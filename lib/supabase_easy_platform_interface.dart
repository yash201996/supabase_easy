import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'supabase_easy_method_channel.dart';

abstract class SupabaseEasyPlatform extends PlatformInterface {
  /// Constructs a SupabaseEasyPlatform.
  SupabaseEasyPlatform() : super(token: _token);

  static final Object _token = Object();

  static SupabaseEasyPlatform _instance = MethodChannelSupabaseEasy();

  /// The default instance of [SupabaseEasyPlatform] to use.
  ///
  /// Defaults to [MethodChannelSupabaseEasy].
  static SupabaseEasyPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SupabaseEasyPlatform] when
  /// they register themselves.
  static set instance(SupabaseEasyPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
