import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// مفاتيح تتطابق مع [ExpenseCategoryHintsSection.onCategoryTap].
const Set<String> kExpenseReportCategoryKeys = <String>{
  'gasoline',
  'carRepair',
  'other',
  'tankWater',
  'cartons',
  'workersWages',
};

bool expenseNoteMatchesCategory(
  String note,
  String categoryKey,
  AppLocalizations l10n,
) {
  final n = note.trim();
  bool prefix(String p) =>
      n == p || n.startsWith('$p —') || n.startsWith('$p:');
  switch (categoryKey) {
    case 'gasoline':
      return prefix(l10n.gasolineExpenses);
    case 'carRepair':
      return prefix(l10n.carRepairExpenses);
    case 'other':
      return prefix(l10n.otherExpenses);
    case 'tankWater':
      return prefix(l10n.expenseTankWater);
    case 'cartons':
      return prefix(l10n.expenseCartons) || prefix(l10n.expenseCartonsWater);
    case 'workersWages':
      // Keep matching legacy labels too (pre-rename).
      return prefix(l10n.expenseWorkersWages) ||
          prefix(l10n.expenseStaffSalaries) ||
          prefix('رواتب عمال') ||
          prefix('رواتب موظفين');
    default:
      return false;
  }
}

String expenseReportCategoryTitle(String categoryKey, AppLocalizations l10n) {
  switch (categoryKey) {
    case 'gasoline':
      return l10n.gasolineExpenses;
    case 'carRepair':
      return l10n.carRepairExpenses;
    case 'other':
      return l10n.otherExpenses;
    case 'tankWater':
      return l10n.expenseTankWater;
    case 'cartons':
      return l10n.expenseCartons;
    case 'workersWages':
      return l10n.expenseWorkersWages;
    default:
      return l10n.notFound;
  }
}

/// تقرير مصاريف حسب تصنيف الملاحظة (للأدمن / السوبر أدمن).
class ExpenseCategoryReportPage extends StatefulWidget {
  const ExpenseCategoryReportPage({super.key, required this.categoryKey});

  final String categoryKey;

  @override
  State<ExpenseCategoryReportPage> createState() =>
      _ExpenseCategoryReportPageState();
}

class _ExpenseCategoryReportPageState extends State<ExpenseCategoryReportPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  bool _didLoadOnce = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadOnce) return;
    _didLoadOnce = true;
    // Safe to access inherited widgets like l10n here.
    _load(context.l10n);
  }

  Future<void> _load([AppLocalizations? l10nOverride]) async {
    if (!kExpenseReportCategoryKeys.contains(widget.categoryKey)) {
      setState(() {
        _loading = false;
        _error = null;
        _items = <Map<String, dynamic>>[];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final AppLocalizations l10n = l10nOverride ?? context.l10n;
    try {
      const int limit = 100; // server validation max=100
      const int maxPages = 5; // cap to avoid long loads
      final all = <Map<String, dynamic>>[];
      for (int page = 1; page <= maxPages; page++) {
        final data = await sl<AmethystApi>().listExpenses(page: page, limit: limit);
        final raw = data['items'];
        final pageItems = <Map<String, dynamic>>[];
        if (raw is List<dynamic>) {
          for (final dynamic e in raw) {
            if (e is Map<String, dynamic>) pageItems.add(e);
          }
        }
        all.addAll(pageItems);
        if (pageItems.length < limit) break;
      }
      if (!mounted) return;
      final filtered = all.where((Map<String, dynamic> m) {
        final note = '${m['note'] ?? ''}';
        return expenseNoteMatchesCategory(note, widget.categoryKey, l10n);
      }).toList(growable: false);

      filtered.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
        final da = _parseDate(a['createdAt']);
        final db = _parseDate(b['createdAt']);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

      if (!mounted) return;
      setState(() {
        _items = filtered;
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

  DateTime? _parseDate(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  double _parseAmount(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final valid = kExpenseReportCategoryKeys.contains(widget.categoryKey);
    final title = expenseReportCategoryTitle(widget.categoryKey, l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            onPressed: () => _load(context.l10n),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: !valid
          ? Center(child: Text(l10n.notFound))
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => _load(context.l10n),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildList(context, l10n),
    );
  }

  Widget _buildList(BuildContext context, AppLocalizations l10n) {
    if (_items.isEmpty) {
      return Center(child: Text(l10n.nothingHereYet));
    }

    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.yMMMMEEEEd(locale);
    final total = _items.fold<double>(
      0,
      (double s, Map<String, dynamic> m) => s + _parseAmount(m['amount']),
    );
    final totalLabel = l10n.expenseReportTotal(_formatMoney(total));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int i) {
              final m = _items[i];
              final dt = _parseDate(m['createdAt']);
              final dateLine = dt != null
                  ? dateFmt.format(dt)
                  : '—';
              final amount = _parseAmount(m['amount']);
              final driver = m['driver'] as Map<String, dynamic>?;
              final driverName = driver?['fullName']?.toString().trim();
              final subtitle = driverName != null && driverName.isNotEmpty
                  ? driverName
                  : l10n.expenseReportStationSource;

              return ListTile(
                title: Text(
                  dateLine,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(subtitle),
                trailing: Text(
                  l10n.amountDinars(_formatMoney(amount)),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                isThreeLine: false,
              );
            },
          ),
        ),
        Material(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Text(
              totalLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  String _formatMoney(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(2);
  }
}
