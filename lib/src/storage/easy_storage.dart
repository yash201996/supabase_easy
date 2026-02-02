import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_easy_client.dart';

/// A simplified helper class for Supabase Storage operations.
class EasyStorage {
  static SupabaseClient get _client => SupabaseEasyClient.client;

  /// Returns the storage bucket with the given [bucketId].
  static StorageFileApi bucket(String bucketId) {
    return _client.storage.from(bucketId);
  }

  /// Uploads a file to a specific [bucketId] at the given [path].
  ///
  /// Supports both [File] and [Uint8List] (bytes).
  static Future<String> upload({
    required String bucketId,
    required String path,
    File? file,
    Uint8List? bytes,
    FileOptions options = const FileOptions(),
  }) async {
    if (file == null && bytes == null) {
      throw Exception('Either file or bytes must be provided for upload.');
    }

    if (file != null) {
      return await _client.storage
          .from(bucketId)
          .upload(path, file, fileOptions: options);
    } else {
      return await _client.storage
          .from(bucketId)
          .uploadBinary(path, bytes!, fileOptions: options);
    }
  }

  /// Downloads a file from the given [bucketId] and [path].
  static Future<Uint8List> download({
    required String bucketId,
    required String path,
  }) async {
    return await _client.storage.from(bucketId).download(path);
  }

  /// Deletes files from the given [bucketId] at the specified [paths].
  static Future<List<FileObject>> delete({
    required String bucketId,
    required List<String> paths,
  }) async {
    return await _client.storage.from(bucketId).remove(paths);
  }

  /// Gets the public URL for a file in a public bucket.
  static String getPublicUrl({
    required String bucketId,
    required String path,
    Map<String, dynamic>? transform,
  }) {
    final storage = _client.storage.from(bucketId);
    if (transform != null) {
      // For transformations (if enabled in Supabase project)
      return storage.getPublicUrl(path);
    }
    return storage.getPublicUrl(path);
  }

  /// Lists all files in a [bucketId] at the given [path].
  static Future<List<FileObject>> list({
    required String bucketId,
    String? path,
    SearchOptions options = const SearchOptions(),
  }) async {
    return await _client.storage
        .from(bucketId)
        .list(path: path, searchOptions: options);
  }

  /// Moves a file from [fromPath] to [toPath] within the same [bucketId].
  static Future<void> move({
    required String bucketId,
    required String fromPath,
    required String toPath,
  }) async {
    await _client.storage.from(bucketId).move(fromPath, toPath);
  }

  /// Copies a file from [fromPath] to [toPath] within the same [bucketId].
  static Future<void> copy({
    required String bucketId,
    required String fromPath,
    required String toPath,
  }) async {
    await _client.storage.from(bucketId).copy(fromPath, toPath);
  }

  /// Creates a signed URL for a file in a private bucket.
  /// [expiresIn] is the duration in seconds.
  static Future<String> createSignedUrl({
    required String bucketId,
    required String path,
    required int expiresIn,
  }) async {
    return await _client.storage
        .from(bucketId)
        .createSignedUrl(path, expiresIn);
  }
}
