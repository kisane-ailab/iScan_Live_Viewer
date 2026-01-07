import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/camera_tile.dart';
import '../viewmodels/camera_viewmodel.dart';

class MultiCameraPage extends ConsumerWidget {
  const MultiCameraPage({super.key});

  void _showLayoutDialog(BuildContext context, WidgetRef ref) {
    final currentCount = ref.read(cameraCountProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text('화면 분할', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioOption(context, ref, currentCount, 1, '1개'),
            _buildRadioOption(context, ref, currentCount, 2, '2개'),
            _buildRadioOption(context, ref, currentCount, 4, '4개'),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(BuildContext context, WidgetRef ref, int currentCount, int value, String label) {
    return RadioListTile<int>(
      title: Text(label, style: const TextStyle(color: Colors.white70)),
      value: value,
      groupValue: currentCount,
      activeColor: Colors.green,
      onChanged: (val) {
        ref.read(cameraCountProvider.notifier).set(val!);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraCount = ref.watch(cameraCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('iScan Live Viewer'),
        backgroundColor: const Color(0xFF1A1A1A),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.play_arrow, color: Colors.green, size: 18),
            label: const Text('전체 연결', style: TextStyle(color: Colors.white70, fontSize: 12)),
            onPressed: () {
              for (int i = 0; i < cameraCount; i++) {
                ref.read(cameraViewModelProvider(i).notifier).connect();
              }
            },
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            icon: const Icon(Icons.stop, color: Colors.red, size: 18),
            label: const Text('전체 해제', style: TextStyle(color: Colors.white70, fontSize: 12)),
            onPressed: () {
              for (int i = 0; i < cameraCount; i++) {
                ref.read(cameraViewModelProvider(i).notifier).disconnect();
              }
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.grid_view, color: Colors.white70, size: 20),
            tooltip: '화면 분할',
            onPressed: () => _showLayoutDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: _buildCameraGrid(cameraCount),
      ),
    );
  }

  Widget _buildCameraGrid(int count) {
    switch (count) {
      case 1:
        return const CameraTile(cameraId: 0);
      case 2:
        return const Row(
          children: [
            Expanded(child: CameraTile(cameraId: 0)),
            SizedBox(width: 8),
            Expanded(child: CameraTile(cameraId: 1)),
          ],
        );
      case 4:
      default:
        return const Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: CameraTile(cameraId: 0)),
                  SizedBox(width: 8),
                  Expanded(child: CameraTile(cameraId: 1)),
                ],
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: CameraTile(cameraId: 2)),
                  SizedBox(width: 8),
                  Expanded(child: CameraTile(cameraId: 3)),
                ],
              ),
            ),
          ],
        );
    }
  }
}
