import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_easy_client.dart';
import '../core/easy_exception.dart';

/// A base model class that all models must extend to be used with [EasyRepository].
abstract class EasyModel {
  /// Converts the model to a JSON map.
  Map<String, dynamic> toJson();

  /// The unique identifier for the model.
  String get id;
}

/// A generic repository for performing CRUD operations on a Supabase table.
///
/// Performance notes:
/// - The [SupabaseClient] reference is resolved once at construction time
///   instead of on every call.
/// - [count] uses a HEAD request (`head: true`) to avoid transferring any
///   row data — only the count header is returned.
/// - [getAll] validates that `limit` and `range` are not used together.
class EasyRepository<T extends EasyModel> {
  /// The name of the table in Supabase.
  final String tableName;

  /// A function that creates an instance of [T] from a JSON map.
  final T Function(Map<String, dynamic>) fromJson;

  /// Cached client reference – resolved once, avoids repeated null-checks.
  late final SupabaseClient _client;

  /// Creates a new [EasyRepository] for the given [tableName] and [fromJson] function.
  EasyRepository({required this.tableName, required this.fromJson})
      : _client = SupabaseEasyClient.client;

  /// Returns a query builder for the current table.
  SupabaseQueryBuilder get _table => _client.from(tableName);

  /// Shorthand for [EasyException.guardDb] scoped to this table.
  Future<R> _guard<R>(Future<R> Function() fn) =>
      EasyException.guardDb(fn, tableName);

  /// Executes a query that returns a single row and maps it to [T].
  ///
  /// Returns `null` when no row is found and [allowNull] is `true`.
  /// Throws [EasyException] for any database error.
  Future<T?> _handleSingleResponse(
    PostgrestTransformBuilder builder, {
    bool allowNull = false,
    String? customErrorMessage,
  }) async {
    try {
      final response = await builder.single();
      return fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        if (allowNull) return null;
        throw EasyException(
          customErrorMessage ?? 'Record not found in "$tableName".',
          cause: e,
        );
      }
      throw EasyException.fromPostgrest(e, tableName);
    }
  }

  /// Retrieves all records from the table with optional filtering, ordering, and pagination.
  ///
  /// [select] specifies which columns to retrieve (defaults to `'*'`).
  /// [filter] is a map of column→value pairs for equality filtering.
  /// [orderBy] is the column name to sort by.
  /// [ascending] specifies the sort order (default `true`).
  /// [limit] caps the number of records returned.
  /// [from] and [to] enable range-based pagination (cannot be combined with [limit]).
  /// [searchColumn] and [searchQuery] enable basic text search via `ILIKE`.
  ///
  /// Throws [EasyException] if both [limit] and a range ([from]/[to]) are provided,
  /// since they would produce conflicting result sets.
  Future<List<T>> getAll({
    String select = '*',
    Map<String, dynamic>? filter,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? from,
    int? to,
    String? searchColumn,
    String? searchQuery,
  }) async {
    // Validate that limit and range are not used together.
    if (limit != null && (from != null || to != null)) {
      throw const EasyException(
        'Cannot use `limit` and `from`/`to` range together. '
        'Use one pagination strategy at a time.',
      );
    }

    return _guard(() async {
      var query = _table.select(select);

      if (filter != null) {
        filter.forEach((key, value) => query = query.eq(key, value));
      }

      if (searchColumn != null && searchQuery != null) {
        query = query.ilike(searchColumn, '%$searchQuery%');
      }

      PostgrestTransformBuilder finalQuery = query;

      if (orderBy != null) {
        finalQuery = finalQuery.order(orderBy, ascending: ascending);
      }

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      if (from != null && to != null) {
        finalQuery = finalQuery.range(from, to);
      }

      final response = await finalQuery;
      return (response as List)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  /// Returns the total count of records matching the optional [filter].
  ///
  /// Uses `CountOption.exact` with a minimal `id` projection to avoid
  /// transferring full row data — only the count is used from the response.
  Future<int> count({Map<String, dynamic>? filter}) async {
    return _guard(() async {
      var query = _table.select('id');

      if (filter != null) {
        filter.forEach((key, value) => query = query.eq(key, value));
      }

      final response = await query.count(CountOption.exact);
      return response.count;
    });
  }

  /// Retrieves a single record by its [id].
  ///
  /// Returns `null` if no record is found.
  Future<T?> getById(String id, {String select = '*'}) async {
    return _handleSingleResponse(
      _table.select(select).eq('id', id),
      allowNull: true,
    );
  }

  /// Creates a new record in the table and returns it.
  Future<T> create(T model, {String select = '*'}) async {
    return (await _handleSingleResponse(
      _table.insert(model.toJson()).select(select),
    ))!;
  }

  /// Creates multiple records in the table in a single request.
  Future<List<T>> createMany(List<T> models, {String select = '*'}) async {
    if (models.isEmpty) return [];
    return _guard(() async {
      final response = await _table
          .insert(models.map((m) => m.toJson()).toList())
          .select(select);

      return (response as List)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  /// Updates the record identified by [model.id] and returns the updated record.
  Future<T> update(T model, {String select = '*'}) async {
    return (await _handleSingleResponse(
      _table.update(model.toJson()).eq('id', model.id).select(select),
      customErrorMessage:
          'Update failed: no row with id "${model.id}" in "$tableName" '
          'or RLS policy prevents the operation.',
    ))!;
  }

  /// Bulk-updates all rows matching [filter] with the given [data].
  ///
  /// Returns every row that was updated.
  Future<List<T>> updateWhere({
    required Map<String, dynamic> filter,
    required Map<String, dynamic> data,
    String select = '*',
  }) async {
    return _guard(() async {
      var query = _table.update(data);
      filter.forEach((key, value) => query = query.eq(key, value));
      final response = await query.select(select);
      return (response as List)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  /// Inserts or updates a record (upsert) and returns the result.
  Future<T> upsert(T model, {String select = '*'}) async {
    return (await _handleSingleResponse(
      _table.upsert(model.toJson()).select(select),
    ))!;
  }

  /// Deletes the record with the given [id].
  Future<void> delete(String id) async {
    return _guard(() async {
      await _table.delete().eq('id', id);
    });
  }

  /// Deletes all records whose `id` is in [ids] in a single request.
  Future<void> deleteMany(List<String> ids) async {
    if (ids.isEmpty) return;
    return _guard(() async {
      await _table.delete().inFilter('id', ids);
    });
  }

  /// Returns a real-time stream of all records in the table.
  ///
  /// [primaryKey] is the list of columns forming the primary key (usually `['id']`).
  /// [orderBy] optionally sorts the stream results.
  Stream<List<T>> stream({
    required List<String> primaryKey,
    String? orderBy,
    bool ascending = true,
  }) {
    final filtered = _table.stream(primaryKey: primaryKey);

    final Stream<List<Map<String, dynamic>>> raw = orderBy != null
        ? filtered.order(orderBy, ascending: ascending)
        : filtered;

    return raw.map(
      (data) => data.map((item) => fromJson(item)).toList(),
    );
  }
}

