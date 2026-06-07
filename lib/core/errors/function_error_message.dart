import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns Supabase [FunctionException] into user-facing messages.
String friendlyFunctionError(Object error) {
  if (error is FunctionException) {
    final fromDetails = _messageFromDetails(error.details);
    if (fromDetails != null) return fromDetails;

    if (error.status == 502) {
      return 'R2 upload service returned an invalid response. Deploy the '
          'Cloudflare R2 signer Worker (see cloudflare/r2-signer-worker).';
    }

    if (error.status == 500 &&
        error.details?.toString() == 'Internal Server Error') {
      return 'Server error while preparing upload. Deploy the R2 signer Worker '
          '(cloudflare/r2-signer-worker) — the default "Hello World" Worker '
          'causes this.';
    }

    return 'Request failed (${error.status})';
  }

  final raw = error.toString();

  if (raw.contains('Invalid URL') && raw.contains('workers.dev')) {
    return 'R2_SIGNER_URL must start with https:// (e.g. '
        'https://your-worker.workers.dev). Update the secret in Supabase '
        'and run: supabase functions deploy sign-r2-object';
  }

  if (raw.contains('Signer not configured')) {
    return 'Upload service is not configured. Set R2_SIGNER_URL and '
        'R2_SIGNER_TOKEN in Supabase Edge Function secrets, then redeploy '
        'sign-r2-object.';
  }

  if (raw.contains('invalid JSON') || raw.contains('Hello World')) {
    return 'Cloudflare R2 signer is not deployed correctly. Replace the '
        '"Hello World" Worker with cloudflare/r2-signer-worker.';
  }

  if (raw.contains('NOT_FOUND') ||
      raw.contains('Requested function was not found')) {
    return 'Backend function not found. Deploy Supabase Edge Functions '
        '(sign-r2-object, create-generation-job, get-generation-job).';
  }

  if (raw.contains('Invalid version') ||
      raw.contains('not permitted') ||
      raw.contains('"status":422')) {
    return 'Replicate model version is invalid. In Supabase secrets, set '
        'REPLICATE_MODEL_VERSION to the full version id from your model\'s '
        'API page on replicate.com (64-character hash), then redeploy '
        'create-generation-job.';
  }

  if (raw.contains('compute resources') || raw.contains('WORKER_LIMIT')) {
    return 'Server is busy processing your video. Wait a moment and check Profile — '
        'or try again with a 5s video while extended processing finishes.';
  }

  if (raw.contains('idle timeout') || raw.contains('150s')) {
    return 'The server took too long to respond. Redeploy Edge Functions '
        '(with latest code), then try again. If it persists, check Replicate '
        'API token and model version in Supabase secrets.';
  }

  if (raw.contains('Unauthorized') || raw.contains('401')) {
    return 'Session expired. Please sign out and sign in again.';
  }

  final jsonMatch = RegExp(r'details:\s*(\{.*\})', dotAll: true).firstMatch(raw);
  if (jsonMatch != null) {
    final parsed = _messageFromDetails(jsonMatch.group(1));
    if (parsed != null) return parsed;
  }

  if (raw.length > 180) {
    return '${raw.substring(0, 180)}…';
  }
  return raw;
}

String? _messageFromDetails(dynamic details) {
  if (details is Map) {
    final hint = details['hint'];
    final error = details['error'];
    if (hint is String && hint.isNotEmpty) {
      if (error == 'Unauthorized' || error == 'R2 signer token rejected') {
        return hint;
      }
      if (error is String && error.isNotEmpty) {
        return '$error $hint';
      }
      return hint;
    }
    if (error is String && error.isNotEmpty) {
      if (error == 'Unauthorized') {
        return 'Authentication failed. Sign out and sign in again, or verify '
            'Cloudflare SIGNER_TOKEN matches Supabase R2_SIGNER_TOKEN.';
      }
      return error;
    }
    final message = details['message'];
    if (message is String && message.isNotEmpty) return message;
    return null;
  }

  if (details is String) {
    if (details.startsWith('{')) {
      try {
        return _messageFromDetails(jsonDecode(details));
      } catch (_) {
        return null;
      }
    }
    if (details == 'Internal Server Error') {
      return 'Server error. Deploy the R2 signer Worker and redeploy '
          'sign-r2-object (see docs/supabase_secrets_and_deploy.md).';
    }
    if (details.isNotEmpty) return details;
  }

  return null;
}
