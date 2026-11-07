import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/domain/app_user.dart';
import '../application/school_providers.dart';
import '../domain/school.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  TeamController get _controller => ref.read(teamControllerProvider.notifier);

  Future<void> _share(String email) async {
    final school = ref.read(currentSchoolProvider).value;
    await SharePlus.instance.share(
      ShareParams(
        text: inviteMessage(schoolName: school?.name ?? 'your school', email: email),
      ),
    );
  }

  Future<void> _invite() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim().toLowerCase();
    if (!await _controller.invite(email)) {
      showAppMessage(friendlyError(_controller.lastError));
      return;
    }
    if (!mounted) return;
    _formKey.currentState!.reset();
    _email.clear();
    FocusScope.of(context).unfocus();
    showAppMessage('Invite saved. Send it so they know to sign up.');
    await _share(email);
  }

  Future<void> _confirm({required String title, required String body, required Future<bool> Function() action}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, style: dialogContext.text.titleLarge),
        content: Text(body, style: dialogContext.text.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true && !await action()) showAppMessage(friendlyError(_controller.lastError));
  }

  @override
  Widget build(BuildContext context) {
    final invites = ref.watch(pendingInvitesProvider);
    final team = ref.watch(teamProvider);
    final school = ref.watch(currentSchoolProvider).value;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: RoundIconButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => context.pop()),
            ),
            const SizedBox(height: 24),
            Text('Your team', style: context.text.displayMedium),
            const SizedBox(height: 6),
            Text(
              'Only people you invite can review and resolve reports at ${school?.name ?? 'your school'}.',
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: LabeledField(
                label: 'Invite staff by email',
                controller: _email,
                hint: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: Validators.email,
                onSubmitted: (_) => _invite(),
              ),
            ),
            const SizedBox(height: 12),
            PillButton(
              label: 'Invite staff',
              icon: Icons.person_add_alt_1_outlined,
              loading: ref.watch(teamControllerProvider).isLoading,
              onPressed: _invite,
            ),
            const SizedBox(height: 30),
            Text('Waiting to join', style: context.text.titleLarge),
            const SizedBox(height: 12),
            invites.when(
              loading: () => const SkeletonList(count: 1, height: 72),
              error: (error, _) =>
                  ErrorView(message: friendlyError(error), onRetry: () => ref.invalidate(pendingInvitesProvider)),
              data: (items) => items.isEmpty
                  ? Text('No pending invites.', style: context.text.bodyMedium)
                  : Column(
                      children: [
                        for (final invite in items)
                          _InviteRow(
                            invite: invite,
                            onShare: () => _share(invite.email),
                            onCancel: () => _confirm(
                              title: 'Cancel this invite?',
                              body: '${invite.email} will no longer be able to join as staff.',
                              action: () => _controller.cancelInvite(invite.email),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 30),
            Text('Staff', style: context.text.titleLarge),
            const SizedBox(height: 12),
            team.when(
              loading: () => const SkeletonList(count: 2, height: 72),
              error: (error, _) =>
                  ErrorView(message: friendlyError(error), onRetry: () => ref.invalidate(teamProvider)),
              data: (members) => Column(
                children: [
                  for (final member in members)
                    _MemberRow(
                      member: member,
                      onRemove: member.role == UserRole.staff
                          ? () => _confirm(
                              title: 'Remove ${member.firstName}?',
                              body: 'They will lose access to ${school?.name ?? 'your school'} straight away.',
                              action: () => _controller.removeStaff(member),
                            )
                          : null,
                    ),
                ],
              ),
            ),
          ].animate(interval: 40.ms).fadeIn(duration: 280.ms),
        ),
      ),
    );
  }
}

class _RowShell extends StatelessWidget {
  const _RowShell({required this.leading, required this.title, required this.subtitle, required this.actions});

  final Widget leading;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile + 4),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodyMedium),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({required this.invite, required this.onShare, required this.onCancel});

  final StaffInvite invite;
  final VoidCallback onShare;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _RowShell(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: p.raised,
        child: Icon(Icons.mail_outline_rounded, size: 20, color: p.ink),
      ),
      title: invite.email,
      subtitle: 'Invited ${TimeFormat.relative(invite.invitedAt)}',
      actions: [
        IconButton(
          tooltip: 'Share invite',
          onPressed: onShare,
          icon: Icon(Icons.ios_share_rounded, color: p.ink),
        ),
        IconButton(
          tooltip: 'Cancel invite',
          onPressed: onCancel,
          icon: Icon(Icons.close_rounded, color: p.danger),
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.onRemove});

  final AppUser member;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _RowShell(
      leading: UserAvatar(user: member, size: 44),
      title: member.name,
      subtitle: '${member.role.label} · ${member.email}',
      actions: [
        if (onRemove != null)
          IconButton(
            tooltip: 'Remove from team',
            onPressed: onRemove,
            icon: Icon(Icons.person_remove_outlined, color: p.danger),
          ),
      ],
    );
  }
}
