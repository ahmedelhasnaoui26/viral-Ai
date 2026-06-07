import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/template_item.dart';

class TemplateRepository {
  TemplateRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<TemplateItem>> listTemplates({
    String? category,
    String sortBy = 'trending',
    int limit = 30,
  }) async {
    dynamic query = _supabase.from('templates').select();
    if (category != null &&
        category.isNotEmpty &&
        category != 'All' &&
        category != 'Trending') {
      query = query.eq('category', category);
    }

    switch (sortBy) {
      case 'most_used':
        query = query.order('uses_count', ascending: false);
        break;
      case 'most_liked':
        query = query.order('likes_count', ascending: false);
        break;
      case 'newest':
        query = query.order('created_at', ascending: false);
        break;
      case 'premium':
        query = query
            .eq('is_premium', true)
            .order('uses_count', ascending: false);
        break;
      case 'trending':
      default:
        query = query
            .order('is_trending', ascending: false)
            .order('uses_count', ascending: false)
            .order('created_at', ascending: false);
        break;
    }

    final rows = await query.limit(limit);
    return (rows as List<dynamic>)
        .map((row) => TemplateItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<TemplateItem?> getTemplateById(String id) async {
    final row = await _supabase
        .from('templates')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return TemplateItem.fromMap(row);
  }

  Future<List<TemplateItem>> searchTemplates(
    String query, {
    String sortBy = 'trending',
    int limit = 30,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return listTemplates(sortBy: sortBy, limit: limit);
    }

    dynamic select = _supabase
        .from('templates')
        .select()
        .or('title.ilike.%$normalized%,description.ilike.%$normalized%,category.ilike.%$normalized%');

    switch (sortBy) {
      case 'most_used':
        select = select.order('uses_count', ascending: false);
        break;
      case 'most_liked':
        select = select.order('likes_count', ascending: false);
        break;
      case 'newest':
        select = select.order('created_at', ascending: false);
        break;
      case 'trending':
      default:
        select = select
            .order('is_trending', ascending: false)
            .order('uses_count', ascending: false);
        break;
    }

    final rows = await select.limit(limit);
    return (rows as List<dynamic>)
        .map((row) => TemplateItem.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
