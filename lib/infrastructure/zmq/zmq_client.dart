import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dartzmq/dartzmq.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/providers/logger_provider.dart';

part 'zmq_client.g.dart';

/// ZMQ 프레임 데이터
class ZmqFrame {
  final Map<String, dynamic> header;
  final Uint8List imageData;

  ZmqFrame({required this.header, required this.imageData});
}

/// ZMQ 클라이언트 - 저수준 ZeroMQ 통신 담당
class ZmqClient {
  final Logger _logger;

  ZContext? _context;
  ZSocket? _socket;
  StreamSubscription? _subscription;
  bool _isConnected = false;

  ZmqClient(this._logger);

  bool get isConnected => _isConnected;

  /// ZMQ SUB 소켓으로 연결
  Future<void> connect(
    String address, {
    required void Function(ZmqFrame frame) onFrame,
    required void Function(String error) onError,
  }) async {
    try {
      _logger.i('ZMQ 연결 시작: $address');

      _context = ZContext();
      _socket = _context!.createSocket(SocketType.sub);
      _socket!.connect(address);
      _socket!.subscribe('');

      _isConnected = true;
      _logger.i('ZMQ 연결됨: $address');

      _subscription = _socket!.messages.listen(
        (message) {
          final frames = message.toList();
          if (frames.isEmpty) return;

          final raw = frames[0].payload;
          final parsed = _parseFrame(raw);
          if (parsed != null) {
            onFrame(parsed);
          }
        },
        onError: (e) {
          _logger.e('ZMQ 스트림 에러: $e');
          onError(e.toString());
        },
      );
    } catch (e) {
      _logger.e('ZMQ 연결 실패: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// 프레임 파싱: [4바이트 헤더길이][JSON헤더][이미지데이터]
  ZmqFrame? _parseFrame(Uint8List raw) {
    try {
      if (raw.length < 4) return null;

      // Little-endian 헤더 길이
      final headerLen = raw[0] | (raw[1] << 8) | (raw[2] << 16) | (raw[3] << 24);
      if (raw.length < 4 + headerLen) return null;

      // JSON 헤더 파싱
      final headerBytes = raw.sublist(4, 4 + headerLen);
      final headerStr = utf8.decode(headerBytes);
      final header = jsonDecode(headerStr) as Map<String, dynamic>;

      // 이미지 데이터 추출
      final imageStart = 4 + headerLen;
      final imageData = Uint8List.fromList(raw.sublist(imageStart));

      return ZmqFrame(header: header, imageData: imageData);
    } catch (e) {
      return null;
    }
  }

  /// 연결 해제
  void disconnect() {
    _subscription?.cancel();
    _socket?.close();
    _context?.stop();

    _subscription = null;
    _socket = null;
    _context = null;
    _isConnected = false;

    _logger.i('ZMQ 연결 해제됨');
  }
}

/// ZMQ 클라이언트 팩토리 프로바이더
@riverpod
ZmqClient zmqClient(ZmqClientRef ref) {
  final logger = ref.watch(loggerProvider);
  return ZmqClient(logger);
}
