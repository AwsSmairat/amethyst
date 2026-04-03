import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/features/dashboard/presentation/cubit/super_admin_product_prices_cubit.dart';
import 'package:amethyst/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// قوالب أسماء الـ API كما يتوقعها التحميل والمبيعات في التطبيق.
final class _AppProductTemplate {
  const _AppProductTemplate({
    required this.apiName,
    required this.unitType,
    required this.labelBuilder,
  });

  final String apiName;
  final String unitType;
  final String Function(AppLocalizations l10n) labelBuilder;
}

Future<void> showAddSuperAdminProductSheet(BuildContext context) {
  final SuperAdminProductPricesCubit cubit =
      context.read<SuperAdminProductPricesCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext context) => BlocProvider.value(
      value: cubit,
      child: const _AddProductBody(),
    ),
  );
}

class _AddProductBody extends StatefulWidget {
  const _AddProductBody();

  @override
  State<_AddProductBody> createState() => _AddProductBodyState();
}

class _AddProductBodyState extends State<_AddProductBody> {
  static final List<_AppProductTemplate> _templates = <_AppProductTemplate>[
    _AppProductTemplate(
      apiName: 'Water Gallon',
      unitType: 'gallon',
      labelBuilder: (AppLocalizations l) => l.productTemplateGallon,
    ),
    _AppProductTemplate(
      apiName: 'Water Bottle',
      unitType: 'bottle',
      labelBuilder: (AppLocalizations l) => l.productTemplateBottle,
    ),
    _AppProductTemplate(
      apiName: 'Water Carton',
      unitType: 'carton',
      labelBuilder: (AppLocalizations l) => l.productTemplateCartonMahdi,
    ),
    _AppProductTemplate(
      apiName: 'Saudi Bottle',
      unitType: 'bottle',
      labelBuilder: (AppLocalizations l) => l.stationBalanceField6,
    ),
    _AppProductTemplate(
      apiName: 'Jordanian Bottle',
      unitType: 'bottle',
      labelBuilder: (AppLocalizations l) => l.stationBalanceField7,
    ),
    _AppProductTemplate(
      apiName: 'Empty Gallon',
      unitType: 'gallon',
      labelBuilder: (AppLocalizations l) => l.stationBalanceField8,
    ),
    _AppProductTemplate(
      apiName: 'Coupon',
      unitType: 'coupon',
      labelBuilder: (AppLocalizations l) => l.productTemplateCoupon1,
    ),
    _AppProductTemplate(
      apiName: 'Coupon 2',
      unitType: 'coupon',
      labelBuilder: (AppLocalizations l) => l.productTemplateCoupon2,
    ),
    _AppProductTemplate(
      apiName: 'Coupon 3',
      unitType: 'coupon',
      labelBuilder: (AppLocalizations l) => l.productTemplateCoupon3,
    ),
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _price = TextEditingController();
  String _unitType = 'gallon';
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _applyTemplate(_AppProductTemplate t) {
    setState(() {
      _name.text = t.apiName;
      _unitType = t.unitType;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final String normalized = _price.text.trim().replaceAll(',', '.');
    final double? parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return;
    }
    setState(() => _submitting = true);
    final String? err =
        await context.read<SuperAdminProductPricesCubit>().createProduct(
              name: _name.text.trim(),
              unitType: _unitType,
              price: parsed,
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
      SnackBar(content: Text(context.l10n.productCreated)),
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
                l10n.addProduct,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.productTemplatesHint,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: _templates
                    .map(
                      (t) => ActionChip(
                        label: Text(t.labelBuilder(l10n)),
                        onPressed: _submitting ? null : () => _applyTemplate(t),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textAlign: TextAlign.right,
                decoration: InputDecoration(labelText: l10n.productNameLabel),
                validator: (String? v) =>
                    v == null || v.trim().isEmpty ? ' ' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _unitType,
                decoration: InputDecoration(labelText: l10n.unitTypeLabel),
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem(
                    value: 'gallon',
                    child: Text(l10n.unitTypeGallon),
                  ),
                  DropdownMenuItem(
                    value: 'bottle',
                    child: Text(l10n.unitTypeBottle),
                  ),
                  DropdownMenuItem(
                    value: 'carton',
                    child: Text(l10n.unitTypeCarton),
                  ),
                  DropdownMenuItem(
                    value: 'coupon',
                    child: Text(l10n.unitTypeCoupon),
                  ),
                ],
                onChanged: _submitting
                    ? null
                    : (String? v) {
                        if (v != null) {
                          setState(() => _unitType = v);
                        }
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                textAlign: TextAlign.right,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(labelText: l10n.productPriceFieldLabel),
                validator: (String? v) {
                  if (v == null || v.trim().isEmpty) {
                    return ' ';
                  }
                  final double? p =
                      double.tryParse(v.trim().replaceAll(',', '.'));
                  if (p == null || p <= 0) {
                    return ' ';
                  }
                  return null;
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
