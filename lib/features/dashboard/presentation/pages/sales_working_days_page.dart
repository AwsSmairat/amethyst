import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Lists calendar days that had station and/or vehicle sales (tap target from Sales today KPI).
class SalesWorkingDaysPage extends StatefulWidget {
  const SalesWorkingDaysPage({super.key});

  @override
  State<SalesWorkingDaysPage> createState() => _SalesWorkingDaysPageState();
}

class _SalesWorkingDaysPageState extends State<SalesWorkingDaysPage> {
  late Future<Map<String, dynamic>> _load;

  Future<Map<String, dynamic>> _fetch() =>
      sl<AmethystApi>().reportsSalesWorkingDays();

  @override
  void initState() {
    super.initState();
    _load = _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.daysWithSales),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _load = _fetch();
                        });
                      },
                      child: Text(context.l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snapshot.data ?? <String, dynamic>{};
          final raw = data['days'];
          final List<dynamic> days = raw is List<dynamic> ? raw : <dynamic>[];
          if (days.isEmpty) {
            return Center(
              child: Text(context.l10n.noSalesDaysRecorded),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: days.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final dynamic item = days[i];
              final Map<String, dynamic> row = item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item as Map<dynamic, dynamic>);
              final String dateStr = row['date']?.toString() ?? '';
              DateTime? parsed;
              try {
                parsed = DateTime.parse(dateStr);
              } on Object {
                parsed = null;
              }
              final locale = Localizations.localeOf(context).toString();
              final String title = parsed != null
                  ? DateFormat.yMMMEd(locale).format(parsed)
                  : dateStr;
              final double combined = _toDouble(row['combined']);
              return ListTile(
                title: Text(title),
                subtitle: Text(
                  context.l10n.salesTotal(combined.toStringAsFixed(2)),
                  style: const TextStyle(color: AppColors.onSurfaceVariant),
                ),
              );
            },
          );
        },
      ),
    );
  }

  double _toDouble(dynamic v) {
    if (v == null) {
      return 0;
    }
    if (v is num) {
      return v.toDouble();
    }
    return double.tryParse(v.toString()) ?? 0;
  }
}
