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
import '../../schools/application/school_providers.dart';
import 'auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final done = await controller.registerMember(name: _name.text, email: _email.text, password: _password.text);
    if (!done) showAppMessage(friendlyError(controller.lastError));
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(onboardingControllerProvider).isLoading;
    return AuthScaffold(
      title: 'Join\nPulse.',
      subtitle: 'Students use their school email. Staff use the email their school admin invited.',
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                LabeledField(
                  label: 'Full name',
                  controller: _name,
                  hint: 'Your name',
                  capitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.name,
                ),
                const SizedBox(height: 18),
                LabeledField(
                  label: 'Email',
                  controller: _email,
                  hint: 'you@school.com',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: 18),
                LabeledField(
                  label: 'Password',
                  controller: _password,
                  hint: 'At least 8 characters and a number',
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        PillButton(label: 'Create account', loading: loading, onPressed: _submit),
        const SizedBox(height: 14),
        Pressable(
          onTap: () => context.pushReplacement('/login'),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Already have an account? Log in',
              textAlign: TextAlign.center,
              style: context.text.labelMedium?.copyWith(color: context.palette.muted),
            ),
          ),
        ),
      ],
    );
  }
}
