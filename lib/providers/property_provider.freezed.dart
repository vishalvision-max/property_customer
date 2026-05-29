// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'property_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PropertyState {
  bool get isLoading => throw _privateConstructorUsedError;
  List<Property> get all => throw _privateConstructorUsedError;
  List<Property> get featured => throw _privateConstructorUsedError;
  List<Property> get recommended => throw _privateConstructorUsedError;
  List<Property> get nearby => throw _privateConstructorUsedError;
  Property? get selected => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of PropertyState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PropertyStateCopyWith<PropertyState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PropertyStateCopyWith<$Res> {
  factory $PropertyStateCopyWith(
    PropertyState value,
    $Res Function(PropertyState) then,
  ) = _$PropertyStateCopyWithImpl<$Res, PropertyState>;
  @useResult
  $Res call({
    bool isLoading,
    List<Property> all,
    List<Property> featured,
    List<Property> recommended,
    List<Property> nearby,
    Property? selected,
    String? error,
  });
}

/// @nodoc
class _$PropertyStateCopyWithImpl<$Res, $Val extends PropertyState>
    implements $PropertyStateCopyWith<$Res> {
  _$PropertyStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PropertyState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? all = null,
    Object? featured = null,
    Object? recommended = null,
    Object? nearby = null,
    Object? selected = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            all: null == all
                ? _value.all
                : all // ignore: cast_nullable_to_non_nullable
                      as List<Property>,
            featured: null == featured
                ? _value.featured
                : featured // ignore: cast_nullable_to_non_nullable
                      as List<Property>,
            recommended: null == recommended
                ? _value.recommended
                : recommended // ignore: cast_nullable_to_non_nullable
                      as List<Property>,
            nearby: null == nearby
                ? _value.nearby
                : nearby // ignore: cast_nullable_to_non_nullable
                      as List<Property>,
            selected: freezed == selected
                ? _value.selected
                : selected // ignore: cast_nullable_to_non_nullable
                      as Property?,
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
abstract class _$$PropertyStateImplCopyWith<$Res>
    implements $PropertyStateCopyWith<$Res> {
  factory _$$PropertyStateImplCopyWith(
    _$PropertyStateImpl value,
    $Res Function(_$PropertyStateImpl) then,
  ) = __$$PropertyStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isLoading,
    List<Property> all,
    List<Property> featured,
    List<Property> recommended,
    List<Property> nearby,
    Property? selected,
    String? error,
  });
}

/// @nodoc
class __$$PropertyStateImplCopyWithImpl<$Res>
    extends _$PropertyStateCopyWithImpl<$Res, _$PropertyStateImpl>
    implements _$$PropertyStateImplCopyWith<$Res> {
  __$$PropertyStateImplCopyWithImpl(
    _$PropertyStateImpl _value,
    $Res Function(_$PropertyStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PropertyState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? all = null,
    Object? featured = null,
    Object? recommended = null,
    Object? nearby = null,
    Object? selected = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _$PropertyStateImpl(
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        all: null == all
            ? _value._all
            : all // ignore: cast_nullable_to_non_nullable
                  as List<Property>,
        featured: null == featured
            ? _value._featured
            : featured // ignore: cast_nullable_to_non_nullable
                  as List<Property>,
        recommended: null == recommended
            ? _value._recommended
            : recommended // ignore: cast_nullable_to_non_nullable
                  as List<Property>,
        nearby: null == nearby
            ? _value._nearby
            : nearby // ignore: cast_nullable_to_non_nullable
                  as List<Property>,
        selected: freezed == selected
            ? _value.selected
            : selected // ignore: cast_nullable_to_non_nullable
                  as Property?,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$PropertyStateImpl implements _PropertyState {
  const _$PropertyStateImpl({
    required this.isLoading,
    required final List<Property> all,
    required final List<Property> featured,
    required final List<Property> recommended,
    required final List<Property> nearby,
    required this.selected,
    required this.error,
  }) : _all = all,
       _featured = featured,
       _recommended = recommended,
       _nearby = nearby;

  @override
  final bool isLoading;
  final List<Property> _all;
  @override
  List<Property> get all {
    if (_all is EqualUnmodifiableListView) return _all;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_all);
  }

  final List<Property> _featured;
  @override
  List<Property> get featured {
    if (_featured is EqualUnmodifiableListView) return _featured;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_featured);
  }

  final List<Property> _recommended;
  @override
  List<Property> get recommended {
    if (_recommended is EqualUnmodifiableListView) return _recommended;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recommended);
  }

  final List<Property> _nearby;
  @override
  List<Property> get nearby {
    if (_nearby is EqualUnmodifiableListView) return _nearby;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nearby);
  }

  @override
  final Property? selected;
  @override
  final String? error;

  @override
  String toString() {
    return 'PropertyState(isLoading: $isLoading, all: $all, featured: $featured, recommended: $recommended, nearby: $nearby, selected: $selected, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PropertyStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality().equals(other._all, _all) &&
            const DeepCollectionEquality().equals(other._featured, _featured) &&
            const DeepCollectionEquality().equals(
              other._recommended,
              _recommended,
            ) &&
            const DeepCollectionEquality().equals(other._nearby, _nearby) &&
            (identical(other.selected, selected) ||
                other.selected == selected) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isLoading,
    const DeepCollectionEquality().hash(_all),
    const DeepCollectionEquality().hash(_featured),
    const DeepCollectionEquality().hash(_recommended),
    const DeepCollectionEquality().hash(_nearby),
    selected,
    error,
  );

  /// Create a copy of PropertyState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PropertyStateImplCopyWith<_$PropertyStateImpl> get copyWith =>
      __$$PropertyStateImplCopyWithImpl<_$PropertyStateImpl>(this, _$identity);
}

abstract class _PropertyState implements PropertyState {
  const factory _PropertyState({
    required final bool isLoading,
    required final List<Property> all,
    required final List<Property> featured,
    required final List<Property> recommended,
    required final List<Property> nearby,
    required final Property? selected,
    required final String? error,
  }) = _$PropertyStateImpl;

  @override
  bool get isLoading;
  @override
  List<Property> get all;
  @override
  List<Property> get featured;
  @override
  List<Property> get recommended;
  @override
  List<Property> get nearby;
  @override
  Property? get selected;
  @override
  String? get error;

  /// Create a copy of PropertyState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PropertyStateImplCopyWith<_$PropertyStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
