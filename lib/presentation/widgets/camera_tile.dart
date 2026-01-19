import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../viewmodels/camera_viewmodel.dart';

class CameraTile extends HookConsumerWidget {
  final int cameraId;

  const CameraTile({super.key, required this.cameraId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camera = ref.watch(cameraViewModelProvider(cameraId));
    final isLogExpanded = ref.watch(cameraLogExpandedProvider(cameraId));
    final notifier = ref.read(cameraViewModelProvider(cameraId).notifier);

    // Hooks로 컨트롤러 및 상태 관리
    final addressController = useTextEditingController(text: camera.address);
    final logScrollController = useScrollController();
    final headerScrollController = useScrollController();
    final isEditing = useState(false);
    final logFontSize = useState(9.0);

    // 테두리 색상 결정: 수신 타임아웃 시 빨간색
    final borderColor = camera.isReceiveTimeout
        ? Colors.red.withOpacity(0.7)
        : camera.isConnected
            ? Colors.green.withOpacity(0.5)
            : Colors.white24;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(
          color: borderColor,
          width: camera.isReceiveTimeout ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildHeader(
            context,
            ref,
            camera,
            notifier,
            isLogExpanded,
            addressController,
            isEditing,
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: Colors.black,
                    child: camera.textureId != null || camera.imageData != null
                        ? Stack(
                            children: [
                              Positioned.fill(
                                child: _buildImageWidget(camera),
                              ),
                              // 수신 타임아웃 오버레이
                              if (camera.isReceiveTimeout)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black54,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.signal_wifi_off,
                                            color: Colors.red,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            '수신 불가',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '영상 데이터를 받지 못하고 있습니다',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : camera.isReceiveTimeout
                            ? _buildTimeoutOverlay()
                            : _buildPlaceholder(
                                camera.isConnecting
                                    ? '연결 중...'
                                    : camera.isConnected
                                        ? '대기 중...'
                                        : '연결 안됨',
                              ),
                  ),
                ),
                if (isLogExpanded)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 280,
                    child: _buildLogPanel(
                      ref,
                      camera,
                      notifier,
                      logScrollController,
                      headerScrollController,
                      logFontSize,
                    ),
                  ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: _buildStatusOverlay(camera),
                ),
                if (camera.header != null && !isLogExpanded)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _buildHeaderInfo(camera),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    camera,
    notifier,
    bool isLogExpanded,
    TextEditingController addressController,
    ValueNotifier<bool> isEditing,
  ) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF252525),
        borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: camera.isConnected ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'CAM ${cameraId + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isEditing.value
                ? TextField(
                    controller: addressController,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(),
                      fillColor: Color(0xFF333333),
                      filled: true,
                    ),
                    onSubmitted: (value) {
                      notifier.updateAddress(value);
                      isEditing.value = false;
                    },
                  )
                : GestureDetector(
                    onDoubleTap: () => isEditing.value = true,
                    child: Text(
                      camera.address,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
          if (isEditing.value)
            IconButton(
              icon: const Icon(Icons.check, size: 16),
              onPressed: () {
                notifier.updateAddress(addressController.text);
                isEditing.value = false;
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            )
          else ...[
            IconButton(
              icon: Icon(
                camera.isConnected ? Icons.stop : Icons.play_arrow,
                size: 18,
                color: camera.isConnected ? Colors.red : Colors.green,
              ),
              onPressed: () {
                if (camera.isConnected) {
                  notifier.disconnect();
                } else {
                  notifier.connect();
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: camera.isConnected ? '연결 해제' : '연결',
            ),
            IconButton(
              icon: Icon(
                isLogExpanded ? Icons.close : Icons.terminal,
                size: 16,
                color: isLogExpanded ? Colors.amber : Colors.white54,
              ),
              onPressed: () {
                ref.read(cameraLogExpandedProvider(cameraId).notifier).toggle();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: '로그 토글',
            ),
          ],
        ],
      ),
    );
  }

  /// Native Texture 렌더링 (고속, 제로카피)
  Widget _buildImageWidget(camera) {
    // Native Texture가 있으면 Texture 위젯으로 고속 렌더링
    if (camera.textureId != null) {
      return Texture(
        textureId: camera.textureId!,
        filterQuality: FilterQuality.low, // 성능 우선
      );
    }

    // fallback: Flutter 기본 이미지 디코더
    if (camera.imageData != null) {
      return Image.memory(
        camera.imageData!,
        gaplessPlayback: true,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildPlaceholder('디코딩 실패'),
      );
    }

    return _buildPlaceholder('이미지 없음');
  }

  Widget _buildPlaceholder(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
    );
  }

  Widget _buildTimeoutOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.signal_wifi_off,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 8),
            const Text(
              '수신 불가',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '영상 데이터를 받지 못하고 있습니다',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOverlay(camera) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (camera.isReceiveTimeout) ...[
            const Icon(Icons.warning_amber, color: Colors.red, size: 12),
            const SizedBox(width: 4),
            const Text(
              '수신 불가',
              style: TextStyle(color: Colors.red, fontSize: 10),
            ),
          ] else if (camera.isConnected) ...[
            // Native/Flutter 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: camera.textureId != null ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                camera.textureId != null ? 'C++' : 'Dart',
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.fiber_manual_record, color: Colors.red, size: 8),
            const SizedBox(width: 4),
            Text(
              '${camera.receiveFps.toStringAsFixed(0)}fps',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            const SizedBox(width: 8),
            Text(
              '#${camera.frameCount}',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ] else if (camera.error != null)
            const Icon(Icons.error_outline, color: Colors.red, size: 14)
          else
            const Icon(Icons.videocam_off, color: Colors.white38, size: 14),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(camera) {
    final header = camera.header?['header'] as Map<String, dynamic>?;
    if (header == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            header['cam_idx']?.toString() ?? '',
            style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            _formatBrightness(header['brightness']),
            style: const TextStyle(color: Colors.white54, fontSize: 9),
          ),
        ],
      ),
    );
  }

  String _formatBrightness(dynamic value) {
    if (value == null) return '';
    if (value is double) return value.toStringAsFixed(3);
    final str = value.toString();
    return str.length > 5 ? str.substring(0, 5) : str;
  }

  Widget _buildLogPanel(
    WidgetRef ref,
    camera,
    notifier,
    ScrollController logScrollController,
    ScrollController headerScrollController,
    ValueNotifier<double> logFontSize,
  ) {
    return Container(
      color: const Color(0xDD1A1A1A),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF252525),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: Colors.green, size: 14),
                const SizedBox(width: 6),
                const Text(
                  'Logs',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    logFontSize.value = (logFontSize.value - 1).clamp(6.0, 16.0);
                  },
                  child: const Icon(Icons.remove, color: Colors.white38, size: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  '${logFontSize.value.toInt()}',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    logFontSize.value = (logFontSize.value + 1).clamp(6.0, 16.0);
                  },
                  child: const Icon(Icons.add, color: Colors.white38, size: 14),
                ),
                const SizedBox(width: 12),
                Text(
                  '${camera.logs.length}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => notifier.clearLogs(),
                  child: const Icon(Icons.delete_outline, color: Colors.white38, size: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: logScrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: logScrollController,
                padding: const EdgeInsets.all(6),
                itemCount: camera.logs.length,
                physics: const ClampingScrollPhysics(),
                itemBuilder: (context, index) {
                  final log = camera.logs[index];
                  Color color = Colors.white70;
                  if (log.contains('ERR')) {
                    color = Colors.red;
                  } else if (log.contains('INFO')) {
                    color = Colors.lightBlue;
                  } else if (log.contains('FRAME')) {
                    color = Colors.green;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: SelectableText(
                      log,
                      style: TextStyle(
                        color: color,
                        fontFamily: 'monospace',
                        fontSize: logFontSize.value,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (camera.header != null)
            Container(
              height: 150,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white24)),
              ),
              child: Scrollbar(
                controller: headerScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: headerScrollController,
                  padding: const EdgeInsets.all(6),
                  child: SizedBox(
                    width: double.infinity,
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(camera.header),
                      style: TextStyle(
                        color: Colors.white54,
                        fontFamily: 'monospace',
                        fontSize: logFontSize.value - 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
