import 'dart:async';

import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:amethyst/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverNotesPage extends StatefulWidget {
  const DriverNotesPage({super.key});

  @override
  State<DriverNotesPage> createState() => _DriverNotesPageState();
}

class _DriverNotesPageState extends State<DriverNotesPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _ready = false;

  String _storageKey(BuildContext context) {
    final AuthState auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated) {
      return 'amethyst_driver_notes_${auth.user.id}';
    }
    return 'amethyst_driver_notes';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotes());
  }

  Future<void> _loadNotes() async {
    if (!mounted) return;
    final String key = _storageKey(context);
    final SharedPreferences p = await SharedPreferences.getInstance();
    final String text = p.getString(key) ?? '';
    if (!mounted) return;
    _controller.text = text;
    _controller.addListener(_scheduleSave);
    setState(() => _ready = true);
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _saveNotes);
  }

  Future<void> _saveNotes() async {
    if (!mounted) return;
    final String key = _storageKey(context);
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.setString(key, _controller.text);
  }

  Future<void> _reloadFromStorage() async {
    if (!mounted) return;
    final String key = _storageKey(context);
    final SharedPreferences p = await SharedPreferences.getInstance();
    final String text = p.getString(key) ?? '';
    if (!mounted) return;
    _controller.removeListener(_scheduleSave);
    _controller.text = text;
    _controller.addListener(_scheduleSave);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_scheduleSave);
    _saveNotes();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.driverNotesTitle),
        actions: <Widget>[
          IconButton(
            onPressed: _ready ? _reloadFromStorage : null,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                minLines: 16,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  alignLabelWithHint: true,
                  hintText: l10n.driverNotesFieldHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
            ),
    );
  }
}
