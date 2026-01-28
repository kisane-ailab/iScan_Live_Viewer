import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'camera_preset.g.dart';

/// 카메라 프리셋 모델
class CameraPreset {
  final String location;
  final String name;
  final String url;

  CameraPreset({
    required this.location,
    required this.name,
    required this.url,
  });

  /// 표시용 라벨 (위치 - 이름)
  String get displayLabel => '$location - $name';
}

/// 위치별로 그룹화된 프리셋
class GroupedPresets {
  final Map<String, List<CameraPreset>> byLocation;

  GroupedPresets(this.byLocation);

  List<String> get locations => byLocation.keys.toList();

  List<CameraPreset> getPresetsFor(String location) =>
      byLocation[location] ?? [];
}

/// Supabase 클라이언트 프로바이더
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(ref) {
  return Supabase.instance.client;
}

/// 카메라 프리셋 목록 프로바이더 (스토리지 JSON에서 로드)
@riverpod
Future<GroupedPresets> cameraPresets(ref) async {
  final client = ref.watch(supabaseClientProvider);

  // 스토리지에서 JSON 파일 다운로드
  final response = await client.storage
      .from('iscan-live-viewer-config')
      .download('camera-presets.json');

  final jsonString = utf8.decode(response);
  final Map<String, dynamic> data = json.decode(jsonString);

  // JSON 파싱: { "천상가옥": [{ "name": "...", "url": "..." }], ... }
  final grouped = <String, List<CameraPreset>>{};

  data.forEach((location, cameras) {
    final list = <CameraPreset>[];
    for (final cam in cameras as List) {
      list.add(CameraPreset(
        location: location,
        name: cam['name'] as String,
        url: cam['url'] as String,
      ));
    }
    grouped[location] = list;
  });

  return GroupedPresets(grouped);
}

/// 프리셋 새로고침 함수
void refreshCameraPresets(WidgetRef ref) {
  ref.invalidate(cameraPresetsProvider);
}
