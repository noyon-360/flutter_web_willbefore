const _unset = Object();

/// Filter state for the users list. The role and created-date filters run
/// server-side so they cover every page. The status, email-verified,
/// has-phone, pending-orders and in-cart filters only see the rows loaded so
/// far.
class UserListQuery {
  // Server-side filters.
  final String? role;
  final bool? isActive;
  final bool? isEmailVerified;
  final DateTime? createdFrom;
  final DateTime? createdTo;

  // Client-side (loaded rows only) filters.
  final bool? hasPhone;
  final bool? hasPendingOrders;
  final bool? hasCartItems;

  const UserListQuery({
    this.role,
    this.isActive,
    this.isEmailVerified,
    this.createdFrom,
    this.createdTo,
    this.hasPhone,
    this.hasPendingOrders,
    this.hasCartItems,
  });

  UserListQuery copyWith({
    Object? role = _unset,
    Object? isActive = _unset,
    Object? isEmailVerified = _unset,
    Object? createdFrom = _unset,
    Object? createdTo = _unset,
    Object? hasPhone = _unset,
    Object? hasPendingOrders = _unset,
    Object? hasCartItems = _unset,
  }) {
    return UserListQuery(
      role: identical(role, _unset) ? this.role : role as String?,
      isActive: identical(isActive, _unset) ? this.isActive : isActive as bool?,
      isEmailVerified: identical(isEmailVerified, _unset)
          ? this.isEmailVerified
          : isEmailVerified as bool?,
      createdFrom: identical(createdFrom, _unset)
          ? this.createdFrom
          : createdFrom as DateTime?,
      createdTo: identical(createdTo, _unset)
          ? this.createdTo
          : createdTo as DateTime?,
      hasPhone: identical(hasPhone, _unset) ? this.hasPhone : hasPhone as bool?,
      hasPendingOrders: identical(hasPendingOrders, _unset)
          ? this.hasPendingOrders
          : hasPendingOrders as bool?,
      hasCartItems: identical(hasCartItems, _unset)
          ? this.hasCartItems
          : hasCartItems as bool?,
    );
  }

  /// Number of filters currently applied .
  int get activeFilterCount => [
    role,
    isActive,
    isEmailVerified,
    createdFrom ?? createdTo,
    hasPhone,
    hasPendingOrders,
    hasCartItems,
  ].where((v) => v != null).length;

  bool get hasFilters => activeFilterCount > 0;

  /// True when a filter is applied to loaded rows only.
  bool get hasClientFilters => [
    isActive,
    isEmailVerified,
    hasPhone,
    hasPendingOrders,
    hasCartItems,
  ].any((v) => v != null);

  // isActive / isEmailVerified are filtered client-side: Firestore equality
  // filters skip documents that lack the field, and not every user doc has it.
  Map<String, dynamic> get serverFilters => {if (role != null) 'role': role};
}
