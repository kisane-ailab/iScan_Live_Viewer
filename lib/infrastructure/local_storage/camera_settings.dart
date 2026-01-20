import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/app_constants.dart';
import 'shared_preferences.dart';

part 'camera_settings.g.dart';

/// 카메라 설정 로컬 저장소 키
class CameraSettingsKeys {
  static const String cameraCount = 'camera_count';
  static String cameraAddress(int id) => 'camera_address_$id';
}

/// 카메라 갯수 설정 (로컬 저장)
@Riverpod(keepAlive: true)
class CameraCountSetting extends _$CameraCountSetting {
  static const int defaultCount = 2;

  @override
  int build() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      return prefs.getInt(CameraSettingsKeys.cameraCount) ?? defaultCount;
    } catch (e) {
      return defaultCount;
    }
  }

  Future<void> set(int count) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setInt(CameraSettingsKeys.cameraCount, count);
      state = count;
    } catch (e) {
      // 저장 실패 시 상태만 업데이트
      state = count;
    }
  }
}

/// 카메라 주소 설정 (로컬 저장)
@Riverpod(keepAlive: true)
class CameraAddressSetting extends _$CameraAddressSetting {
  @override
  String build(int id) {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final saved = prefs.getString(CameraSettingsKeys.cameraAddress(id));
      if (saved != null && saved.isNotEmpty) {
        return saved;
      }
    } catch (e) {
      // SharedPreferences 접근 실패 시 기본값 반환
    }
    // 기본 주소 반환
    return id < defaultCameraAddresses.length
        ? defaultCameraAddresses[id]
        : 'tcp://127.0.0.1:1700${id + 1}';
  }

  Future<void> set(String address) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(CameraSettingsKeys.cameraAddress(id), address);
      state = address;
    } catch (e) {
      // 저장 실패 시 상태만 업데이트
      state = address;
    }
  }
}
