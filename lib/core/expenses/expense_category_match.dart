import 'package:amethyst/l10n/app_localizations.dart';

/// مفاتيح تصنيفات المصاريف (سائق + محطة).
const List<String> kDriverExpenseCategoryKeys = <String>[
  'gasoline',
  'carRepair',
  'other',
];

/// تصنيفات مصاريف السائق في الواجهة (بدون «أخرى»).
const List<String> kDriverExpenseUiCategoryKeys = <String>[
  'gasoline',
  'carRepair',
];

const List<String> kStationExpenseCategoryKeys = <String>[
  'tankWater',
  'cartons',
  'workersWages',
  'stationCards',
  'stationCarTracking',
  'stationInternet',
  'stationShopRent',
  'stationRoomRent',
  'stationElectricity',
  'stationBags',
  'stationEmptyBottles',
  'stationEmptyGallon',
  'stationSalt',
  'stationShrinkWrap',
  'stationFilters',
];

const Set<String> kExpenseReportCategoryKeys = <String>{
  ...kDriverExpenseCategoryKeys,
  ...kStationExpenseCategoryKeys,
};

List<String> expenseCategoryKeysForHub({required bool includeStationExpense}) {
  return <String>[
    ...kDriverExpenseCategoryKeys,
    if (includeStationExpense) ...kStationExpenseCategoryKeys,
  ];
}

bool expenseNoteMatchesCategory(
  String note,
  String categoryKey,
  AppLocalizations l10n,
) {
  final String n = note.trim();
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
    case 'cartons': {
      const String sentinel = 'STATION_CARTON_WATER:';
      String rest = n;
      if (rest.startsWith(sentinel)) {
        rest = rest.substring(sentinel.length);
      }
      bool prefixCarton(String p) =>
          rest == p || rest.startsWith('$p —') || rest.startsWith('$p:');
      return prefixCarton(l10n.expenseCartons) ||
          prefixCarton(l10n.expenseCartonsWater);
    }
    case 'workersWages':
      return prefix(l10n.expenseWorkersWages) ||
          prefix(l10n.expenseStaffSalaries) ||
          prefix('رواتب عمال') ||
          prefix('رواتب موظفين');
    case 'stationCards':
      return prefix(l10n.expenseStationCards);
    case 'stationCarTracking':
      return prefix(l10n.expenseStationCarTracking);
    case 'stationInternet':
      return prefix(l10n.expenseStationInternet);
    case 'stationShopRent':
      return prefix(l10n.expenseStationShopRent);
    case 'stationRoomRent':
      return prefix(l10n.expenseStationRoomRent);
    case 'stationElectricity':
      return prefix(l10n.expenseStationElectricity);
    case 'stationBags':
      return prefix(l10n.expenseStationBags);
    case 'stationEmptyBottles':
      return prefix(l10n.expenseStationEmptyBottles);
    case 'stationEmptyGallon':
      return prefix(l10n.expenseStationEmptyGallon);
    case 'stationSalt':
      return prefix(l10n.expenseStationSalt);
    case 'stationShrinkWrap':
      return prefix(l10n.expenseStationShrinkWrap);
    case 'stationFilters':
      return prefix(l10n.expenseStationFilters);
    default:
      return false;
  }
}
