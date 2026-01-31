import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_easy_client.dart';

/// A base model class that all models must extend to be used with [EasyRepository].
abstract class EasyModel {
  /// Converts the model to a JSON map.
  Map<String, dynamic> toJson();

  /// The unique identifier for the model.
  String get id;
}

/// A generic repository for performing CRUD operations on a Supabase table.
class EasyRepository<T extends EasyModel> {
  /// The name of the table in Supabase.
  final String tableName;

  /// A function that creates an instance of [T] from a JSON map.
  final T Function(Map<String, dynamic>) fromJson;

  /// Creates a new [EasyRepository] for the given [tableName] and [fromJson] function.
  EasyRepository({required this.tableName, required this.fromJson});

  SupabaseClient get _client => SupabaseEasyClient.client;

  /// Returns a query builder for the current table.
  SupabaseQueryBuilder get _table => _client.from(tableName);

  /// Executes a query and returns a single item of type [T].
  /// Handles the common PGRST116 (no rows found) error by returning null if [allowNull] is true.
  Future<T?> _handleSingleResponse(
    PostgrestTransformBuilder builder, {
    bool allowNull = false,
    String? customErrorMessage,
  }) async {
    try {
      final response = await builder.single();
      return fromJson(response);
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') {
        if (allowNull) return null;
        throw PostgrestException(
          message: customErrorMessage ?? 'Record not found.',
          code: e.code,
          details: e.details,
          hint: e.hint,
        );
      }
      rethrow;
    }
  }

  /// Retrieves all records from the table with optional filtering, ordering, and pagination.
  ///
  /// [select] specifies which columns to retrieve (defaults to '*').
  /// [filter] is a map of column names and values for equality filtering.
  /// [orderBy] is the column name to sort by.
  /// [ascending] specifies the sort order.
  /// [limit] limits the number of records returned.
  /// [from] and [to] are used for range-based pagination.
  /// [searchColumn] and [searchQuery] can be used for basic text searching via ILIKE.
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
  }

  /// Returns the total count of records in the table.
  Future<int> count({Map<String, dynamic>? filter}) async {
    var query = _table.select('*');

    if (filter != null) {
      filter.forEach((key, value) => query = query.eq(key, value));
    }

    final response = await query.count(CountOption.exact);
    return response.count;
  }

  /// Creates multiple records in the table.
  Future<List<T>> createMany(List<T> models, {String select = '*'}) async {
    final response = await _table
        .insert(models.map((m) => m.toJson()).toList())
        .select(select);

    return (response as List)
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
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

  /// Creates a new record in the table.
  ///
  /// Returns the created record.
  Future<T> create(T model, {String select = '*'}) async {
    return (await _handleSingleResponse(
      _table.insert(model.toJson()).select(select),
    ))!;
  }

  /// Updates an existing record in the table.
  ///
  /// The [model] must have a valid [id].
  /// Returns the updated record.
  Future<T> update(T model, {String select = '*'}) async {
    return (await _handleSingleResponse(
      _table.update(model.toJson()).eq('id', model.id).select(select),
      customErrorMessage:
          'Update failed: No row found with id ${model.id} or RLS policy prevents update.',
    ))!;
  }

  /// Inserts or updates a record in the table.
  ///
  /// If a record with the same primary key exists, it will be updated.
  /// Otherwise, a new record will be inserted.
  Future<T> upsert(T model, {String select = '*'}) async {
    return (await _handleSingleResponse(
      _table.upsert(model.toJson()).select(select),
    ))!;
  }

  /// Deletes a record by its [id].
  Future<void> delete(String id) async {
    await _table.delete().eq('id', id);
  }

  /// Returns a real-time stream of all records in the table.
  ///
  /// [primaryKey] is a list of column names that form the primary key (usually `['id']`).
  Stream<List<T>> stream({required List<String> primaryKey}) {
    return _table
        .stream(primaryKey: primaryKey)
        .map((data) => data.map((item) => fromJson(item)).toList());
  }
}
