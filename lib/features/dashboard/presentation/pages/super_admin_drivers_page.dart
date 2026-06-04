import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_users_cubit.dart';
import 'package:amethyst/features/dashboard/presentation/widgets/add_super_admin_user_sheet.dart';
import 'package:amethyst/features/dashboard/presentation/widgets/edit_super_admin_user_sheet.dart';
import 'package:amethyst/features/dashboard/presentation/widgets/user_list_actions_row.dart';
import 'package:amethyst/core/users/super_admin_users_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SuperAdminDriversPage extends StatelessWidget {
  const SuperAdminDriversPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SuperAdminUsersCubit(
        sl<SuperAdminUsersPort>(),
        roleFilter: 'driver',
      )..load(),
      child: const _SuperAdminDriversBody(),
    );
  }
}

class _SuperAdminDriversBody extends StatelessWidget {
  const _SuperAdminDriversBody();

  String? _selfId(BuildContext context) {
    final AuthState state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated) {
      return state.user.id;
    }
    return null;
  }

  Future<void> _toggleActive(
    BuildContext context,
    SuperAdminUsersCubit cubit,
    Map<String, dynamic> user,
  ) async {
    final l10n = context.l10n;
    final String? id = user['id']?.toString();
    if (id == null) {
      return;
    }
    final bool isActive = user['isActive'] == true;
    final String? err = await cubit.setUserActive(uid: id, isActive: !isActive);
    if (!context.mounted) {
      return;
    }
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isActive ? l10n.userDeactivated : l10n.userActivated),
      ),
    );
  }

  Future<void> _sendPasswordReset(
    BuildContext context,
    SuperAdminUsersCubit cubit,
    Map<String, dynamic> user,
  ) async {
    final l10n = context.l10n;
    final String? email = user['email']?.toString();
    if (email == null || email.isEmpty) {
      return;
    }
    final String? err = await cubit.sendPasswordReset(email: email);
    if (!context.mounted) {
      return;
    }
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.passwordResetSent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleDrivers),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.retry,
            onPressed: () => context.read<SuperAdminUsersCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddSuperAdminUserSheet(
          context,
          fixedRole: 'driver',
        ),
        icon: const Icon(Icons.person_add_outlined),
        label: Text(l10n.addDriver),
      ),
      body: BlocBuilder<SuperAdminUsersCubit, ListLoadState>(
        builder: (BuildContext context, ListLoadState state) {
          if (state is ListLoadLoading || state is ListLoadInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ListLoadFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          context.read<SuperAdminUsersCubit>().load(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          final items = (state as ListLoadLoaded).items;
          if (items.isEmpty) {
            return Center(child: Text(l10n.nothingHereYet));
          }
          final String? selfId = _selfId(context);
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int i) {
              final Map<String, dynamic> u = items[i];
              final String id = u['id']?.toString() ?? '';
              final String title =
                  u['fullName']?.toString() ?? u['email']?.toString() ?? '';
              final bool isActive = u['isActive'] == true;
              final String status = isActive ? l10n.active : l10n.inactive;
              final String sub = '${u['email'] ?? ''}\n$status';
              final bool isSelf = selfId != null && id == selfId;
              final SuperAdminUsersCubit cubit =
                  context.read<SuperAdminUsersCubit>();
              return ListTile(
                contentPadding: const EdgeInsetsDirectional.only(
                  start: 8,
                  end: 12,
                ),
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sub,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    UserListActionsRow(
                      onEdit: () => showEditSuperAdminUserSheet(context, u),
                      onResetPassword: () =>
                          _sendPasswordReset(context, cubit, u),
                      onToggleActive: isSelf
                          ? null
                          : () => _toggleActive(context, cubit, u),
                      isActive: isActive,
                      editTooltip: l10n.editUser,
                      resetTooltip: l10n.resetPassword,
                      toggleTooltip:
                          isActive ? l10n.deactivateUser : l10n.activateUser,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
