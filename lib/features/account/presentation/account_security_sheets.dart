import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/application/auth_providers.dart';

Future<void> showChangePasswordSheet(BuildContext context) => showModalBottomSheet<void>(
  useRootNavigator: true,
  context: context,
  isScrollControlled: true,
  builder: (_) => const _ChangePasswordSheet(),
);

Future<void> showDeleteAccountSheet(BuildContext context) => showModalBottomSheet<void>(
  useRootNavigator: true,
  context: context,
  isScrollControlled: true,
  builder: (_) => const _DeleteAccountSheet(),
);

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.formKey, required this.title, required this.subtitle, required this.children});

  final GlobalKey<FormState> formKey;
  final String title;
  final String subtitle;
  final List<Widget> children;

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
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: context.text.titleLarge),
            const SizedBox(height: 4),
            Text(subtitle, style: context.text.bodyMedium),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final done = await ref.read(authControllerProvider.notifier).changePassword(_current.text, _next.text);
    if (!mounted) return;
    if (done) {
      Navigator.pop(context);
      showMessage(context, 'Password changed.');
    } else {
      showMessage(context, friendlyError(ref.read(authControllerProvider).error!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      formKey: _formKey,
      title: 'Change password',
      subtitle: 'Enter your current password to confirm it is you.',
      children: [
        LabeledField(
          label: 'Current password',
          controller: _current,
          obscure: true,
          autofillHints: const [AutofillHints.password],
          validator: Validators.requiredPassword,
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'New password',
          controller: _next,
          hint: 'At least 8 characters and a number',
          obscure: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          validator: Validators.password,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 18),
        PillButton(label: 'Update password', loading: ref.watch(authControllerProvider).isLoading, onPressed: _submit),
      ],
    );
  }
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  @override
  ConsumerState<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final done = await ref.read(authControllerProvider.notifier).deleteAccount(_password.text);
    if (!mounted) return;
    if (done) {
      Navigator.pop(context);
    } else {
      showMessage(context, friendlyError(ref.read(authControllerProvider).error!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      formKey: _formKey,
      title: 'Delete your account?',
      subtitle:
          'You will lose access to Pulse straight away. Reports you sent stay on record so staff can finish them.',
      children: [
        LabeledField(
          label: 'Current password',
          controller: _password,
          obscure: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          validator: Validators.requiredPassword,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 18),
        PillButton(
          label: 'Delete my account',
          style: PillStyle.danger,
          loading: ref.watch(authControllerProvider).isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
