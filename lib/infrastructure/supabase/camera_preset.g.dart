// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_preset.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$supabaseClientHash() => r'a05183fba23718e23fec2101f0b5eac7d43db156';

/// Supabase 클라이언트 프로바이더
///
/// Copied from [supabaseClient].
@ProviderFor(supabaseClient)
final supabaseClientProvider = Provider<SupabaseClient>.internal(
  supabaseClient,
  name: r'supabaseClientProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supabaseClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SupabaseClientRef = ProviderRef<SupabaseClient>;
String _$cameraPresetsHash() => r'7b011903432e673b8f9787d5cad499548ad9d178';

/// 카메라 프리셋 목록 프로바이더 (스토리지 JSON에서 로드)
///
/// Copied from [cameraPresets].
@ProviderFor(cameraPresets)
final cameraPresetsProvider =
    AutoDisposeFutureProvider<GroupedPresets>.internal(
      cameraPresets,
      name: r'cameraPresetsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cameraPresetsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CameraPresetsRef = AutoDisposeFutureProviderRef<GroupedPresets>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
