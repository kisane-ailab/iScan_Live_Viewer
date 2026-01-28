import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../infrastructure/constants/app_constants.dart';
import '../../infrastructure/logger/logger_provider.dart';
import '../../domain/entities/camera_state.dart';
import '../../infrastructure/local_storage/camera_settings.dart';
import '../../infrastructure/native/native_video_renderer.dart';
import '../../infrastructure/native/generated/native_video_api.g.dart';

part 'camera_viewmodel.g.dart';

/// 카메라 ViewModel - Native C++ 렌더러 사용
@riverpod
class CameraViewModel extends _$CameraViewModel {
  NativeVideoRenderer? _renderer;

  // FPS 측정용
  DateTime? _lastSecond;
  int _receiveThisSecond = 0;
  int _lastFrameCount = 0;

  // 수신 타임아웃 체크용 타이머
  Timer? _timeoutTimer;

  // 프레임 정보 폴링 타이머
  Timer? _pollTimer;

  @override
  CameraState build(int id) {
    ref.onDispose(() {
      _timeoutTimer?.cancel();
      _pollTimer?.cancel();
      disconnect();
    });

    // 로컬 저장소에서 주소 로드
    final savedAddress = ref.watch(cameraAddressSettingProvider(id));

    return CameraState(
      id: id,
      address: savedAddress,
    );
  }

  /// 주소 변경 (로컬 저장소에 저장)
  Future<void> updateAddress(String address, {bool autoConnect = false}) async {
    // 기존 연결/연결중 상태면 해제
    if (state.isConnected || state.isConnecting) {
      await disconnect();
    }
    // 로컬 저장소에 저장
    await ref.read(cameraAddressSettingProvider(state.id).notifier).set(address);
    state = state.copyWith(address: address);

    if (autoConnect) {
      // 상태 안정화 대기
      await Future.delayed(const Duration(milliseconds: 100));
      await connect();
    }
  }

  /// 로그 추가
  void _addLog(String level, String message) {
    final timestamp = DateTime.now().toString().substring(11, 23);
    final log = '[$timestamp] $level: $message';
    final newLogs = [log, ...state.logs];
    if (newLogs.length > maxLogCount) newLogs.removeLast();
    state = state.copyWith(logs: newLogs);
  }

