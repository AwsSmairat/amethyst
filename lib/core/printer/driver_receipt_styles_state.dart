import 'package:amethyst/core/printer/driver_receipt_style_id.dart';
import 'package:amethyst/core/printer/receipt_style_config.dart';

final class DriverReceiptStylesState {
  const DriverReceiptStylesState({
    required this.activeId,
    required this.styles,
  });

  final DriverReceiptStyleId activeId;
  final Map<DriverReceiptStyleId, ReceiptStyleConfig> styles;

  ReceiptStyleConfig get activeStyle =>
      styles[activeId] ?? ReceiptStyleConfig.preset(activeId);

  ReceiptStyleConfig styleFor(DriverReceiptStyleId id) =>
      styles[id] ?? ReceiptStyleConfig.preset(id);

  DriverReceiptStylesState copyWith({
    DriverReceiptStyleId? activeId,
    Map<DriverReceiptStyleId, ReceiptStyleConfig>? styles,
  }) {
    return DriverReceiptStylesState(
      activeId: activeId ?? this.activeId,
      styles: styles ?? this.styles,
    );
  }

  static DriverReceiptStylesState defaults() {
    return DriverReceiptStylesState(
      activeId: DriverReceiptStyleId.pattern1,
      styles: <DriverReceiptStyleId, ReceiptStyleConfig>{
        for (final DriverReceiptStyleId id in DriverReceiptStyleId.values)
          id: ReceiptStyleConfig.preset(id),
      },
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'activeId': activeId.storageKey(),
        'styles': <String, dynamic>{
          for (final MapEntry<DriverReceiptStyleId, ReceiptStyleConfig> e
              in styles.entries)
            e.key.storageKey(): e.value.toJson(),
        },
      };

  factory DriverReceiptStylesState.fromJson(Map<String, dynamic> json) {
    final DriverReceiptStyleId activeId =
        DriverReceiptStyleIdX.fromStorageKey(json['activeId'] as String?);
    final Map<String, dynamic>? rawStyles =
        json['styles'] as Map<String, dynamic>?;
    final Map<DriverReceiptStyleId, ReceiptStyleConfig> styles =
        <DriverReceiptStyleId, ReceiptStyleConfig>{};
    for (final DriverReceiptStyleId id in DriverReceiptStyleId.values) {
      final Map<String, dynamic>? raw = rawStyles?[id.storageKey()]
          as Map<String, dynamic>?;
      styles[id] = raw == null
          ? ReceiptStyleConfig.preset(id)
          : ReceiptStyleConfig.fromJson(raw, fallbackId: id);
    }
    return DriverReceiptStylesState(activeId: activeId, styles: styles);
  }
}
