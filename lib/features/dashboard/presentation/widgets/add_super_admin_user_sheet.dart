import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_users_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// When [fixedRole] is `admin` or `driver`, the role dropdown is hidden.
Future<void> showAddSuperAdminUserSheet(
  BuildContext context, {
  String? fixedRole,
}) {
  final SuperAdminUsersCubit cubit = context.read<SuperAdminUsersCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => BlocProvider.value(
      value: cubit,
      child: _AddUserBody(fixedRole: fixedRole),
    ),
  );
}

class _AddUserBody extends StatefulWidget {
  const _AddUserBody({this.fixedRole});

  /// Locks creation to this role (`admin` or `driver`).
  final String? fixedRole;

  @override
  State<_AddUserBody> createState() => _AddUserBodyState();
}

class _AddUserBodyState extends State<_AddUserBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  late String _role;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _role = widget.fixedRole ?? 'admin';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    final String? err = await context.read<SuperAdminUsersCubit>().createUser(
          fullName: _fullName.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          role: _role,
        );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.userCreated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final double bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottom + 24,
        top: 8,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                widget.fixedRole == 'driver' ? l10n.addDriver : l10n.addUser,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullName,
                textAlign: TextAlign.right,
                decoration: InputDecoration(labelText: l10n.newUserFullName),
                validator: (String? v) =>
                    v == null || v.trim().length < 2 ? ' ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.newUserEmail),
                validator: (String? v) {
                  if (v == null || v.trim().isEmpty) {
                    return ' ';
                  }
                  if (!v.contains('@')) {
                    return ' ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                textAlign: TextAlign.right,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.newUserPassword),
                validator: (String? v) =>
                    v == null || v.length < 8 ? ' ' : null,
              ),
              if (widget.fixedRole == null) ...<Widget>[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: InputDecoration(labelText: l10n.userRoleLabel),
                  items: <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(
                      value: 'admin',
                      child: Text(l10n.userRoleAdminOption),
                    ),
                    DropdownMenuItem<String>(
                      value: 'driver',
                      child: Text(l10n.userRoleDriverOption),
                    ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (String? v) {
                          if (v != null) {
                            setState(() => _role = v);
                          }
                        },
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
