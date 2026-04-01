import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/di/injection.dart';
import 'package:flutter/material.dart';

class DriverNotesPage extends StatefulWidget {
  const DriverNotesPage({super.key});

  @override
  State<DriverNotesPage> createState() => _DriverNotesPageState();
}

class _DriverNotesPageState extends State<DriverNotesPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _dash;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await sl<AmethystApi>().getDashboardDriver();
      if (!mounted) return;
      setState(() {
        _dash = d;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notesAndSummary),
        actions: <Widget>[
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;
    final notes = (_dash?['notesSummary'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final sold = _dash?['soldQuantitiesToday'];
    final amt = _dash?['vehicleSalesAmountToday'];
    final exp = _dash?['totalExpensesToday'];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text(
          l10n.sectionToday,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(l10n.unitsSoldLine('$sold')),
        Text(l10n.salesAmountLine('$amt')),
        Text(l10n.expensesLine('$exp')),
        const SizedBox(height: 24),
        Text(
          l10n.notesFromExpenses,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        if (notes.isEmpty)
          Text(l10n.noNotesYet)
        else
          ...notes.map(
            (n) => ListTile(
              title: Text(n['note']?.toString() ?? ''),
              subtitle: Text(n['at']?.toString() ?? ''),
            ),
          ),
      ],
    );
  }
}
