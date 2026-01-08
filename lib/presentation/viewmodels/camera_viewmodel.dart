import 'dart:async';
import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/logger_provider.dart';
import '../../domain/entities/camera_state.dart';
import '../../domain/repositories/camera_repository.dart';
import '../../infrastructure/zmq/zmq_client.dart';
import '../../data/repositories/camera_repository_impl.dart';

part 'camera_viewmodel.g.dart';

/// 카메라 ViewModel - Presentation 로직 담당
@riverpod
class CameraViewModel extends _$CameraViewModel {
  CameraRepository? _repository;

  // FPS 측정용
  DateTime? _lastSecond;
  int _receiveThisSecond = 0;
  int _renderThisSecond = 0;

  // 수신 타임아웃 체크용 타이머
  Timer? _timeoutTimer;

  @override
  CameraState build(int id) {
    ref.onDispose(() {
      _timeoutTimer?.cancel();
      disconnect();
    });

    return CameraState(
      id: id,
      address: id < defaultCameraAddresses.length
          ? defaultCameraAddresses[id]
          : 'tcp://58.238.37.52:1700${id + 1}',
    );
  }

  /// 주소 변경
  void updateAddress(String address) {
    if (state.isConnected) {
      disconnect();
    }
    state = state.copyWith(address: address);
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
      // 각 카메라마다 새 ZmqClient 인스턴스 생성
      final logger = ref.read(loggerProvider);
      final zmqClient = ZmqClient(logger);
      _repository = CameraRepositoryImpl(zmqClient);

      await _repository!.connect(
        state.address,
        onFrame: _onFrameReceived,
        onError: _onError,
      );

      _addLog('INFO', '연결됨 - 데이터 대기중');
      state = state.copyWith(
        isConnecting: false,
        isConnected: true,
        isReceiveTimeout: false,
        lastFrameTime: DateTime.now(),
      );

      // 수신 타임아웃 체크 타이머 시작
      _startTimeoutTimer();
    } catch (e) {
      _addLog('ERR', '연결 실패: $e');
      state = state.copyWith(
        isConnecting: false,
        isConnected: false,
        error: e.toString(),
      );
    }
  }

  /// 프레임 수신 콜백
  void _onFrameReceived(Map<String, dynamic> header, Uint8List imageData) {
    final now = DateTime.now();
    _receiveThisSecond++;

    // FPS 계산
    if (_lastSecond == null) {
      _lastSecond = now;
    } else if (now.difference(_lastSecond!).inMilliseconds >= fpsUpdateIntervalMs) {
      state = state.copyWith(
        receiveFps: _receiveThisSecond.toDouble(),
        renderFps: _renderThisSecond.toDouble(),
      );
      _receiveThisSecond = 0;
      _renderThisSecond = 0;
      _lastSecond = now;
    }

    _renderThisSecond++;
    state = state.copyWith(
      header: header,
      imageData: imageData,
      frameCount: state.frameCount + 1,
      lastFrameTime: now,
      isReceiveTimeout: false,
    );

    // 처음 5프레임만 로깅
    if (state.frameCount <= 5) {
      _addLog('FRAME', '#${state.frameCount} - ${imageData.length} bytes');
    }
  }

  /// 에러 콜백
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
  void disconnect() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _repository?.disconnect();
    _repository = null;

    if (state.isConnected) {
      _addLog('INFO', '연결 해제됨');
    }

    state = state.copyWith(
      isConnected: false,
      isConnecting: false,
      isReceiveTimeout: false,
      imageData: null,
      header: null,
      lastFrameTime: null,
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

/// 화면에 표시할 카메라 갯수 (1, 2, 4)
@riverpod
class CameraCount extends _$CameraCount {
  @override
  int build() => 2;

  void set(int count) => state = count;
}
