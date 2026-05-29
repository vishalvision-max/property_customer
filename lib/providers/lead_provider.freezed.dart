// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lead_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LeadState {
  bool get isLoading => throw _privateConstructorUsedError;
  List<Lead> get items => throw _privateConstructorUsedError;
  int get currentPage => throw _privateConstructorUsedError;
  int get lastPage => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of LeadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LeadStateCopyWith<LeadState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LeadStateCopyWith<$Res> {
  factory $LeadStateCopyWith(LeadState value, $Res Function(LeadState) then) =
      _$LeadStateCopyWithImpl<$Res, LeadState>;
  @useResult
  $Res call({
    bool isLoading,
    List<Lead> items,
    int currentPage,
    int lastPage,
    int total,
    String? error,
  });
}

/// @nodoc
class _$LeadStateCopyWithImpl<$Res, $Val extends LeadState>
    implements $LeadStateCopyWith<$Res> {
  _$LeadStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LeadState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? items = null,
    Object? currentPage = null,
    Object? lastPage = null,
    Object? total = null,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<Lead>,
            currentPage: null == currentPage
                ? _value.currentPage
                : currentPage // ignore: cast_nullable_to_non_nullable
                      as int,
            lastPage: null == lastPage
                ? _value.lastPage
                : lastPage // ignore: cast_nullable_to_non_nullable
                      as int,
            total: null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int,
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
abstract class _$$LeadStateImplCopyWith<$Res>
    implements $LeadStateCopyWith<$Res> {
  factory _$$LeadStateImplCopyWith(
    _$LeadStateImpl value,
    $Res Function(_$LeadStateImpl) then,
  ) = __$$LeadStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isLoading,
    List<Lead> items,
    int currentPage,
    int lastPage,
    int total,
    String? error,
  });
}

/// @nodoc
class __$$LeadStateImplCopyWithImpl<$Res>
    extends _$LeadStateCopyWithImpl<$Res, _$LeadStateImpl>
    implements _$$LeadStateImplCopyWith<$Res> {
  __$$LeadStateImplCopyWithImpl(
    _$LeadStateImpl _value,
    $Res Function(_$LeadStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LeadState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? items = null,
    Object? currentPage = null,
    Object? lastPage = null,
    Object? total = null,
    Object? error = freezed,
  }) {
    return _then(
      _$LeadStateImpl(
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<Lead>,
        currentPage: null == currentPage
            ? _value.currentPage
            : currentPage // ignore: cast_nullable_to_non_nullable
                  as int,
        lastPage: null == lastPage
            ? _value.lastPage
            : lastPage // ignore: cast_nullable_to_non_nullable
                  as int,
        total: null == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$LeadStateImpl implements _LeadState {
  const _$LeadStateImpl({
    required this.isLoading,
    required final List<Lead> items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.error,
  }) : _items = items;

  @override
  final bool isLoading;
  final List<Lead> _items;
  @override
  List<Lead> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final int currentPage;
  @override
  final int lastPage;
  @override
  final int total;
  @override
  final String? error;

  @override
  String toString() {
    return 'LeadState(isLoading: $isLoading, items: $items, currentPage: $currentPage, lastPage: $lastPage, total: $total, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LeadStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.lastPage, lastPage) ||
                other.lastPage == lastPage) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isLoading,
    const DeepCollectionEquality().hash(_items),
    currentPage,
    lastPage,
    total,
    error,
  );

  /// Create a copy of LeadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LeadStateImplCopyWith<_$LeadStateImpl> get copyWith =>
      __$$LeadStateImplCopyWithImpl<_$LeadStateImpl>(this, _$identity);
}

abstract class _LeadState implements LeadState {
  const factory _LeadState({
    required final bool isLoading,
    required final List<Lead> items,
    required final int currentPage,
    required final int lastPage,
    required final int total,
    required final String? error,
  }) = _$LeadStateImpl;

  @override
  bool get isLoading;
  @override
  List<Lead> get items;
  @override
  int get currentPage;
  @override
  int get lastPage;
  @override
  int get total;
  @override
  String? get error;

  /// Create a copy of LeadState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LeadStateImplCopyWith<_$LeadStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
