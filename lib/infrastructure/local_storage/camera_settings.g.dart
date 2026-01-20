// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cameraCountSettingHash() =>
    r'02353df7aa2defb29c4b1510faa8469117950582';

/// 카메라 갯수 설정 (로컬 저장)
///
/// Copied from [CameraCountSetting].
@ProviderFor(CameraCountSetting)
final cameraCountSettingProvider =
    NotifierProvider<CameraCountSetting, int>.internal(
      CameraCountSetting.new,
      name: r'cameraCountSettingProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cameraCountSettingHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CameraCountSetting = Notifier<int>;
String _$cameraAddressSettingHash() =>
    r'c229da5d0d850acb19538a35944472f9e1561d18';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$CameraAddressSetting extends BuildlessNotifier<String> {
  late final int id;

  String build(int id);
}

/// 카메라 주소 설정 (로컬 저장)
///
/// Copied from [CameraAddressSetting].
@ProviderFor(CameraAddressSetting)
const cameraAddressSettingProvider = CameraAddressSettingFamily();

/// 카메라 주소 설정 (로컬 저장)
///
/// Copied from [CameraAddressSetting].
class CameraAddressSettingFamily extends Family<String> {
  /// 카메라 주소 설정 (로컬 저장)
  ///
  /// Copied from [CameraAddressSetting].
  const CameraAddressSettingFamily();

  /// 카메라 주소 설정 (로컬 저장)
  ///
  /// Copied from [CameraAddressSetting].
  CameraAddressSettingProvider call(int id) {
    return CameraAddressSettingProvider(id);
  }

  @override
  CameraAddressSettingProvider getProviderOverride(
    covariant CameraAddressSettingProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'cameraAddressSettingProvider';
}

/// 카메라 주소 설정 (로컬 저장)
///
/// Copied from [CameraAddressSetting].
class CameraAddressSettingProvider
    extends NotifierProviderImpl<CameraAddressSetting, String> {
  /// 카메라 주소 설정 (로컬 저장)
  ///
  /// Copied from [CameraAddressSetting].
  CameraAddressSettingProvider(int id)
    : this._internal(
        () => CameraAddressSetting()..id = id,
        from: cameraAddressSettingProvider,
        name: r'cameraAddressSettingProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$cameraAddressSettingHash,
        dependencies: CameraAddressSettingFamily._dependencies,
        allTransitiveDependencies:
            CameraAddressSettingFamily._allTransitiveDependencies,
        id: id,
      );

  CameraAddressSettingProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final int id;

  @override
  String runNotifierBuild(covariant CameraAddressSetting notifier) {
    return notifier.build(id);
  }

  @override
  Override overrideWith(CameraAddressSetting Function() create) {
    return ProviderOverride(
      origin: this,
      override: CameraAddressSettingProvider._internal(
        () => create()..id = id,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  NotifierProviderElement<CameraAddressSetting, String> createElement() {
    return _CameraAddressSettingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CameraAddressSettingProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CameraAddressSettingRef on NotifierProviderRef<String> {
  /// The parameter `id` of this provider.
  int get id;
}

class _CameraAddressSettingProviderElement
    extends NotifierProviderElement<CameraAddressSetting, String>
    with CameraAddressSettingRef {
  _CameraAddressSettingProviderElement(super.provider);

  @override
  int get id => (origin as CameraAddressSettingProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
