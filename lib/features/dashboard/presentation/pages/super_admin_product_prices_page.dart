import 'package:amethyst/core/catalog/catalog_product_display_label.dart';
import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/presentation/list_load_state.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/core/utils/parse_dynamic_double.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/features/admin/presentation/station_balance/station_balance_lines.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_product_prices_cubit.dart';
import 'package:amethyst/features/dashboard/presentation/widgets/add_super_admin_product_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SuperAdminProductPricesPage extends StatelessWidget {
  const SuperAdminProductPricesPage({
    super.key,
    this.allowAddProduct = true,
  });

  /// سوبر أدمن: إضافة منتج جديد. الأدمن: تعديل الأسعار فقط.
  final bool allowAddProduct;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SuperAdminProductPricesCubit(sl<AmethystApi>())..load(),
      child: _SuperAdminProductPricesBody(allowAddProduct: allowAddProduct),
    );
  }
}

class _SuperAdminProductPricesBody extends StatelessWidget {
  const _SuperAdminProductPricesBody({required this.allowAddProduct});

  final bool allowAddProduct;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleProductPrices),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.retry,
            onPressed: () =>
                context.read<SuperAdminProductPricesCubit>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: allowAddProduct
          ? FloatingActionButton.extended(
              onPressed: () => showAddSuperAdminProductSheet(context),
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: Text(l10n.addProduct),
            )
          : null,
      body: BlocBuilder<SuperAdminProductPricesCubit, ListLoadState>(
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
                          context.read<SuperAdminProductPricesCubit>().load(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          final List<Map<String, dynamic>> rows =
              (state as ListLoadLoaded).items;
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Text(
                  l10n.stationStockPricingSection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              for (final Map<String, dynamic> row in rows)
                _SuperAdminPricingRowCard(
                  rowIndex: row['rowIndex'] as int,
                  product: row['product'] as Map<String, dynamic>?,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SuperAdminPricingRowCard extends StatefulWidget {
  const _SuperAdminPricingRowCard({
    required this.rowIndex,
    required this.product,
  });

  final int rowIndex;
  final Map<String, dynamic>? product;

  @override
  State<_SuperAdminPricingRowCard> createState() =>
      _SuperAdminPricingRowCardState();
}

class _SuperAdminPricingRowCardState extends State<_SuperAdminPricingRowCard> {
  late final TextEditingController _price;
  bool _saving = false;
  bool _linking = false;

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(text: _initialPriceText());
  }

  @override
  void didUpdateWidget(covariant _SuperAdminPricingRowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product?['id'] != widget.product?['id'] ||
        oldWidget.product?['price'] != widget.product?['price']) {
      _price.text = _initialPriceText();
    }
  }

  String _initialPriceText() {
    final double? p = parseDynamicDouble(widget.product?['price']);
    if (p == null) {
      return '';
    }
    return p == p.roundToDouble() ? '${p.toInt()}' : p.toString();
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Future<void> _savePrice() async {
    final String? productId = widget.product?['id']?.toString();
    if (productId == null || productId.isEmpty) {
      return;
    }
    final String normalized = _price.text.trim().replaceAll(',', '.');
    final double? parsed = double.tryParse(normalized);
    if (parsed == null || parsed < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.checkQtyPrice)),
      );
      return;
    }
    setState(() => _saving = true);
    final String? err = await context
        .read<SuperAdminProductPricesCubit>()
        .updatePrice(productId, parsed);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }

  Future<void> _linkProduct() async {
    setState(() => _linking = true);
    final String? err = await context
        .read<SuperAdminProductPricesCubit>()
        .linkPricingRow(widget.rowIndex);
    if (!mounted) {
      return;
    }
    setState(() => _linking = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final String rowLabel = productPricingRowLabel(l10n, widget.rowIndex);
    final Map<String, dynamic>? product = widget.product;
    final String? apiName = product?['name']?.toString();
    final bool linked = product != null && product['id'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              rowLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              linked && apiName != null && apiName.trim().isNotEmpty
                  ? '${l10n.product}: ${catalogProductArabicDisplayLabel(apiName)}'
                  : l10n.stationBalanceSaveRowUnlinked(rowLabel),
              style: theme.textTheme.bodySmall?.copyWith(
                    color: linked
                        ? AppColors.onSurfaceVariant
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (widget.rowIndex == kSuperAdminFillingGallonPricingExtraSlot) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'سعر تعبئة المحطة — منتج ١ جالون (بدون خصم مخزون).',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            if (widget.rowIndex == kSuperAdminFillingBottlePricingExtraSlot) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'سعر تعبئة المحطة — منتج ٢ قاروره (بدون خصم مخزون).',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            if (widget.rowIndex ==
                kSuperAdminFillingSmallGallonPricingExtraSlot) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'سعر جالون صغير (تعبئة/سيارة) — منتج مستقل عن «ج صغير فارغ».',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            if (widget.rowIndex ==
                kSuperAdminFillingSmallBottlePricingExtraSlot) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'سعر قاروره صغير (تعبئة/سيارة) — منتج مستقل عن «ق صغير فارغ».',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            if (widget.rowIndex ==
                kSuperAdminEmptySaleWithFillingRow1PricingExtraSlot) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'زيادة «مع تعبئة» لكل وحدة — المنتجات ١–٣ في بيع فارغ من المحطة.',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            if (widget.rowIndex ==
                kSuperAdminEmptySaleWithFillingRow2PricingExtraSlot) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'زيادة «مع تعبئة» لكل وحدة — المنتجين ٤–٥ في بيع فارغ من المحطة.',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            if (widget.rowIndex == kSuperAdminStoreGallonPricingExtraSlot) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'سعر بيع متجر؛ الخصم من حمولة السيارة (جالون ٢٠ لتر).',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            if (widget.rowIndex == kSuperAdminStoreBottlePricingExtraSlot) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'سعر بيع متجر؛ الخصم من حمولة السيارة (قارورة ٢٠ لتر).',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            if (widget.rowIndex == 0) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'سعر موحّد لـ «مهدي» (تعبئة المحطة) و«ك مهدي» (منزل/حمولة) — الخصم من مخزون ك مهدي.',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            if (widget.rowIndex == kSuperAdminStoreMahdiPricingExtraSlot) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'سعر «مهدي متجر» فقط (بيع متجر من السيارة) — الخصم من مخزون ك مهدي.',
                style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            if (!linked)
              OutlinedButton(
                onPressed: _linking ? null : _linkProduct,
                child: _linking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.linkProductToRow),
              )
            else ...<Widget>[
              TextField(
                controller: _price,
                textAlign: TextAlign.right,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.productPriceFieldLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: _saving ? null : _savePrice,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.save),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