  /// 카메라 연결
  Future<void> connect() async {
    if (state.isConnected || state.isConnecting) return;

    state = state.copyWith(
      isConnecting: true,
      error: null,
      logs: [],
      frameCount: 0,
    );

    _addLog('INFO', '연결 시작: ${state.address}');

    try {
      final logger = ref.read(loggerProvider);

      // Create native renderer
      _renderer = NativeVideoRenderer();

      // Set error callback (frame info is now polled)
      _renderer!.onErrorCallback = _onError;

      // Reset frame count tracking
      _lastFrameCount = 0;

      // Initialize and get texture ID
      final textureId = await _renderer!.initialize(state.id);
      _addLog('INFO', '텍스처 초기화 완료: $textureId');

      // Start ZMQ stream
      await _renderer!.startStream(state.address);

      _addLog('INFO', '네이티브 스트림 시작됨');
      state = state.copyWith(
        isConnecting: false,
        isConnected: true,
        isReceiveTimeout: false,
        lastFrameTime: DateTime.now(),
        textureId: textureId,
      );

      // 수신 타임아웃 체크 타이머 시작
      _startTimeoutTimer();

      // 프레임 정보 폴링 타이머 시작
      _startPollTimer();
    } catch (e) {
      _addLog('ERR', '연결 실패: $e');
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        error: e.toString(),
      );
    }
  }

  /// 프레임 정보 폴링 타이머 시작
  void _startPollTimer() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _pollFrameInfo(),
    );
  }

  /// 프레임 정보 폴링
  Future<void> _pollFrameInfo() async {
    if (_renderer == null || !state.isConnected) return;

    try {
      final info = await _renderer!.getFrameInfo();
      if (info == null) return;

      // 새 프레임이 있는 경우에만 업데이트
      if (info.frameCount == _lastFrameCount) return;

      final now = DateTime.now();
      final framesDelta = info.frameCount - _lastFrameCount;
      _lastFrameCount = info.frameCount;
      _receiveThisSecond += framesDelta;

      // FPS 계산
      if (_lastSecond == null) {
        _lastSecond = now;
      } else if (now.difference(_lastSecond!).inMilliseconds >= fpsUpdateIntervalMs) {
        state = state.copyWith(
          receiveFps: _receiveThisSecond.toDouble(),
        );
        _receiveThisSecond = 0;
        _lastSecond = now;
      }

      // Build header with bbox if available
      final headerData = <String, dynamic>{
        'cam_idx': info.camIdx,
        'cam_num': info.camNum,
        'brightness': info.brightness,
        'motion': info.motion,
        'width': info.width,
        'height': info.height,
      };

      if (info.bboxW != null && info.bboxH != null && info.bboxW! > 0 && info.bboxH! > 0) {
        headerData['bbox'] = {
          'x': info.bboxX,
          'y': info.bboxY,
          'w': info.bboxW,
          'h': info.bboxH,
        };
      }

      state = state.copyWith(
        header: {'header': headerData},
        frameCount: info.frameCount,
        lastFrameTime: now,
        isReceiveTimeout: false,
      );

      // 처음 5프레임만 로깅
      if (info.frameCount <= 5) {
        _addLog('FRAME', '#${info.frameCount} received');
      }
    } catch (e) {
      // 폴링 중 에러는 무시 (연결 끊김 등)
    }
  }

  /// 에러 콜백 (from native - currently unused due to threading issues)
  void _onError(String error) {
    _addLog('ERR', '스트림 에러: $error');
    state = state.copyWith(error: error);
  }

  /// 수신 타임아웃 체크 타이머 시작
  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkReceiveTimeout(),
    );
  }

  /// 수신 타임아웃 체크
  void _checkReceiveTimeout() {
    if (!state.isConnected || state.lastFrameTime == null) return;

    final elapsed = DateTime.now().difference(state.lastFrameTime!).inSeconds;
    if (elapsed >= receiveTimeoutSeconds && !state.isReceiveTimeout) {
      _addLog('ERR', '수신 타임아웃 - ${receiveTimeoutSeconds}초 동안 프레임 없음');
      state = state.copyWith(isReceiveTimeout: true);
    }
  }

  /// 카메라 연결 해제
  Future<void> disconnect() async {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;

    if (_renderer != null) {
      try {
        await _renderer!.stopStream();
        await _renderer!.dispose();
      } catch (e) {
        // Ignore errors during cleanup
      }
      _renderer = null;
    }

    if (state.isConnected) {
      _addLog('INFO', '연결 해제됨');
    }

    state = state.copyWith(
      isConnected: false,
      isConnecting: false,
      isReceiveTimeout: false,
      imageData: null,
      decodedImage: null,
      header: null,
      lastFrameTime: null,
      textureId: null,
    );
  }

  /// 로그 지우기
  void clearLogs() {
    state = state.copyWith(logs: []);
  }
}

/// 카메라 로그 펼침 상태
@riverpod
class CameraLogExpanded extends _$CameraLogExpanded {
  @override
  bool build(int id) => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

/// 화면에 표시할 카메라 갯수 (1, 2, 4) - 로컬 저장
@riverpod
class CameraCount extends _$CameraCount {
  @override
  int build() {
    // 로컬 저장소에서 카메라 갯수 로드
    return ref.watch(cameraCountSettingProvider);
  }

  Future<void> set(int count) async {
    // 로컬 저장소에 저장
    await ref.read(cameraCountSettingProvider.notifier).set(count);
    state = count;
  }
}

/// 화면 비율 모드
/// - "contain": 원본 비율 유지 (기본)
/// - "fill": 꽉 차게 늘림
/// - "16:9", "4:3", "1:1", "9:16": 지정 비율
@riverpod
class CameraAspectRatio extends _$CameraAspectRatio {
  @override
  String build(int id) => 'contain'; // 기본값: 원본 비율 유지

  void set(String mode) => state = mode;
}
