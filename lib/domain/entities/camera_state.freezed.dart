// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'camera_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CameraState {
  int get id => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  bool get isConnected => throw _privateConstructorUsedError;
  bool get isConnecting => throw _privateConstructorUsedError;
  bool get isReceiveTimeout => throw _privateConstructorUsedError;
  Uint8List? get imageData => throw _privateConstructorUsedError;
  Map<String, dynamic>? get header => throw _privateConstructorUsedError;
  List<String> get logs => throw _privateConstructorUsedError;
  int get frameCount => throw _privateConstructorUsedError;
  double get receiveFps => throw _privateConstructorUsedError;
  double get renderFps => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  DateTime? get lastFrameTime => throw _privateConstructorUsedError;

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CameraStateCopyWith<CameraState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CameraStateCopyWith<$Res> {
  factory $CameraStateCopyWith(
    CameraState value,
    $Res Function(CameraState) then,
  ) = _$CameraStateCopyWithImpl<$Res, CameraState>;
  @useResult
  $Res call({
    int id,
    String address,
    bool isConnected,
    bool isConnecting,
    bool isReceiveTimeout,
    Uint8List? imageData,
    Map<String, dynamic>? header,
    List<String> logs,
    int frameCount,
    double receiveFps,
    double renderFps,
    String? error,
    DateTime? lastFrameTime,
  });
}

/// @nodoc
class _$CameraStateCopyWithImpl<$Res, $Val extends CameraState>
    implements $CameraStateCopyWith<$Res> {
  _$CameraStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? address = null,
    Object? isConnected = null,
    Object? isConnecting = null,
    Object? isReceiveTimeout = null,
    Object? imageData = freezed,
    Object? header = freezed,
    Object? logs = null,
    Object? frameCount = null,
    Object? receiveFps = null,
    Object? renderFps = null,
    Object? error = freezed,
    Object? lastFrameTime = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            isConnected: null == isConnected
                ? _value.isConnected
                : isConnected // ignore: cast_nullable_to_non_nullable
                      as bool,
            isConnecting: null == isConnecting
                ? _value.isConnecting
                : isConnecting // ignore: cast_nullable_to_non_nullable
                      as bool,
            isReceiveTimeout: null == isReceiveTimeout
                ? _value.isReceiveTimeout
                : isReceiveTimeout // ignore: cast_nullable_to_non_nullable
                      as bool,
            imageData: freezed == imageData
                ? _value.imageData
                : imageData // ignore: cast_nullable_to_non_nullable
                      as Uint8List?,
            header: freezed == header
                ? _value.header
                : header // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            logs: null == logs
                ? _value.logs
                : logs // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            frameCount: null == frameCount
                ? _value.frameCount
                : frameCount // ignore: cast_nullable_to_non_nullable
                      as int,
            receiveFps: null == receiveFps
                ? _value.receiveFps
                : receiveFps // ignore: cast_nullable_to_non_nullable
                      as double,
            renderFps: null == renderFps
                ? _value.renderFps
                : renderFps // ignore: cast_nullable_to_non_nullable
                      as double,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastFrameTime: freezed == lastFrameTime
                ? _value.lastFrameTime
                : lastFrameTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CameraStateImplCopyWith<$Res>
    implements $CameraStateCopyWith<$Res> {
  factory _$$CameraStateImplCopyWith(
    _$CameraStateImpl value,
    $Res Function(_$CameraStateImpl) then,
  ) = __$$CameraStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String address,
    bool isConnected,
    bool isConnecting,
    bool isReceiveTimeout,
    Uint8List? imageData,
    Map<String, dynamic>? header,
    List<String> logs,
    int frameCount,
    double receiveFps,
    double renderFps,
    String? error,
    DateTime? lastFrameTime,
  });
}

