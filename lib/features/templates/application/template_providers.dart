import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/template_repository.dart';
import '../domain/template_item.dart';

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  return TemplateRepository(ref.watch(supabaseClientProvider));
});

class TemplateFilters {
  const TemplateFilters({
    this.sort = 'trending',
    this.category = 'All',
    this.query = '',
  });

  final String sort;
  final String category;
  final String query;

  TemplateFilters copyWith({
    String? sort,
    String? category,
    String? query,
  }) {
    return TemplateFilters(
      sort: sort ?? this.sort,
      category: category ?? this.category,
      query: query ?? this.query,
    );
  }
}

class TemplateFiltersNotifier extends Notifier<TemplateFilters> {
  @override
  TemplateFilters build() => const TemplateFilters();

  void setSort(String sort) {
    state = state.copyWith(sort: sort);
  }

  void setCategory(String category) {
    state = state.copyWith(category: category);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }
}

final templateFiltersProvider =
    NotifierProvider<TemplateFiltersNotifier, TemplateFilters>(
  TemplateFiltersNotifier.new,
);

final templatesProvider = FutureProvider<List<TemplateItem>>((ref) async {
  final repo = ref.watch(templateRepositoryProvider);
  final filters = ref.watch(templateFiltersProvider);
  final query = filters.query;
  final category = filters.category;
  final sort = filters.sort;
  if (query.trim().isNotEmpty) {
    return repo.searchTemplates(query, sortBy: sort);
  }
  return repo.listTemplates(category: category, sortBy: sort);
});

final templateByIdProvider =
    FutureProvider.family<TemplateItem?, String>((ref, templateId) async {
  final repo = ref.watch(templateRepositoryProvider);
  return repo.getTemplateById(templateId);
});
