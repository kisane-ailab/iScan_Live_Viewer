// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cameraViewModelHash() => r'93cb31a19cc918f7b9aeb52f125c6d17124cf471';

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

abstract class _$CameraViewModel
    extends BuildlessAutoDisposeNotifier<CameraState> {
  late final int id;

  CameraState build(int id);
}

/// 카메라 ViewModel - Native C++ 렌더러 사용
///
/// Copied from [CameraViewModel].
@ProviderFor(CameraViewModel)
const cameraViewModelProvider = CameraViewModelFamily();

/// 카메라 ViewModel - Native C++ 렌더러 사용
///
/// Copied from [CameraViewModel].
class CameraViewModelFamily extends Family<CameraState> {
  /// 카메라 ViewModel - Native C++ 렌더러 사용
  ///
  /// Copied from [CameraViewModel].
  const CameraViewModelFamily();

  /// 카메라 ViewModel - Native C++ 렌더러 사용
  ///
  /// Copied from [CameraViewModel].
  CameraViewModelProvider call(int id) {
    return CameraViewModelProvider(id);
  }

  @override
  CameraViewModelProvider getProviderOverride(
    covariant CameraViewModelProvider provider,
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
  String? get name => r'cameraViewModelProvider';
}

/// 카메라 ViewModel - Native C++ 렌더러 사용
///
/// Copied from [CameraViewModel].
class CameraViewModelProvider
    extends AutoDisposeNotifierProviderImpl<CameraViewModel, CameraState> {
  /// 카메라 ViewModel - Native C++ 렌더러 사용
  ///
  /// Copied from [CameraViewModel].
  CameraViewModelProvider(int id)
    : this._internal(
        () => CameraViewModel()..id = id,
        from: cameraViewModelProvider,
        name: r'cameraViewModelProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$cameraViewModelHash,
        dependencies: CameraViewModelFamily._dependencies,
        allTransitiveDependencies:
            CameraViewModelFamily._allTransitiveDependencies,
        id: id,
      );

  CameraViewModelProvider._internal(
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
  CameraState runNotifierBuild(covariant CameraViewModel notifier) {
    return notifier.build(id);
  }

  @override
  Override overrideWith(CameraViewModel Function() create) {
    return ProviderOverride(
      origin: this,
      override: CameraViewModelProvider._internal(
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
  AutoDisposeNotifierProviderElement<CameraViewModel, CameraState>
  createElement() {
    return _CameraViewModelProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CameraViewModelProvider && other.id == id;
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
mixin CameraViewModelRef on AutoDisposeNotifierProviderRef<CameraState> {
  /// The parameter `id` of this provider.
  int get id;
}

class _CameraViewModelProviderElement
    extends AutoDisposeNotifierProviderElement<CameraViewModel, CameraState>
    with CameraViewModelRef {
  _CameraViewModelProviderElement(super.provider);

  @override
  int get id => (origin as CameraViewModelProvider).id;
}

String _$cameraLogExpandedHash() => r'8751db28fa1572015d4cc5701842cc3f8054c73b';

abstract class _$CameraLogExpanded extends BuildlessAutoDisposeNotifier<bool> {
  late final int id;

  bool build(int id);
}

/// 카메라 로그 펼침 상태
///
/// Copied from [CameraLogExpanded].
@ProviderFor(CameraLogExpanded)
const cameraLogExpandedProvider = CameraLogExpandedFamily();

/// 카메라 로그 펼침 상태
///
/// Copied from [CameraLogExpanded].
class CameraLogExpandedFamily extends Family<bool> {
  /// 카메라 로그 펼침 상태
  ///
  /// Copied from [CameraLogExpanded].
  const CameraLogExpandedFamily();

  /// 카메라 로그 펼침 상태
  ///
  /// Copied from [CameraLogExpanded].
  CameraLogExpandedProvider call(int id) {
    return CameraLogExpandedProvider(id);
  }

  @override
  CameraLogExpandedProvider getProviderOverride(
    covariant CameraLogExpandedProvider provider,
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
  String? get name => r'cameraLogExpandedProvider';
}

/// 카메라 로그 펼침 상태
///
/// Copied from [CameraLogExpanded].
class CameraLogExpandedProvider
    extends AutoDisposeNotifierProviderImpl<CameraLogExpanded, bool> {
  /// 카메라 로그 펼침 상태
  ///
  /// Copied from [CameraLogExpanded].
  CameraLogExpandedProvider(int id)
    : this._internal(
        () => CameraLogExpanded()..id = id,
        from: cameraLogExpandedProvider,
        name: r'cameraLogExpandedProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$cameraLogExpandedHash,
        dependencies: CameraLogExpandedFamily._dependencies,
        allTransitiveDependencies:
            CameraLogExpandedFamily._allTransitiveDependencies,
        id: id,
      );

  CameraLogExpandedProvider._internal(
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
  bool runNotifierBuild(covariant CameraLogExpanded notifier) {
    return notifier.build(id);
  }

  @override
  Override overrideWith(CameraLogExpanded Function() create) {
    return ProviderOverride(
      origin: this,
      override: CameraLogExpandedProvider._internal(
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
  AutoDisposeNotifierProviderElement<CameraLogExpanded, bool> createElement() {
    return _CameraLogExpandedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CameraLogExpandedProvider && other.id == id;
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
mixin CameraLogExpandedRef on AutoDisposeNotifierProviderRef<bool> {
  /// The parameter `id` of this provider.
  int get id;
}

class _CameraLogExpandedProviderElement
    extends AutoDisposeNotifierProviderElement<CameraLogExpanded, bool>
    with CameraLogExpandedRef {
  _CameraLogExpandedProviderElement(super.provider);

  @override
  int get id => (origin as CameraLogExpandedProvider).id;
}

String _$cameraCountHash() => r'0c0e63fb5a095730c2836fd9b83c0bd96c2f0252';

/// 화면에 표시할 카메라 갯수 (1, 2, 4) - 로컬 저장
///
/// Copied from [CameraCount].
@ProviderFor(CameraCount)
final cameraCountProvider =
    AutoDisposeNotifierProvider<CameraCount, int>.internal(
      CameraCount.new,
      name: r'cameraCountProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cameraCountHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CameraCount = AutoDisposeNotifier<int>;
String _$cameraAspectRatioHash() => r'a22cd877b21ad8985d4ea3e9c85d3b4e7ed3b825';

abstract class _$CameraAspectRatio
    extends BuildlessAutoDisposeNotifier<String> {
  late final int id;

  String build(int id);
}

/// 화면 비율 모드
/// - "contain": 원본 비율 유지 (기본)
/// - "fill": 꽉 차게 늘림
/// - "16:9", "4:3", "1:1", "9:16": 지정 비율
///
/// Copied from [CameraAspectRatio].
@ProviderFor(CameraAspectRatio)
const cameraAspectRatioProvider = CameraAspectRatioFamily();

/// 화면 비율 모드
/// - "contain": 원본 비율 유지 (기본)
/// - "fill": 꽉 차게 늘림
/// - "16:9", "4:3", "1:1", "9:16": 지정 비율
///
/// Copied from [CameraAspectRatio].
class CameraAspectRatioFamily extends Family<String> {
  /// 화면 비율 모드
  /// - "contain": 원본 비율 유지 (기본)
  /// - "fill": 꽉 차게 늘림
  /// - "16:9", "4:3", "1:1", "9:16": 지정 비율
  ///
  /// Copied from [CameraAspectRatio].
  const CameraAspectRatioFamily();

  /// 화면 비율 모드
  /// - "contain": 원본 비율 유지 (기본)
  /// - "fill": 꽉 차게 늘림
  /// - "16:9", "4:3", "1:1", "9:16": 지정 비율
  ///
  /// Copied from [CameraAspectRatio].
  CameraAspectRatioProvider call(int id) {
    return CameraAspectRatioProvider(id);
  }

  @override
  CameraAspectRatioProvider getProviderOverride(
    covariant CameraAspectRatioProvider provider,
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
  String? get name => r'cameraAspectRatioProvider';
}

/// 화면 비율 모드
/// - "contain": 원본 비율 유지 (기본)
/// - "fill": 꽉 차게 늘림
/// - "16:9", "4:3", "1:1", "9:16": 지정 비율
///
/// Copied from [CameraAspectRatio].
class CameraAspectRatioProvider
    extends AutoDisposeNotifierProviderImpl<CameraAspectRatio, String> {
  /// 화면 비율 모드
  /// - "contain": 원본 비율 유지 (기본)
  /// - "fill": 꽉 차게 늘림
  /// - "16:9", "4:3", "1:1", "9:16": 지정 비율
  ///
  /// Copied from [CameraAspectRatio].
  CameraAspectRatioProvider(int id)
    : this._internal(
        () => CameraAspectRatio()..id = id,
        from: cameraAspectRatioProvider,
        name: r'cameraAspectRatioProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$cameraAspectRatioHash,
        dependencies: CameraAspectRatioFamily._dependencies,
        allTransitiveDependencies:
            CameraAspectRatioFamily._allTransitiveDependencies,
        id: id,
      );

  CameraAspectRatioProvider._internal(
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
  String runNotifierBuild(covariant CameraAspectRatio notifier) {
    return notifier.build(id);
  }

  @override
  Override overrideWith(CameraAspectRatio Function() create) {
    return ProviderOverride(
      origin: this,
      override: CameraAspectRatioProvider._internal(
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
  AutoDisposeNotifierProviderElement<CameraAspectRatio, String>
  createElement() {
    return _CameraAspectRatioProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CameraAspectRatioProvider && other.id == id;
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
mixin CameraAspectRatioRef on AutoDisposeNotifierProviderRef<String> {
  /// The parameter `id` of this provider.
  int get id;
}

class _CameraAspectRatioProviderElement
    extends AutoDisposeNotifierProviderElement<CameraAspectRatio, String>
    with CameraAspectRatioRef {
  _CameraAspectRatioProviderElement(super.provider);

  @override
  int get id => (origin as CameraAspectRatioProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
