import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profile)),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return Center(child: Text(context.l10n.notSignedIn));
          }
          final u = state.user;
          final bool adminArea =
              u.role == 'admin' || u.role == 'super_admin';
          final l10n = context.l10n;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.tertiaryFixed.withValues(alpha: 0.4),
                child: Text(
                  u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 32, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              _row(l10n.name, u.fullName),
              _row(l10n.emailLabel, u.email),
              if (!adminArea) ...<Widget>[
                _row(l10n.role, u.role),
                if (u.phone != null) _row(l10n.phone, u.phone!),
                _row(
                  l10n.statusLabel,
                  u.isActive ? l10n.active : l10n.inactive,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              k,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
