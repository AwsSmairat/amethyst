import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_users_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showEditSuperAdminUserSheet(
  BuildContext context,
  Map<String, dynamic> user,
) {
  final SuperAdminUsersCubit cubit = context.read<SuperAdminUsersCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => BlocProvider.value(
      value: cubit,
      child: _EditUserBody(user: user),
    ),
  );
}

class _EditUserBody extends StatefulWidget {
  const _EditUserBody({required this.user});

  final Map<String, dynamic> user;

  @override
  State<_EditUserBody> createState() => _EditUserBodyState();
}

class _EditUserBodyState extends State<_EditUserBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late String _role;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.user['fullName']?.toString() ?? '');
    _phone = TextEditingController(text: widget.user['phone']?.toString() ?? '');
    _role = widget.user['role']?.toString() ?? 'admin';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final String? id = widget.user['id']?.toString();
    if (id == null) {
      return;
    }
    setState(() => _submitting = true);
    final String? err = await context.read<SuperAdminUsersCubit>().updateUser(
          uid: id,
          fullName: _fullName.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
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
      SnackBar(content: Text(context.l10n.userUpdated)),
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
                l10n.editUser,
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
                    v == null || v.trim().length < 2 ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.newUserPhone),
              ),
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
