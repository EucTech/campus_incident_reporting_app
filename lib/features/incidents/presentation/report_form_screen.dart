import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/pulse_rings.dart';
import '../../../core/widgets/state_views.dart';
import '../application/incident_providers.dart';
import '../domain/incident.dart';
import '../domain/incident_enums.dart';
import '../domain/incident_filter.dart';
import 'widgets/category_visuals.dart';
import 'widgets/filter_pill.dart';

class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key, this.existing});

  final Incident? existing;

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  static const _places = ['Library', 'Cafeteria', 'Residence', 'Lab', 'Main hall', 'Sports field'];
  static const _stepTitles = ['What kind of\nissue is it?', 'Tell us what\nhappened.', 'Add a photo\nand send.'];

  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _description = TextEditingController(text: widget.existing?.description);
  late final _location = TextEditingController(text: widget.existing?.location);

  late IncidentCategory? _category = widget.existing?.category;
  late IncidentSeverity _severity = widget.existing?.severity ?? IncidentSeverity.medium;
  late String? _existingImage = widget.existing?.imageUrl;
  File? _photo;
  bool _anonymous = false;
  int _step = 0;
  String? _sentId;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  void _continue() {
    if (_step == 1 && !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _step++);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 72, maxWidth: 1600);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _send() async {
    final controller = ref.read(incidentControllerProvider.notifier);
    final draft = IncidentDraft(
      title: _title.text,
      description: _description.text,
      location: _location.text,
      category: _category!,
      severity: _severity,
      anonymous: _anonymous,
    );

    if (_isEditing) {
      final removePhoto = widget.existing!.imageUrl != null && _existingImage == null;
      final done = await controller.edit(widget.existing!, draft, _photo, removePhoto: removePhoto);
      if (!mounted) return;
      if (done) {
        context.pop();
        showMessage(context, 'Report updated.');
      } else {
        showMessage(context, friendlyError(ref.read(incidentControllerProvider).error!));
      }
      return;
    }

    final id = await controller.submit(draft, _photo);
    if (!mounted) return;
    if (id != null) {
      setState(() => _sentId = id);
    } else {
      showMessage(context, friendlyError(ref.read(incidentControllerProvider).error!));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sentId != null) return _SentView(incidentId: _sentId!);

    final p = context.palette;
    final sending = ref.watch(incidentControllerProvider).isLoading;
    final isLast = _step == _stepTitles.length - 1;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    RoundIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: _goBack),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: (_step + 1) / _stepTitles.length),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => LinearProgressIndicator(
                            value: value,
                            minHeight: 5,
                            backgroundColor: p.raised,
                            color: p.signal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text('${_step + 1}/${_stepTitles.length}', style: context.text.labelMedium),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    layoutBuilder: (current, previous) =>
                        Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                        child: child,
                      ),
                    ),
                    child: SingleChildScrollView(
                      key: ValueKey(_step),
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(_stepTitles[_step], style: context.text.displayMedium),
                          const SizedBox(height: 24),
                          switch (_step) {
                            0 => _categoryStep(),
                            1 => _detailsStep(),
                            _ => _photoStep(),
                          },
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: PillButton(
                  label: isLast ? (_isEditing ? 'Save changes' : 'Send report') : 'Continue',
                  style: isLast ? PillStyle.signal : PillStyle.solid,
                  loading: sending,
                  onPressed: _category == null ? null : (isLast ? _send : _continue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryStep() {
    final p = context.palette;
    return Column(
      children: [
        for (final category in IncidentCategory.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Pressable(
              onTap: () => setState(() => _category = category),
              semanticLabel: category.label,
              scale: 0.98,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _category == category ? p.ink : p.surface,
                  borderRadius: BorderRadius.circular(AppRadius.tile + 4),
                ),
                child: Row(
                  children: [
                    Icon(category.icon, color: _category == category ? p.canvas : p.ink),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.label,
                            style: context.text.titleMedium?.copyWith(color: _category == category ? p.canvas : p.ink),
                          ),
                          Text(
                            category.hint,
                            style: context.text.bodyMedium?.copyWith(
                              color: _category == category ? p.canvas.withValues(alpha: 0.7) : p.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _detailsStep() {
    final similar = _isEditing
        ? const <Incident>[]
        : similarOpenIncidents(ref.watch(incidentsProvider).value ?? const [], _category!, _location.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LabeledField(
          label: 'Title',
          controller: _title,
          hint: 'No water on the second floor',
          maxLength: 80,
          capitalization: TextCapitalization.sentences,
          validator: Validators.title,
        ),
        const SizedBox(height: 18),
        LabeledField(
          label: 'What happened?',
          controller: _description,
          hint: 'When did it start and who is affected?',
          maxLines: 4,
          maxLength: 1000,
          capitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.newline,
          validator: Validators.description,
        ),
        const SizedBox(height: 18),
        LabeledField(
          label: 'Where?',
          controller: _location,
          hint: 'Block B, Room 204',
          maxLength: 80,
          capitalization: TextCapitalization.sentences,
          validator: Validators.location,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final place in _places)
              FilterPill(
                label: place,
                selected: _location.text == place,
                onTap: () => setState(() => _location.text = place),
              ),
          ],
        ),
        if (similar.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SimilarNotice(incident: similar.first, count: similar.length),
        ],
        const SizedBox(height: 20),
        Text('How urgent is it?', style: context.text.labelMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final severity in IncidentSeverity.values) ...[
              FilterPill(
                label: severity.label,
                selected: _severity == severity,
                onTap: () => setState(() => _severity = severity),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  Widget _photoStep() {
    final p = context.palette;
    final hasPhoto = _photo != null || _existingImage != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: hasPhoto
              ? ClipRRect(
                  key: const ValueKey('photo'),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: _photo != null
                            ? Image.file(_photo!, fit: BoxFit.cover)
                            : CachedNetworkImage(imageUrl: _existingImage!, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: RoundIconButton(
                          icon: Icons.close_rounded,
                          label: 'Remove photo',
                          onTap: () => setState(() {
                            _photo = null;
                            _existingImage = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  key: const ValueKey('picker'),
                  children: [
                    Expanded(
                      child: _PhotoSource(
                        icon: Icons.photo_camera_outlined,
                        label: 'Camera',
                        onTap: () => _pickPhoto(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PhotoSource(
                        icon: Icons.image_outlined,
                        label: 'Gallery',
                        onTap: () => _pickPhoto(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        Text('Optional. A photo helps staff find the issue faster.', style: context.text.bodyMedium),
        const SizedBox(height: 20),
        if (!_isEditing)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(AppRadius.tile + 4)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hide my name', style: context.text.titleMedium),
                      Text('Your name will not be shown on this report.', style: context.text.bodyMedium),
                    ],
                  ),
                ),
                Switch(
                  value: _anonymous,
                  activeThumbColor: p.signalInk,
                  activeTrackColor: p.signal,
                  onChanged: (value) => setState(() => _anonymous = value),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PhotoSource extends StatelessWidget {
  const _PhotoSource({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 130,
        decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: p.ink),
            const SizedBox(height: 8),
            Text(label, style: context.text.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _SimilarNotice extends StatelessWidget {
  const _SimilarNotice({required this.incident, required this.count});

  final Incident incident;
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: () => context.push('/incident/${incident.id}'),
      semanticLabel: 'View similar report',
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 20, color: p.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                count == 1
                    ? 'This may already be reported: ${incident.title}. Tap to view it and mark yourself affected.'
                    : '$count similar reports are open here. Tap to view one and mark yourself affected.',
                style: context.text.labelMedium?.copyWith(color: p.ink, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.15);
  }
}

class _SentView extends StatelessWidget {
  const _SentView({required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: PulseRings(
                  size: 240,
                  color: p.signalText,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: p.signal, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, size: 36, color: p.signalInk),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                ),
              ),
              const SizedBox(height: 24),
              Text('Report sent.', textAlign: TextAlign.center, style: context.text.displayMedium),
              const SizedBox(height: 10),
              Text(
                'Campus staff can see it now. You will find every update on the report.',
                textAlign: TextAlign.center,
                style: context.text.bodyLarge?.copyWith(color: p.muted),
              ),
              const Spacer(),
              PillButton(label: 'View report', onPressed: () => context.pushReplacement('/incident/$incidentId')),
              const SizedBox(height: 10),
              PillButton(label: 'Done', style: PillStyle.outline, onPressed: () => context.pop()),
            ],
          ),
        ),
      ),
    );
  }
}
