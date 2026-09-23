import 'package:cloud_functions/cloud_functions.dart';

/// One page of results from a `getXPage`-style callable Cloud Function.
class PaginatedFetchResult<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  const PaginatedFetchResult({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });
}

/// Calls a paginated-list callable Cloud Function (see
/// `functions/controllers/paginated_list.js`) and decodes its response.
Future<PaginatedFetchResult<T>> fetchPaginatedPage<T>({
  required String functionName,
  required T Function(Map<String, dynamic> data) fromMap,
  String? cursor,
  String? searchTerm,
  int pageSize = 20,
}) async {
  final callable = FirebaseFunctions.instance.httpsCallable(
    functionName,
    options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
  );

  final result = await callable.call(<String, dynamic>{
    if (cursor != null) 'cursor': cursor,
    if (searchTerm != null && searchTerm.isNotEmpty) 'searchTerm': searchTerm,
    'pageSize': pageSize,
  });

  final data = Map<String, dynamic>.from(result.data as Map);
  final items = (data['items'] as List)
      .map((e) => fromMap(Map<String, dynamic>.from(e as Map)))
      .toList();

  return PaginatedFetchResult<T>(
    items: items,
    nextCursor: data['nextCursor'] as String?,
    hasMore: data['hasMore'] as bool? ?? false,
  );
}
