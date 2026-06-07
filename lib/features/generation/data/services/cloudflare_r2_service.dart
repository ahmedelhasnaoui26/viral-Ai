import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/http_url.dart';

/// Client wrapper for Cloudflare R2 operations via the sign-r2-object edge function.
///
/// Input images are uploaded from the device; output videos are archived server-side.
class CloudflareR2Service {
  CloudflareR2Service(this._supabase, this._dio);

  final SupabaseClient _supabase;
  final Dio _dio;

  /// Step 1 — Request a presigned PUT URL for an input image upload.
  Future<({String objectKey, Uri uploadUrl})> createInputUploadUrl({
    required String fileName,
    required String contentType,
  }) async {
    final response = await _supabase.functions.invoke(
      'sign-r2-object',
      body: {
        'operation': 'upload',
        'fileName': fileName,
        'contentType': contentType,
      },
    );
    final data = _map(response.data);
    return (
      objectKey: data['objectKey'] as String,
      uploadUrl: parseHttpUri(data['signedUrl'] as String, fieldName: 'signedUrl'),
    );
  }

  /// Upload bytes to R2 using a presigned URL (input images only on client).
  Future<void> uploadFile({
    required File file,
    required Uri uploadUrl,
    required String contentType,
    required void Function(double progress) onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    await _dio.putUri(
      uploadUrl,
      data: bytes,
      options: Options(headers: {'content-type': contentType}),
      onSendProgress: (sent, total) {
        if (total <= 0) return;
        onProgress(sent / total);
      },
    );
  }

  /// Resolve a short-lived signed GET URL for private R2 object keys.
  Future<String> getSignedDownloadUrl(String objectKey) async {
    final response = await _supabase.functions.invoke(
      'sign-r2-object',
      body: {'operation': 'download', 'objectKey': objectKey},
    );
    final data = _map(response.data);
    final error = data['error'];
    if (error is String && error.isNotEmpty) {
      throw AppFailure(error);
    }
    final signedUrl = data['signedUrl'] as String?;
    if (signedUrl == null || signedUrl.isEmpty) {
      throw const AppFailure('Failed to obtain signed URL from backend');
    }
    return signedUrl;
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const AppFailure('Unexpected response from storage service');
    }
    return data;
  }
}
