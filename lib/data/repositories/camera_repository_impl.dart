import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/repositories/camera_repository.dart';
import '../../infrastructure/zmq/zmq_client.dart';

part 'camera_repository_impl.g.dart';

/// 카메라 레포지토리 구현체
class CameraRepositoryImpl implements CameraRepository {
  final ZmqClient _zmqClient;

  CameraRepositoryImpl(this._zmqClient);

  @override
  bool get isConnected => _zmqClient.isConnected;

  @override
  Future<void> connect(
    String address, {
    required OnFrameReceived onFrame,
    required OnError onError,
  }) async {
    await _zmqClient.connect(
      address,
      onFrame: (frame) {
        onFrame(frame.header, frame.imageData);
      },
      onError: onError,
    );
  }

  @override
  void disconnect() {
    _zmqClient.disconnect();
  }
}

/// 카메라 레포지토리 프로바이더
@riverpod
CameraRepository cameraRepository(CameraRepositoryRef ref) {
  final zmqClient = ref.watch(zmqClientProvider);
  return CameraRepositoryImpl(zmqClient);
}
