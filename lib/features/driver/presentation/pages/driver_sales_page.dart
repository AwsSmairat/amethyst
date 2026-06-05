import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/widgets/fab_hero_tags.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/features/catalog/presentation/cubit/json_list_cubit.dart';
import 'package:amethyst/features/driver/presentation/driver_sales_list_refresh.dart';
import 'package:amethyst/features/driver/presentation/widgets/add_vehicle_sale_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DriverSalesPage extends StatefulWidget {
  const DriverSalesPage({super.key});

  @override
  State<DriverSalesPage> createState() => _DriverSalesPageState();
}

class _DriverSalesPageState extends State<DriverSalesPage> {
  late final JsonListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = JsonListCubit(() => sl<AmethystApi>().listVehicleSales())..load();
    DriverSalesListRefresh.onSalesTabSelected = _cubit.load;
  }

  @override
  void dispose() {
    if (DriverSalesListRefresh.onSalesTabSelected == _cubit.load) {
      DriverSalesListRefresh.onSalesTabSelected = null;
    }
    _cubit.close();
    super.dispose();
  }

  String _productName(BuildContext context, Map<String, dynamic> m) {
    final p = m['product'] as Map<String, dynamic>?;
    final name = p?['name']?.toString().trim();
    if (name != null && name.isNotEmpty) {
      return catalogProductArabicDisplayLabel(name);
    }
    return context.l10n.product;
  }

  DateTime? _parseDate(Object? v) {
    if (v == null) {
      return null;
    }
    if (v is DateTime) {
      return v;
    }
    return DateTime.tryParse(v.toString());
  }

  DateTime? _dayKey(DateTime? dt) {
    if (dt == null) {
      return null;
    }
    return DateTime(dt.year, dt.month, dt.day);
  }

  bool _isCashSale(Map<String, dynamic> m) => m['isDebt'] != true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider<JsonListCubit>.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.myVehicleSales),
          actions: <Widget>[
            IconButton(
              onPressed: _cubit.load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: FabHeroTags.driverSales,
          onPressed: () async {
            await showAddVehicleSaleSheet(context);
            if (mounted) {
              _cubit.load();
            }
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.addSale),
          backgroundColor: AppColors.brandPrimary,
        ),
        body: BlocBuilder<JsonListCubit, ListLoadState>(
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
                        onPressed: _cubit.load,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              );
            }
            final List<Map<String, dynamic>> items =
                (state as ListLoadLoaded).items;
            final List<Map<String, dynamic>> cashSales = items
                .where(_isCashSale)
                .toList(growable: false);
            if (cashSales.isEmpty) {
              return Center(child: Text(l10n.nothingHereYet));
            }

            final String locale = Localizations.localeOf(context).toString();
            final DateFormat dateFmt = DateFormat.yMMMMd(locale);

            final Map<DateTime?, List<Map<String, dynamic>>> grouped =
                <DateTime?, List<Map<String, dynamic>>>{};
            for (final Map<String, dynamic> m in cashSales) {
              final DateTime? dt = _parseDate(m['createdAt']);
              final DateTime? key = _dayKey(dt);
              (grouped[key] ??= <Map<String, dynamic>>[]).add(m);
            }
            final List<DateTime?> keys = grouped.keys.toList(growable: false)
              ..sort((DateTime? a, DateTime? b) {
                if (a == null && b == null) {
                  return 0;
                }
                if (a == null) {
                  return 1;
                }
                if (b == null) {
                  return -1;
                }
                return b.compareTo(a);
              });

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: keys.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int i) {
                final DateTime? day = keys[i];
                final String dayLabel =
                    day == null ? '—' : dateFmt.format(day);
                final List<Map<String, dynamic>> dayItems =
                    grouped[day] ?? const <Map<String, dynamic>>[];

                return InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        dayLabel,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      ...dayItems.map((Map<String, dynamic> m) {
                        final String name = _productName(context, m);
                        final String qty = '${m['quantity'] ?? ''}';
                        final String amount = '${m['totalAmount'] ?? ''}';
                        final String? debtor =
                            m['debtorName']?.toString().trim();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    if (debtor != null && debtor.isNotEmpty)
                                      Text(
                                        debtor,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.brandPrimary,
                                        ),
                                      ),
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.qtyAmountSubtitle(qty, amount),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.amountDinars(amount),
                                style:
                                    const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (dayItems.isNotEmpty) const SizedBox(height: 2),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
