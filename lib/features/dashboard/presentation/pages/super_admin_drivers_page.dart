import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_users_cubit.dart';
import 'package:amethyst/features/dashboard/presentation/widgets/add_super_admin_user_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Lists users with role `driver` and allows adding drivers (same API as users).
class SuperAdminDriversPage extends StatelessWidget {
  const SuperAdminDriversPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SuperAdminUsersCubit(sl<AmethystApi>())..load(),
      child: const _SuperAdminDriversBody(),
    );
  }
}

class _SuperAdminDriversBody extends StatelessWidget {
  const _SuperAdminDriversBody();

  Future<void> _confirmDelete(
    BuildContext context,
    SuperAdminUsersCubit cubit,
    Map<String, dynamic> user,
  ) async {
    final l10n = context.l10n;
    final String? id = user['id']?.toString();
    final String name = user['fullName']?.toString() ?? id ?? '';
    if (id == null) {
      return;
    }
    final String? selfId = context.read<AuthCubit>().state is AuthAuthenticated
        ? (context.read<AuthCubit>().state as AuthAuthenticated).user.id
        : null;
    if (selfId != null && id == selfId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cannotDeleteSelf)),
      );
      return;
    }
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l10n.deleteUserConfirmTitle),
        content: Text(l10n.deleteUserConfirmBody(name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteUser),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) {
      return;
    }
    final String? err = await cubit.deleteUser(id);
    if (!context.mounted) {
      return;
    }
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userDeleted)),
      );
    }
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
          final all = (state as ListLoadLoaded).items;
          final items = all
              .where((Map<String, dynamic> u) => u['role'] == 'driver')
              .toList(growable: false);
          if (items.isEmpty) {
            return Center(child: Text(l10n.nothingHereYet));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int i) {
              final Map<String, dynamic> u = items[i];
              final String title =
                  u['fullName']?.toString() ?? u['email']?.toString() ?? '';
              final String status =
                  u['isActive'] == true ? l10n.active : l10n.inactive;
              final String sub = '${u['email'] ?? ''}\n$status';
              return ListTile(
                title: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  sub,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                trailing: IconButton(
                  tooltip: l10n.deleteUser,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _confirmDelete(
                    context,
                    context.read<SuperAdminUsersCubit>(),
                    u,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
