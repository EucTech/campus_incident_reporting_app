import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/failure.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/state_views.dart';
import '../application/incident_providers.dart';
import '../domain/incident_enums.dart';
import 'widgets/category_visuals.dart';
import 'widgets/filter_pill.dart';
import 'widgets/incident_card.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    ref.read(incidentFilterProvider.notifier).clear();
  }

  Future<void> _pickCategory() async {
    final filter = ref.read(incidentFilterProvider.notifier);
    final current = ref.read(incidentFilterProvider).category;
    await showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterPill(
                label: 'All types',
                selected: current == null,
                onTap: () {
                  filter.setCategory(null);
                  Navigator.pop(sheetContext);
                },
              ),
              for (final category in IncidentCategory.values)
                FilterPill(
                  label: category.label,
                  icon: category.icon,
                  selected: current == category,
                  onTap: () {
                    filter.setCategory(category);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final filter = ref.watch(incidentFilterProvider);
    final results = ref.watch(filteredIncidentsProvider);
    final notifier = ref.read(incidentFilterProvider.notifier);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Reports', style: context.text.displayMedium),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  onChanged: notifier.setQuery,
                  textInputAction: TextInputAction.search,
                  style: context.text.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Search title, place or details',
                    prefixIcon: Icon(Icons.search_rounded, color: p.muted),
                    suffixIcon: filter.query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: Icon(Icons.close_rounded, size: 20, color: p.muted),
                            onPressed: () {
                              _search.clear();
                              notifier.setQuery('');
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                FilterPill(
                  label: 'Mine',
                  icon: Icons.person_outline_rounded,
                  selected: filter.mineOnly,
                  onTap: () => notifier.setMineOnly(!filter.mineOnly),
                ),
                const SizedBox(width: 8),
                FilterPill(
                  label: filter.category?.label ?? 'Type',
                  icon: filter.category?.icon ?? Icons.tune_rounded,
                  selected: filter.category != null,
                  onTap: _pickCategory,
                ),
                const SizedBox(width: 8),
                for (final status in IncidentStatus.values) ...[
                  FilterPill(
                    label: status.label,
                    selected: filter.status == status,
                    onTap: () => notifier.setStatus(filter.status == status ? null : status),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: results.when(
              loading: () => const SingleChildScrollView(padding: EdgeInsets.all(20), child: SkeletonList()),
              error: (error, _) => Center(
                child: ErrorView(message: friendlyError(error), onRetry: () => ref.invalidate(incidentsProvider)),
              ),
              data: (incidents) {
                if (incidents.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: EmptyView(
                        title: filter.isActive ? 'No matches' : 'All quiet',
                        message: filter.isActive
                            ? 'Try a different search or clear your filters.'
                            : 'Nothing has been reported yet.',
                        action: filter.isActive
                            ? PillButton(label: 'Clear filters', compact: true, onPressed: _clearFilters)
                            : null,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 130),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: incidents.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => IncidentCard(
                    key: ValueKey(incidents[index].id),
                    incident: incidents[index],
                  ).animate().fadeIn(delay: (index.clamp(0, 6) * 40).ms, duration: 280.ms).slideY(begin: 0.08),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
