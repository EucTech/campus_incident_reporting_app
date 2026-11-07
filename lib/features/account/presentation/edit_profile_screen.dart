import 'dart:io';

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
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/application/auth_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: ref.read(profileProvider).value?.name);
  File? _photo;
  bool _removePhoto = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    Navigator.pop(context);
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 72, maxWidth: 800);
    if (picked != null) {
      setState(() {
        _photo = File(picked.path);
        _removePhoto = false;
      });
    }
  }

  Future<void> _showPhotoOptions(bool hasPhoto) => showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PillButton(
              label: 'Take a photo',
              icon: Icons.photo_camera_outlined,
              onPressed: () => _pick(ImageSource.camera),
            ),
            const SizedBox(height: 8),
            PillButton(
              label: 'Choose from gallery',
              icon: Icons.image_outlined,
              style: PillStyle.outline,
              onPressed: () => _pick(ImageSource.gallery),
            ),
            if (hasPhoto) ...[
              const SizedBox(height: 8),
              PillButton(
                label: 'Remove photo',
                icon: Icons.delete_outline_rounded,
                style: PillStyle.outline,
                onPressed: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _photo = null;
                    _removePhoto = true;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    final done = await controller.updateProfile(name: _name.text, photo: _photo, removePhoto: _removePhoto);
    if (!mounted) return;
    if (done) {
      context.pop();
      showMessage(context, 'Profile updated.');
    } else {
      showMessage(context, friendlyError(ref.read(authControllerProvider).error!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final profile = ref.watch(profileProvider).value;
    final previewUser = _removePhoto ? profile?.withoutPhoto() : profile;
    final hasPhoto = _photo != null || previewUser?.photoUrl != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: RoundIconButton(
                          icon: Icons.arrow_back_rounded,
                          label: 'Back',
                          onTap: () => context.pop(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Your profile', style: context.text.displayMedium),
                      const SizedBox(height: 24),
                      Center(
                        child: Pressable(
                          onTap: () => _showPhotoOptions(hasPhoto),
                          semanticLabel: 'Change photo',
                          child: Stack(
                            children: [
                              _photo != null
                                  ? CircleAvatar(radius: 56, backgroundImage: FileImage(_photo!))
                                  : UserAvatar(user: previewUser, size: 112),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: p.ink,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: p.canvas, width: 3),
                                  ),
                                  child: Icon(Icons.edit_rounded, size: 15, color: p.canvas),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().scale(begin: const Offset(0.9, 0.9), duration: 350.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 26),
                      LabeledField(
                        label: 'Full name',
                        controller: _name,
                        capitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.name],
                        validator: Validators.name,
                      ),
                      const SizedBox(height: 18),
                      Text('Email', style: context.text.labelMedium),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(AppRadius.tile),
                          border: Border.all(color: p.line),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                profile?.email ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.bodyLarge,
                              ),
                            ),
                            const SizedBox(width: 8),
                            PillButton(
                              label: 'Change',
                              style: PillStyle.outline,
                              compact: true,
                              onPressed: () => showModalBottomSheet<void>(
                                useRootNavigator: true,
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => const _ChangeEmailSheet(),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PillButton(
                label: 'Save changes',
                loading: ref.watch(authControllerProvider).isLoading,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeEmailSheet extends ConsumerStatefulWidget {
  const _ChangeEmailSheet();

  @override
  ConsumerState<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends ConsumerState<_ChangeEmailSheet> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    final done = await controller.requestEmailChange(_email.text, _password.text);
    if (!mounted) return;
    if (done) {
      Navigator.pop(context);
      showMessage(context, 'Open the link sent to your new email, then log in again.');
    } else {
      showMessage(context, friendlyError(ref.read(authControllerProvider).error!));
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
            Text('Change your email', style: context.text.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Your email only changes after you open the link we send to the new address.',
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: 16),
            LabeledField(
              label: 'New email',
              controller: _email,
              hint: 'you@school.com',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Current password',
              controller: _password,
              obscure: true,
              textInputAction: TextInputAction.done,
              validator: Validators.requiredPassword,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18),
            PillButton(
              label: 'Send verification link',
              loading: ref.watch(authControllerProvider).isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
