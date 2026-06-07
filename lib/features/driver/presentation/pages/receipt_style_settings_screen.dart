import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/printer/driver_receipt_style_id.dart';
import 'package:amethyst/core/printer/driver_receipt_styles_state.dart';
import 'package:amethyst/core/printer/receipt_style_config.dart';
import 'package:amethyst/core/printer/receipt_style_storage.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/features/driver/presentation/widgets/receipt_preview_sheet.dart';
import 'package:flutter/material.dart';

class ReceiptStyleSettingsScreen extends StatefulWidget {
  const ReceiptStyleSettingsScreen({super.key});

  @override
  State<ReceiptStyleSettingsScreen> createState() =>
      _ReceiptStyleSettingsScreenState();
}

class _ReceiptStyleSettingsScreenState extends State<ReceiptStyleSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  DriverReceiptStylesState? _state;
  DriverReceiptStyleId _editingId = DriverReceiptStyleId.pattern1;

  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _companyTitle = TextEditingController();
  final TextEditingController _saleTitle = TextEditingController();
  final TextEditingController _summaryTitle = TextEditingController();
  final TextEditingController _inventoryTitle = TextEditingController();
  final TextEditingController _signature = TextEditingController();
  final TextEditingController _stamp = TextEditingController();
  final TextEditingController _footerNote = TextEditingController();
  final TextEditingController _colItem = TextEditingController();
  final TextEditingController _colQty = TextEditingController();
  final TextEditingController _colPrice = TextEditingController();
  final TextEditingController _colTotal = TextEditingController();
  final TextEditingController _remainingTitle = TextEditingController();

  bool _showRemaining = true;
  bool _showSignature = true;
  bool _showStamp = true;
  bool _autoCut = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _displayName.dispose();
    _companyTitle.dispose();
    _saleTitle.dispose();
    _summaryTitle.dispose();
    _inventoryTitle.dispose();
    _signature.dispose();
    _stamp.dispose();
    _footerNote.dispose();
    _colItem.dispose();
    _colQty.dispose();
    _colPrice.dispose();
    _colTotal.dispose();
    _remainingTitle.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final DriverReceiptStylesState state = await ReceiptStyleStorage.loadAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _state = state;
      _editingId = state.activeId;
      _loading = false;
    });
    _applyToForm(state.styleFor(_editingId));
  }

  String _patternTabLabel(BuildContext context, DriverReceiptStyleId id) {
    final l10n = context.l10n;
    return switch (id) {
      DriverReceiptStyleId.pattern1 => l10n.receiptStylePattern1,
      DriverReceiptStyleId.pattern2 => l10n.receiptStylePattern2,
      DriverReceiptStyleId.pattern3 => l10n.receiptStylePattern3,
    };
  }

  void _selectPattern(DriverReceiptStyleId id) {
    if (_editingId == id) {
      return;
    }
    setState(() => _editingId = id);
    _applyToForm(_state?.styleFor(id) ?? ReceiptStyleConfig.preset(id));
  }

  void _applyToForm(ReceiptStyleConfig style) {
    _displayName.text = style.displayName;
    _companyTitle.text = style.companyTitleOverride;
    _saleTitle.text = style.saleInvoiceTitle;
    _summaryTitle.text = style.dailySummaryTitle;
    _inventoryTitle.text = style.inventoryReportTitle;
    _signature.text = style.receiverSignatureLabel;
    _stamp.text = style.stationStampLabel;
    _footerNote.text = style.footerNote;
    _colItem.text = style.colItem;
    _colQty.text = style.colQuantity;
    _colPrice.text = style.colPrice;
    _colTotal.text = style.colTotal;
    _remainingTitle.text = style.remainingInventoryTitle;
    _showRemaining = style.showRemainingInventory;
    _showSignature = style.showReceiverSignature;
    _showStamp = style.showStationStamp;
    _autoCut = style.autoCut;
  }

  ReceiptStyleConfig _readFromForm() {
    return ReceiptStyleConfig(
      displayName: _displayName.text.trim(),
      companyTitleOverride: _companyTitle.text.trim(),
      saleInvoiceTitle: _saleTitle.text.trim(),
      dailySummaryTitle: _summaryTitle.text.trim(),
      inventoryReportTitle: _inventoryTitle.text.trim(),
      showRemainingInventory: _showRemaining,
      showReceiverSignature: _showSignature,
      showStationStamp: _showStamp,
      receiverSignatureLabel: _signature.text.trim(),
      stationStampLabel: _stamp.text.trim(),
      footerNote: _footerNote.text.trim(),
      colItem: _colItem.text.trim(),
      colQuantity: _colQty.text.trim(),
      colPrice: _colPrice.text.trim(),
      colTotal: _colTotal.text.trim(),
      remainingInventoryTitle: _remainingTitle.text.trim(),
      autoCut: _autoCut,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ReceiptStyleConfig config = _readFromForm();
    await ReceiptStyleStorage.savePattern(id: _editingId, config: config);
    final DriverReceiptStylesState state = await ReceiptStyleStorage.loadAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _state = state;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.receiptStyleSaved)),
    );
  }

  Future<void> _setActiveForPrinting() async {
    await ReceiptStyleStorage.setActive(_editingId);
    final DriverReceiptStylesState state = await ReceiptStyleStorage.loadAll();
    if (!mounted) {
      return;
    }
    setState(() => _state = state);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.receiptStyleActivated)),
    );
  }

  Future<void> _resetPattern() async {
    await ReceiptStyleStorage.resetPattern(_editingId);
    final DriverReceiptStylesState state = await ReceiptStyleStorage.loadAll();
    if (!mounted) {
      return;
    }
    _applyToForm(state.styleFor(_editingId));
    setState(() => _state = state);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.receiptStyleReset)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final DriverReceiptStylesState? state = _state;
    final bool isActive = state?.activeId == _editingId;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.receiptStyleSettingsTitle),
      ),
      body: _loading || state == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: <Widget>[
                Text(
                  l10n.receiptStyleDriverOnlyHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<DriverReceiptStyleId>(
                  segments: DriverReceiptStyleId.values
                      .map(
                        (DriverReceiptStyleId id) =>
                            ButtonSegment<DriverReceiptStyleId>(
                          value: id,
                          label: Text(_patternTabLabel(context, id)),
                        ),
                      )
                      .toList(growable: false),
                  selected: <DriverReceiptStyleId>{_editingId},
                  onSelectionChanged: (Set<DriverReceiptStyleId> selected) {
                    _selectPattern(selected.first);
                  },
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: Icon(
                      isActive ? Icons.check_circle : Icons.circle_outlined,
                      color: isActive
                          ? AppColors.success
                          : AppColors.onSurfaceVariant,
                    ),
                    title: Text(
                      isActive
                          ? l10n.receiptStyleActivePattern
                          : l10n.receiptStyleInactivePattern,
                    ),
                    subtitle: Text(
                      state.styleFor(_editingId).displayName.isNotEmpty
                          ? state.styleFor(_editingId).displayName
                          : _patternTabLabel(context, _editingId),
                    ),
                    trailing: isActive
                        ? null
                        : FilledButton.tonal(
                            onPressed: _setActiveForPrinting,
                            child: Text(l10n.receiptStyleUseForPrint),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.receiptStyleSettingsHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                _sectionTitle(context, l10n.receiptStyleSectionHeader),
                _field(
                  controller: _displayName,
                  label: l10n.receiptStyleDisplayName,
                ),
                _field(
                  controller: _companyTitle,
                  label: l10n.receiptStyleCompanyTitle,
                  hint: l10n.receiptStyleCompanyTitleHint,
                ),
                _field(controller: _saleTitle, label: l10n.receiptStyleSaleTitle),
                _field(
                  controller: _summaryTitle,
                  label: l10n.receiptStyleSummaryTitle,
                ),
                _field(
                  controller: _inventoryTitle,
                  label: l10n.receiptStyleInventoryTitle,
                ),
                const SizedBox(height: 12),
                _sectionTitle(context, l10n.receiptStyleSectionColumns),
                _field(controller: _colItem, label: l10n.receiptStyleColItem),
                _field(controller: _colQty, label: l10n.receiptStyleColQty),
                _field(controller: _colPrice, label: l10n.receiptStyleColPrice),
                _field(controller: _colTotal, label: l10n.receiptStyleColTotal),
                const SizedBox(height: 12),
                _sectionTitle(context, l10n.receiptStyleSectionFooter),
                _field(
                  controller: _remainingTitle,
                  label: l10n.receiptStyleRemainingTitle,
                ),
                _field(
                  controller: _signature,
                  label: l10n.receiptStyleSignatureLabel,
                ),
                _field(controller: _stamp, label: l10n.receiptStyleStampLabel),
                _field(
                  controller: _footerNote,
                  label: l10n.receiptStyleFooterNote,
                  hint: l10n.receiptStyleFooterNoteHint,
                  maxLines: 2,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.receiptStyleShowRemaining),
                  value: _showRemaining,
                  onChanged: (bool v) => setState(() => _showRemaining = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.receiptStyleShowSignature),
                  value: _showSignature,
                  onChanged: (bool v) => setState(() => _showSignature = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.receiptStyleShowStamp),
                  value: _showStamp,
                  onChanged: (bool v) => setState(() => _showStamp = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.receiptStyleAutoCut),
                  value: _autoCut,
                  onChanged: (bool v) => setState(() => _autoCut = v),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => showReceiptPreviewSheet(
                    context,
                    styleOverride: _readFromForm(),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(l10n.printerReceiptPreviewTitle),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.receiptStyleSave),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _resetPattern,
                  child: Text(l10n.receiptStyleResetPatternButton),
                ),
              ],
            ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
