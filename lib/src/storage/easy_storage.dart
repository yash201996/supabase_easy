import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_easy_client.dart';
import '../core/easy_exception.dart';

/// Common MIME-type lookup by file extension.
///
/// Used by [EasyStorage.upload] to auto-detect content type when the caller
/// does not provide one explicitly via [FileOptions.contentType].
const _mimeTypes = <String, String>{
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.gif': 'image/gif',
  '.webp': 'image/webp',
  '.svg': 'image/svg+xml',
  '.bmp': 'image/bmp',
  '.ico': 'image/x-icon',
  '.pdf': 'application/pdf',
  '.json': 'application/json',
  '.xml': 'application/xml',
  '.zip': 'application/zip',
  '.gz': 'application/gzip',
  '.tar': 'application/x-tar',
  '.mp3': 'audio/mpeg',
  '.wav': 'audio/wav',
  '.mp4': 'video/mp4',
  '.mov': 'video/quicktime',
  '.avi': 'video/x-msvideo',
  '.txt': 'text/plain',
  '.html': 'text/html',
  '.css': 'text/css',
  '.csv': 'text/csv',
  '.doc': 'application/msword',
  '.docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  '.xls': 'application/vnd.ms-excel',
  '.xlsx':
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  '.ppt': 'application/vnd.ms-powerpoint',
  '.pptx':
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
};

/// Returns the MIME type for [path] based on its file extension, or `null`
/// if the extension is not recognised.
String? _detectMimeType(String path) {
  final dot = path.lastIndexOf('.');
  if (dot == -1) return null;
  return _mimeTypes[path.substring(dot).toLowerCase()];
}

/// A simplified helper class for Supabase Storage operations.
///
/// Performance notes:
/// - All methods use [EasyException.guardStorage] which catches
///   [StorageException], [SocketException], and unexpected errors in one place.
/// - [upload] auto-detects the MIME content type from the file extension when
///   the caller does not provide one. This prevents Supabase from storing files
///   as `application/octet-stream`, which improves browser caching and
///   inline rendering.
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
  ///
  /// The content type is auto-detected from [path]'s extension when
  /// [options.contentType] is not explicitly set.
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

    // Auto-detect content type when the caller hasn't set one.
    final effectiveOptions = options.contentType == null
        ? FileOptions(
            upsert: options.upsert,
            contentType: _detectMimeType(path),
          )
        : options;

    return EasyException.guardStorage(() {
      if (file != null) {
        return _client.storage
            .from(bucketId)
            .upload(path, file, fileOptions: effectiveOptions);
      } else {
        return _client.storage
            .from(bucketId)
            .uploadBinary(path, bytes!, fileOptions: effectiveOptions);
      }
    });
  }

  /// Downloads a file from the given [bucketId] and [path].
  static Future<Uint8List> download({
    required String bucketId,
    required String path,
  }) =>
      EasyException.guardStorage(
        () => _client.storage.from(bucketId).download(path),
      );

  /// Deletes files from the given [bucketId] at the specified [paths].
  static Future<List<FileObject>> delete({
    required String bucketId,
    required List<String> paths,
  }) =>
      EasyException.guardStorage(
        () => _client.storage.from(bucketId).remove(paths),
      );

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
  }) =>
      EasyException.guardStorage(
        () => _client.storage
            .from(bucketId)
            .list(path: path, searchOptions: options),
      );

  /// Moves a file from [fromPath] to [toPath] within the same [bucketId].
  static Future<void> move({
    required String bucketId,
    required String fromPath,
    required String toPath,
  }) =>
      EasyException.guardStorage(
        () => _client.storage.from(bucketId).move(fromPath, toPath),
      );

  /// Copies a file from [fromPath] to [toPath] within the same [bucketId].
  static Future<void> copy({
    required String bucketId,
    required String fromPath,
    required String toPath,
  }) =>
      EasyException.guardStorage(
        () => _client.storage.from(bucketId).copy(fromPath, toPath),
      );

  /// Creates a signed URL for a file in a private bucket.
  ///
  /// [expiresIn] is the duration in seconds before the URL expires.
  static Future<String> createSignedUrl({
    required String bucketId,
    required String path,
    required int expiresIn,
  }) =>
      EasyException.guardStorage(
        () => _client.storage.from(bucketId).createSignedUrl(path, expiresIn),
      );
}