/// @nodoc
class __$$CameraStateImplCopyWithImpl<$Res>
    extends _$CameraStateCopyWithImpl<$Res, _$CameraStateImpl>
    implements _$$CameraStateImplCopyWith<$Res> {
  __$$CameraStateImplCopyWithImpl(
    _$CameraStateImpl _value,
    $Res Function(_$CameraStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? address = null,
    Object? isConnected = null,
    Object? isConnecting = null,
    Object? isReceiveTimeout = null,
    Object? imageData = freezed,
    Object? header = freezed,
    Object? logs = null,
    Object? frameCount = null,
    Object? receiveFps = null,
    Object? renderFps = null,
    Object? error = freezed,
    Object? lastFrameTime = freezed,
  }) {
    return _then(
      _$CameraStateImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        isConnected: null == isConnected
            ? _value.isConnected
            : isConnected // ignore: cast_nullable_to_non_nullable
                  as bool,
        isConnecting: null == isConnecting
            ? _value.isConnecting
            : isConnecting // ignore: cast_nullable_to_non_nullable
                  as bool,
        isReceiveTimeout: null == isReceiveTimeout
            ? _value.isReceiveTimeout
            : isReceiveTimeout // ignore: cast_nullable_to_non_nullable
                  as bool,
        imageData: freezed == imageData
            ? _value.imageData
            : imageData // ignore: cast_nullable_to_non_nullable
                  as Uint8List?,
        header: freezed == header
            ? _value._header
            : header // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        logs: null == logs
            ? _value._logs
            : logs // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        frameCount: null == frameCount
            ? _value.frameCount
            : frameCount // ignore: cast_nullable_to_non_nullable
                  as int,
        receiveFps: null == receiveFps
            ? _value.receiveFps
            : receiveFps // ignore: cast_nullable_to_non_nullable
                  as double,
        renderFps: null == renderFps
            ? _value.renderFps
            : renderFps // ignore: cast_nullable_to_non_nullable
                  as double,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastFrameTime: freezed == lastFrameTime
            ? _value.lastFrameTime
            : lastFrameTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$CameraStateImpl implements _CameraState {
  const _$CameraStateImpl({
    required this.id,
    required this.address,
    this.isConnected = false,
    this.isConnecting = false,
    this.isReceiveTimeout = false,
    this.imageData,
    final Map<String, dynamic>? header,
    final List<String> logs = const [],
    this.frameCount = 0,
    this.receiveFps = 0.0,
    this.renderFps = 0.0,
    this.error,
    this.lastFrameTime,
  }) : _header = header,
       _logs = logs;

  @override
  final int id;
  @override
  final String address;
  @override
  @JsonKey()
  final bool isConnected;
  @override
  @JsonKey()
  final bool isConnecting;
  @override
  @JsonKey()
  final bool isReceiveTimeout;
  @override
  final Uint8List? imageData;
  final Map<String, dynamic>? _header;
  @override
  Map<String, dynamic>? get header {
    final value = _header;
    if (value == null) return null;
    if (_header is EqualUnmodifiableMapView) return _header;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<String> _logs;
  @override
  @JsonKey()
  List<String> get logs {
    if (_logs is EqualUnmodifiableListView) return _logs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_logs);
  }

  @override
  @JsonKey()
  final int frameCount;
  @override
  @JsonKey()
  final double receiveFps;
  @override
  @JsonKey()
  final double renderFps;
  @override
  final String? error;
  @override
  final DateTime? lastFrameTime;

  @override
  String toString() {
    return 'CameraState(id: $id, address: $address, isConnected: $isConnected, isConnecting: $isConnecting, isReceiveTimeout: $isReceiveTimeout, imageData: $imageData, header: $header, logs: $logs, frameCount: $frameCount, receiveFps: $receiveFps, renderFps: $renderFps, error: $error, lastFrameTime: $lastFrameTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CameraStateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected) &&
            (identical(other.isConnecting, isConnecting) ||
                other.isConnecting == isConnecting) &&
            (identical(other.isReceiveTimeout, isReceiveTimeout) ||
                other.isReceiveTimeout == isReceiveTimeout) &&
            const DeepCollectionEquality().equals(other.imageData, imageData) &&
            const DeepCollectionEquality().equals(other._header, _header) &&
            const DeepCollectionEquality().equals(other._logs, _logs) &&
            (identical(other.frameCount, frameCount) ||
                other.frameCount == frameCount) &&
            (identical(other.receiveFps, receiveFps) ||
                other.receiveFps == receiveFps) &&
            (identical(other.renderFps, renderFps) ||
                other.renderFps == renderFps) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.lastFrameTime, lastFrameTime) ||
                other.lastFrameTime == lastFrameTime));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    address,
    isConnected,
    isConnecting,
    isReceiveTimeout,
    const DeepCollectionEquality().hash(imageData),
    const DeepCollectionEquality().hash(_header),
    const DeepCollectionEquality().hash(_logs),
    frameCount,
    receiveFps,
    renderFps,
    error,
    lastFrameTime,
  );

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CameraStateImplCopyWith<_$CameraStateImpl> get copyWith =>
      __$$CameraStateImplCopyWithImpl<_$CameraStateImpl>(this, _$identity);
}

abstract class _CameraState implements CameraState {
  const factory _CameraState({
    required final int id,
    required final String address,
    final bool isConnected,
    final bool isConnecting,
    final bool isReceiveTimeout,
    final Uint8List? imageData,
    final Map<String, dynamic>? header,
    final List<String> logs,
    final int frameCount,
    final double receiveFps,
    final double renderFps,
    final String? error,
    final DateTime? lastFrameTime,
  }) = _$CameraStateImpl;

  @override
  int get id;
  @override
  String get address;
  @override
  bool get isConnected;
  @override
  bool get isConnecting;
  @override
  bool get isReceiveTimeout;
  @override
  Uint8List? get imageData;
  @override
  Map<String, dynamic>? get header;
  @override
  List<String> get logs;
  @override
  int get frameCount;
  @override
  double get receiveFps;
  @override
  double get renderFps;
  @override
  String? get error;
  @override
  DateTime? get lastFrameTime;

  /// Create a copy of CameraState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CameraStateImplCopyWith<_$CameraStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
