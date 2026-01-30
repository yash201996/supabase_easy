import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'supabase_easy_platform_interface.dart';

/// An implementation of [SupabaseEasyPlatform] that uses method channels.
class MethodChannelSupabaseEasy extends SupabaseEasyPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('supabase_easy');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
