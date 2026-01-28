import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../infrastructure/supabase/camera_preset.dart';
import '../viewmodels/camera_viewmodel.dart';

class CameraTile extends HookConsumerWidget {
  final int cameraId;

  const CameraTile({super.key, required this.cameraId});

  // 비율 옵션: 모드명 -> (라벨, aspectRatio 또는 null)
  static const List<Map<String, dynamic>> _aspectRatioOptions = [
    {'mode': 'contain', 'label': '원본비율'},
    {'mode': 'fill', 'label': '꽉참'},
    {'mode': '16:9', 'label': '16:9', 'ratio': 16 / 9},
    {'mode': '4:3', 'label': '4:3', 'ratio': 4 / 3},
    {'mode': '1:1', 'label': '1:1', 'ratio': 1.0},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camera = ref.watch(cameraViewModelProvider(cameraId));
    final isLogExpanded = ref.watch(cameraLogExpandedProvider(cameraId));
    final aspectRatio = ref.watch(cameraAspectRatioProvider(cameraId));
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
            aspectRatio,
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
                                child: _buildImageWithRatio(camera, aspectRatio),
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

  // HTTP 카메라 옵션 목록 (폴백용)
  static const List<String> _httpCamOptions = [
    'left',
    'right',
    'single_1',
    'single_2',
    'single_3',
    'single_4',
  ];

  // 주소가 HTTP인지 확인
  bool _isHttpAddress(String address) {
    final lower = address.trim().toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  // HTTP 기본 URL 추출 (쿼리 파라미터 제거)
  String _getHttpBaseUrl(String address) {
    final trimmed = address.trim();
    // /livecam 이전까지만 추출
    final livecamIdx = trimmed.indexOf('/livecam');
    if (livecamIdx > 0) {
      return trimmed.substring(0, livecamIdx);
    }
    // 쿼리 파라미터 제거
    final queryIdx = trimmed.indexOf('?');
    if (queryIdx > 0) {
      return trimmed.substring(0, queryIdx);
    }
    return trimmed;
  }

  // HTTP 전체 URL 생성
  String _buildHttpUrl(String baseUrl, String cam) {
    var base = baseUrl.trim();
    // 이미 /livecam이 포함되어 있으면 기본 URL만 추출
    var cleanBase = _getHttpBaseUrl(base);
    // 끝에 슬래시 있으면 제거
    while (cleanBase.endsWith('/')) {
      cleanBase = cleanBase.substring(0, cleanBase.length - 1);
    }
    return '$cleanBase/livecam/mjpeg?cam=$cam';
  }

  /// 프리셋 선택 다이얼로그
  void _showPresetDialog(
    BuildContext context,
    WidgetRef ref,
    TextEditingController addressController,
    notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final presetsAsync = ref.watch(cameraPresetsProvider);

          return AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text(
              '카메라 프리셋 선택',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            content: SizedBox(
              width: 300,
              height: 400,
              child: presetsAsync.when(
                data: (grouped) => grouped.locations.isEmpty
                    ? const Center(
                        child: Text('프리셋이 없습니다', style: TextStyle(color: Colors.white54)),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: grouped.locations.map((location) {
                          return ExpansionTile(
                            title: Text(
                              location,
                              style: const TextStyle(color: Colors.amber, fontSize: 14),
                            ),
                            iconColor: Colors.white54,
                            collapsedIconColor: Colors.white38,
                            initiallyExpanded: true,
                            children: grouped.getPresetsFor(location).map((preset) {
                              return ListTile(
                                dense: true,
                                title: Text(
                                  preset.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                                subtitle: Text(
                                  preset.url,
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                                onTap: () async {
                                  addressController.text = preset.url;
                                  Navigator.pop(ctx);
                                  await notifier.updateAddress(preset.url, autoConnect: true);
                                },
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text('로드 실패: $e', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(cameraPresetsProvider),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.cyan),
                tooltip: '새로고침',
                onPressed: () => ref.invalidate(cameraPresetsProvider),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('닫기'),
              ),
            ],
          );
        },
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
    String aspectRatioMode,
  ) {
    final isHttp = _isHttpAddress(addressController.text);
    // 현재 비율 라벨 찾기
    final currentOption = _aspectRatioOptions.firstWhere(
      (o) => o['mode'] == aspectRatioMode,
      orElse: () => _aspectRatioOptions[0],
    );
    final currentRatioLabel = currentOption['label'] as String;

    return Container(
      height: 48,
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
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: const OutlineInputBorder(),
                      fillColor: const Color(0xFF333333),
                      filled: true,
                      hintText: isHttp ? 'http://IP:18081' : 'tcp://IP:17002',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                    onChanged: (_) {
                      // 주소 변경 시 UI 갱신 (HTTP 감지용)
                      (context as Element).markNeedsBuild();
                    },
                    onSubmitted: (value) {
                      notifier.updateAddress(value);
                      isEditing.value = false;
                    },
                  )
                : GestureDetector(
                    onDoubleTap: () => isEditing.value = true,
                    child: Text(
                      camera.address,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
          // 프리셋 선택 버튼 (항상 표시)
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.cyan, size: 18),
            tooltip: '프리셋에서 선택',
            onPressed: () => _showPresetDialog(context, ref, addressController, notifier),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          // HTTP 기본 URL일 때 카메라 선택 팝업 버튼
          if (isHttp && !camera.isConnected && !addressController.text.contains('/livecam')) ...[
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.camera_alt, color: Colors.amber, size: 18),
              tooltip: '카메라 선택',
              color: const Color(0xFF333333),
              onSelected: (cam) {
                final fullUrl = _buildHttpUrl(addressController.text, cam);
                addressController.text = fullUrl;
                notifier.updateAddress(fullUrl);
              },
              itemBuilder: (context) => _httpCamOptions.map((cam) {
                return PopupMenuItem(
                  value: cam,
                  height: 36,
                  child: Text(cam, style: const TextStyle(color: Colors.white, fontSize: 13)),
                );
              }).toList(),
            ),
          ],
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
            // 비율 선택 버튼
            PopupMenuButton<String>(
              icon: const Icon(Icons.aspect_ratio, color: Colors.white54, size: 16),
              tooltip: '화면 비율: $currentRatioLabel',
              color: const Color(0xFF333333),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onSelected: (mode) {
                ref.read(cameraAspectRatioProvider(cameraId).notifier).set(mode);
              },
              itemBuilder: (context) => _aspectRatioOptions.map((option) {
                final mode = option['mode'] as String;
                final label = option['label'] as String;
                final isSelected = mode == aspectRatioMode;
                return PopupMenuItem(
                  value: mode,
                  height: 36,
                  child: Row(
                    children: [
                      if (isSelected)
                        const Icon(Icons.check, color: Colors.cyan, size: 14)
                      else
                        const SizedBox(width: 14),
                      const SizedBox(width: 8),
                      Text(label, style: TextStyle(
                        color: isSelected ? Colors.cyan : Colors.white,
                        fontSize: 13,
                      )),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// 비율 모드에 따라 이미지 위젯 빌드
  Widget _buildImageWithRatio(camera, String ratioMode) {
    // 비율 모드별 처리
    final option = _aspectRatioOptions.firstWhere(
      (o) => o['mode'] == ratioMode,
      orElse: () => _aspectRatioOptions[0],
    );

    // 지정 비율 (16:9, 4:3 등) - 레터박스 방식
    if (option['ratio'] != null) {
      final targetRatio = option['ratio'] as double;
      return LayoutBuilder(
        builder: (context, constraints) {
          final parentWidth = constraints.maxWidth;
          final parentHeight = constraints.maxHeight;
          final parentRatio = parentWidth / parentHeight;

          double boxWidth, boxHeight;
          if (parentRatio > targetRatio) {
            // 부모가 더 넓음 -> 높이 맞춤, 좌우 레터박스
            boxHeight = parentHeight;
            boxWidth = boxHeight * targetRatio;
          } else {
            // 부모가 더 좁음 -> 너비 맞춤, 상하 레터박스
            boxWidth = parentWidth;
            boxHeight = boxWidth / targetRatio;
          }

          return Container(
            color: Colors.black,
            child: Center(
              child: ClipRect(
                child: SizedBox(
                  width: boxWidth,
                  height: boxHeight,
                  child: _buildRawImage(camera),
                ),
              ),
            ),
          );
        },
      );
    }

    // fill: 꽉 차게 늘림
    if (ratioMode == 'fill') {
      return _buildRawImage(camera, BoxFit.fill);
    }

    // contain: 원본 비율 유지 (기본)
    return _buildRawImage(camera, BoxFit.contain);
  }

  /// 이미지 위젯 (비율 없이 순수 이미지만)
  Widget _buildRawImage(camera, [BoxFit fit = BoxFit.cover]) {
    if (camera.textureId != null) {
      // 해상도 정보 가져오기
      final header = camera.header?['header'] as Map<String, dynamic>?;
      final w = (header?['width'] as int?) ?? 1920;
      final h = (header?['height'] as int?) ?? 1080;

      return FittedBox(
        fit: fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: w.toDouble(),
          height: h.toDouble(),
          child: Texture(
            textureId: camera.textureId!,
            filterQuality: FilterQuality.low,
          ),
        ),
      );
    }

    if (camera.imageData != null) {
      return Image.memory(
        camera.imageData!,
        gaplessPlayback: true,
        fit: fit,
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
            // 해상도 표시
            if (camera.header != null) ...[
              const SizedBox(width: 8),
              Text(
                _getResolutionText(camera.header),
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ] else if (camera.error != null)
            const Icon(Icons.error_outline, color: Colors.red, size: 14)
          else
            const Icon(Icons.videocam_off, color: Colors.white38, size: 14),
        ],
      ),
    );
  }

  /// header에서 해상도 텍스트 추출
  String _getResolutionText(Map<String, dynamic>? headerData) {
    if (headerData == null) return '';
    final header = headerData['header'] as Map<String, dynamic>?;
    if (header == null) return '';
    final width = header['width'];
    final height = header['height'];
    if (width != null && height != null) {
      return '${width}x$height';
    }
    return '';
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
