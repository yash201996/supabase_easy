import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_easy_client.dart';

abstract class EasyModel {
  Map<String, dynamic> toJson();
  String get id;
}

class EasyRepository<T extends EasyModel> {
  final String tableName;
  final T Function(Map<String, dynamic>) fromJson;

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
  Future<List<T>> getAll({
    String select = '*',
    Map<String, dynamic>? filter,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? from,
    int? to,
  }) async {
    var query = _table.select(select);

    if (filter != null) {
      filter.forEach((key, value) => query = query.eq(key, value));
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

  /// Retrieves a single record by its [id].
  Future<T?> getById(String id, {String select = '*'}) async {
    return _handleSingleResponse(
      _table.select(select).eq('id', id),
      allowNull: true,
    );
  }

  /// Creates a new record in the table.
  Future<T> create(T model, {String select = '*'}) async {
    return (await _handleSingleResponse(
      _table.insert(model.toJson()).select(select),
    ))!;
  }

  /// Updates an existing record in the table.
  Future<T> update(T model, {String select = '*'}) async {
    return (await _handleSingleResponse(
      _table.update(model.toJson()).eq('id', model.id).select(select),
      customErrorMessage:
          'Update failed: No row found with id ${model.id} or RLS policy prevents update.',
    ))!;
  }

  /// Inserts or updates a record in the table.
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
  Stream<List<T>> stream({required List<String> primaryKey}) {
    return _table
        .stream(primaryKey: primaryKey)
        .map((data) => data.map((item) => fromJson(item)).toList());
  }
}
