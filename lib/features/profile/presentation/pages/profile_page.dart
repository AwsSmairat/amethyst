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
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: Text('Not signed in'));
          }
          final u = state.user;
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
              _row('Name', u.fullName),
              _row('Email', u.email),
              _row('Role', u.role),
              if (u.phone != null) _row('Phone', u.phone!),
              _row('Status', u.isActive ? 'Active' : 'Inactive'),
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
