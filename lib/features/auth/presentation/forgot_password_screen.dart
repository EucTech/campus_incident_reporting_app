import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/state_views.dart';
import '../application/auth_providers.dart';
import 'auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final done = await ref.read(authControllerProvider.notifier).sendPasswordReset(_email.text);
    if (!mounted) return;
    showMessage(
      context,
      done ? 'Check your inbox for a reset link.' : friendlyError(ref.read(authControllerProvider).error!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Reset\npassword.',
      subtitle: 'We will email you a link to choose a new one.',
      children: [
        Form(
          key: _formKey,
          child: LabeledField(
            label: 'ALU email',
            controller: _email,
            hint: 'you@alustudent.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: 26),
        PillButton(label: 'Send reset link', loading: ref.watch(authControllerProvider).isLoading, onPressed: _submit),
      ],
    );
  }
}
