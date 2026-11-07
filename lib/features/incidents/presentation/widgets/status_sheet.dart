import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/failure.dart';
import '../../../../core/widgets/labeled_field.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../application/incident_providers.dart';
import '../../domain/incident.dart';
import '../../domain/incident_enums.dart';
import 'filter_pill.dart';

Future<void> showStatusSheet(BuildContext context, Incident incident) => showModalBottomSheet<void>(
  useRootNavigator: true,
  context: context,
  isScrollControlled: true,
  builder: (_) => _StatusSheet(incident: incident),
);

class _StatusSheet extends ConsumerStatefulWidget {
  const _StatusSheet({required this.incident});

  final Incident incident;

  @override
  ConsumerState<_StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends ConsumerState<_StatusSheet> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  late IncidentStatus _status = widget.incident.status.nextOptions.first;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _needsNote => _status == IncidentStatus.dismissed;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(incidentControllerProvider.notifier);
    final done = await controller.changeStatus(widget.incident, _status, _note.text);
    if (!mounted) return;
    if (done) {
      Navigator.pop(context);
      showMessage(context, 'Status changed to ${_status.label}.');
    } else {
      showMessage(context, friendlyError(ref.read(incidentControllerProvider).error!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + MediaQuery.viewPaddingOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Update status', style: context.text.titleLarge),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in widget.incident.status.nextOptions)
                  FilterPill(
                    label: status.label,
                    selected: _status == status,
                    onTap: () => setState(() => _status = status),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            LabeledField(
              label: _needsNote ? 'Reason for dismissing' : 'Note for the reporter (optional)',
              controller: _note,
              hint: 'What is happening next?',
              maxLines: 3,
              maxLength: 300,
              capitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              validator: (value) => _needsNote && (value?.trim().isEmpty ?? true) ? 'Tell the reporter why' : null,
            ),
            const SizedBox(height: 18),
            PillButton(
              label: 'Save update',
              loading: ref.watch(incidentControllerProvider).isLoading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
