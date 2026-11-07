import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/application/auth_providers.dart';
import '../application/incident_providers.dart';
import '../domain/incident.dart';
import '../domain/incident_enums.dart';
import 'widgets/category_visuals.dart';
import 'widgets/incident_art.dart';
import 'widgets/status_sheet.dart';
import 'widgets/status_track.dart';

class IncidentDetailScreen extends ConsumerWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(incidentByIdProvider(incidentId))
        .when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            body: Center(
              child: ErrorView(message: friendlyError(error), onRetry: () => ref.invalidate(incidentsProvider)),
            ),
          ),
          data: (incident) => incident == null
              ? Scaffold(
                  appBar: AppBar(),
                  body: const Center(
                    child: EmptyView(title: 'Report removed', message: 'This report is no longer available.'),
                  ),
                )
              : _DetailBody(incident: incident),
        );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.incident});

  final Incident incident;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete this report?', style: dialogContext.text.titleLarge),
        content: Text('This cannot be undone.', style: dialogContext.text.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final done = await ref.read(incidentControllerProvider.notifier).remove(incident);
    if (!context.mounted) return;
    if (done) {
      context.pop();
    } else {
      showMessage(context, friendlyError(ref.read(incidentControllerProvider).error!));
    }
  }

  Future<void> _toggleAffected(BuildContext context, WidgetRef ref, bool affected) async {
    final done = await ref.read(incidentControllerProvider.notifier).setAffected(incident, affected);
    if (!done && context.mounted) {
      showMessage(context, friendlyError(ref.read(incidentControllerProvider).error!));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final uid = ref.watch(currentUidProvider);
    final isStaff = ref.watch(isStaffProvider);
    final canEdit = incident.canEdit(uid);
    final canDelete = canEdit || isStaff;
    final affected = incident.affectedBy.contains(uid);
    final canMarkAffected = !incident.isOwnedBy(uid) && incident.status.isOpen;
    final reporter = incident.reporterName ?? 'Anonymous';

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.card + 6)),
                          child: IncidentArt(incident: incident, iconSize: 72),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.paddingOf(context).top + 10,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            RoundIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => context.pop()),
                            const Spacer(),
                            if (canEdit) ...[
                              RoundIconButton(
                                icon: Icons.edit_outlined,
                                label: 'Edit report',
                                onTap: () => context.push('/incident/${incident.id}/edit'),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (canDelete)
                              RoundIconButton(
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete report',
                                onTap: () => _confirmDelete(context, ref),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            StatusChip(status: incident.status),
                            const SizedBox(width: 6),
                            if (incident.severity == IncidentSeverity.high && incident.status.isOpen) const UrgentTag(),
                            const Spacer(),
                            Icon(incident.category.icon, size: 16, color: p.muted),
                            const SizedBox(width: 5),
                            Text(incident.category.label, style: context.text.bodyMedium),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(incident.title, style: context.text.headlineMedium),
                        const SizedBox(height: 10),
                        _MetaRow(icon: Icons.place_outlined, text: incident.location),
                        _MetaRow(icon: Icons.schedule_rounded, text: TimeFormat.full(incident.createdAt)),
                        _MetaRow(icon: Icons.person_outline_rounded, text: 'Reported by $reporter'),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: StatusTrack(status: incident.status),
                        ),
                        const SizedBox(height: 24),
                        Text('Details', style: context.text.titleLarge),
                        const SizedBox(height: 8),
                        Text(incident.description, style: context.text.bodyLarge),
                        const SizedBox(height: 26),
                        Text('Updates', style: context.text.titleLarge),
                        const SizedBox(height: 14),
                        StatusHistory(entries: incident.timeline),
                      ],
                    ),
                  ).animate().fadeIn(duration: 320.ms),
                ),
              ],
            ),
          ),
          if (isStaff || canMarkAffected)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (canMarkAffected)
                      PillButton(
                        label: affected
                            ? 'You are affected · ${incident.affectedBy.length}'
                            : 'This affects me too · ${incident.affectedBy.length}',
                        icon: affected ? Icons.check_rounded : Icons.front_hand_outlined,
                        style: affected ? PillStyle.signal : PillStyle.outline,
                        compact: isStaff,
                        onPressed: () => _toggleAffected(context, ref, !affected),
                      ),
                    if (isStaff && canMarkAffected) const SizedBox(height: 8),
                    if (isStaff)
                      PillButton(
                        label: 'Update status',
                        icon: Icons.sync_alt_rounded,
                        onPressed: () => showStatusSheet(context, incident),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.palette.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}
