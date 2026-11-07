import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/state_views.dart';
import '../application/auth_providers.dart';
import 'auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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
    final done = await controller.signIn(_email.text, _password.text);
    final controllerError = done ? '' : controller.lastError;
    if (!done) showAppMessage(friendlyError(controllerError));
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    return AuthScaffold(
      title: 'Welcome\nback.',
      subtitle: 'Log in with your ALU email.',
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                LabeledField(
                  label: 'ALU email',
                  controller: _email,
                  hint: 'you@alustudent.com',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: 18),
                LabeledField(
                  label: 'Password',
                  controller: _password,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: Validators.requiredPassword,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Pressable(
            onTap: () => context.push('/forgot'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('Forgot password?', style: context.text.labelMedium),
            ),
          ),
        ),
        const SizedBox(height: 18),
        PillButton(label: 'Log in', loading: loading, onPressed: _submit),
        const SizedBox(height: 14),
        Pressable(
          onTap: () => context.pushReplacement('/register'),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'New here? Create an account',
              textAlign: TextAlign.center,
              style: context.text.labelMedium?.copyWith(color: context.palette.muted),
            ),
          ),
        ),
      ],
    );
  }
}
