import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_scaffold.dart';
import '../application/school_providers.dart';

class RegisterSchoolScreen extends ConsumerStatefulWidget {
  const RegisterSchoolScreen({super.key});

  @override
  ConsumerState<RegisterSchoolScreen> createState() => _RegisterSchoolScreenState();
}

class _RegisterSchoolScreenState extends ConsumerState<RegisterSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolName = TextEditingController();
  final _domain = TextEditingController();
  final _adminName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    for (final controller in [_schoolName, _domain, _adminName, _email, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final done = await controller.registerSchool(
      adminName: _adminName.text,
      email: _email.text,
      password: _password.text,
      schoolName: _schoolName.text,
      domain: _domain.text,
    );
    if (!done) showAppMessage(friendlyError(controller.lastError));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AuthScaffold(
      title: 'Bring your\nschool.',
      subtitle: 'You become the school admin. Students join with their school email and you invite your staff.',
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('School', style: context.text.titleLarge),
                const SizedBox(height: 14),
                LabeledField(
                  label: 'School name',
                  controller: _schoolName,
                  hint: 'Your school name',
                  capitalization: TextCapitalization.words,
                  validator: Validators.schoolName,
                ),
                const SizedBox(height: 18),
                LabeledField(
                  label: 'Student email domain',
                  controller: _domain,
                  hint: 'students.school.com',
                  keyboardType: TextInputType.url,
                  validator: Validators.studentDomain,
                ),
                const SizedBox(height: 6),
                Text(
                  'Students with emails ending in this domain join your school automatically.',
                  style: context.text.bodyMedium?.copyWith(color: p.muted),
                ),
                const SizedBox(height: 28),
                Text('Your admin account', style: context.text.titleLarge),
                const SizedBox(height: 14),
                LabeledField(
                  label: 'Your name',
                  controller: _adminName,
                  capitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.name,
                ),
                const SizedBox(height: 18),
                LabeledField(
                  label: 'Your email',
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
        PillButton(
          label: 'Register school',
          style: PillStyle.signal,
          loading: ref.watch(onboardingControllerProvider).isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
