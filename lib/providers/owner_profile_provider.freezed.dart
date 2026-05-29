// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'owner_profile_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$OwnerProfileState {
  bool get isLoading => throw _privateConstructorUsedError;
  OwnerProfile? get profile => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of OwnerProfileState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OwnerProfileStateCopyWith<OwnerProfileState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OwnerProfileStateCopyWith<$Res> {
  factory $OwnerProfileStateCopyWith(
    OwnerProfileState value,
    $Res Function(OwnerProfileState) then,
  ) = _$OwnerProfileStateCopyWithImpl<$Res, OwnerProfileState>;
  @useResult
  $Res call({bool isLoading, OwnerProfile? profile, String? error});
}

/// @nodoc
class _$OwnerProfileStateCopyWithImpl<$Res, $Val extends OwnerProfileState>
    implements $OwnerProfileStateCopyWith<$Res> {
  _$OwnerProfileStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OwnerProfileState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? profile = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            profile: freezed == profile
                ? _value.profile
                : profile // ignore: cast_nullable_to_non_nullable
                      as OwnerProfile?,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OwnerProfileStateImplCopyWith<$Res>
    implements $OwnerProfileStateCopyWith<$Res> {
  factory _$$OwnerProfileStateImplCopyWith(
    _$OwnerProfileStateImpl value,
    $Res Function(_$OwnerProfileStateImpl) then,
  ) = __$$OwnerProfileStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isLoading, OwnerProfile? profile, String? error});
}

/// @nodoc
class __$$OwnerProfileStateImplCopyWithImpl<$Res>
    extends _$OwnerProfileStateCopyWithImpl<$Res, _$OwnerProfileStateImpl>
    implements _$$OwnerProfileStateImplCopyWith<$Res> {
  __$$OwnerProfileStateImplCopyWithImpl(
    _$OwnerProfileStateImpl _value,
    $Res Function(_$OwnerProfileStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OwnerProfileState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? profile = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _$OwnerProfileStateImpl(
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        profile: freezed == profile
            ? _value.profile
            : profile // ignore: cast_nullable_to_non_nullable
                  as OwnerProfile?,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$OwnerProfileStateImpl implements _OwnerProfileState {
  const _$OwnerProfileStateImpl({
    required this.isLoading,
    required this.profile,
    required this.error,
  });

  @override
  final bool isLoading;
  @override
  final OwnerProfile? profile;
  @override
  final String? error;

  @override
  String toString() {
    return 'OwnerProfileState(isLoading: $isLoading, profile: $profile, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OwnerProfileStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.profile, profile) || other.profile == profile) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isLoading, profile, error);

  /// Create a copy of OwnerProfileState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OwnerProfileStateImplCopyWith<_$OwnerProfileStateImpl> get copyWith =>
      __$$OwnerProfileStateImplCopyWithImpl<_$OwnerProfileStateImpl>(
        this,
        _$identity,
      );
}

abstract class _OwnerProfileState implements OwnerProfileState {
  const factory _OwnerProfileState({
    required final bool isLoading,
    required final OwnerProfile? profile,
    required final String? error,
  }) = _$OwnerProfileStateImpl;

  @override
  bool get isLoading;
  @override
  OwnerProfile? get profile;
  @override
  String? get error;

  /// Create a copy of OwnerProfileState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OwnerProfileStateImplCopyWith<_$OwnerProfileStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
