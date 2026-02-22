import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_easy_client.dart';
import '../core/easy_exception.dart';

/// A simplified helper class for Supabase Storage operations.
class EasyStorage {
  static SupabaseClient get _client => SupabaseEasyClient.client;

  /// Returns the storage bucket with the given [bucketId].
  static StorageFileApi bucket(String bucketId) {
    return _client.storage.from(bucketId);
  }

  /// Uploads a file to a specific [bucketId] at the given [path].
  ///
  /// Provide either a [file] (io.File) or raw [bytes] (Uint8List).
  /// Throws [EasyException] when neither is supplied.
  static Future<String> upload({
    required String bucketId,
    required String path,
    File? file,
    Uint8List? bytes,
    FileOptions options = const FileOptions(),
  }) async {
    if (file == null && bytes == null) {
      throw const EasyException(
        'Either `file` or `bytes` must be provided for upload.',
      );
    }
    try {
      if (file != null) {
        return await _client.storage
            .from(bucketId)
            .upload(path, file, fileOptions: options);
      } else {
        return await _client.storage
            .from(bucketId)
            .uploadBinary(path, bytes!, fileOptions: options);
      }
    } on StorageException catch (e) {
      throw EasyException.fromStorage(e);
    }
  }

  /// Downloads a file from the given [bucketId] and [path].
  static Future<Uint8List> download({
    required String bucketId,
    required String path,
  }) async {
    try {
      return await _client.storage.from(bucketId).download(path);
    } on StorageException catch (e) {
      throw EasyException.fromStorage(e);
    }
  }

  /// Deletes files from the given [bucketId] at the specified [paths].
  static Future<List<FileObject>> delete({
    required String bucketId,
    required List<String> paths,
  }) async {
    try {
      return await _client.storage.from(bucketId).remove(paths);
    } on StorageException catch (e) {
      throw EasyException.fromStorage(e);
    }
  }

  /// Gets the public URL for a file in a public bucket.
  ///
  /// Pass [transform] to apply server-side image transformations
  /// (width, height, resize, format, quality) when the feature is enabled
  /// in your Supabase project.
  static String getPublicUrl({
    required String bucketId,
    required String path,
    TransformOptions? transform,
  }) {
    final storage = _client.storage.from(bucketId);
    return storage.getPublicUrl(path, transform: transform);
  }

  /// Lists all files in a [bucketId] at the given [path].
  static Future<List<FileObject>> list({
    required String bucketId,
    String? path,
    SearchOptions options = const SearchOptions(),
  }) async {
    try {
      return await _client.storage
          .from(bucketId)
          .list(path: path, searchOptions: options);
    } on StorageException catch (e) {
      throw EasyException.fromStorage(e);
    }
  }

  /// Moves a file from [fromPath] to [toPath] within the same [bucketId].
  static Future<void> move({
    required String bucketId,
    required String fromPath,
    required String toPath,
  }) async {
    try {
      await _client.storage.from(bucketId).move(fromPath, toPath);
    } on StorageException catch (e) {
      throw EasyException.fromStorage(e);
    }
  }

  /// Copies a file from [fromPath] to [toPath] within the same [bucketId].
  static Future<void> copy({
    required String bucketId,
    required String fromPath,
    required String toPath,
  }) async {
    try {
      await _client.storage.from(bucketId).copy(fromPath, toPath);
    } on StorageException catch (e) {
      throw EasyException.fromStorage(e);
    }
  }

  /// Creates a signed URL for a file in a private bucket.
  ///
  /// [expiresIn] is the duration in seconds before the URL expires.
  static Future<String> createSignedUrl({
    required String bucketId,
    required String path,
    required int expiresIn,
  }) async {
    try {
      return await _client.storage
          .from(bucketId)
          .createSignedUrl(path, expiresIn);
    } on StorageException catch (e) {
      throw EasyException.fromStorage(e);
    }
  }
}

