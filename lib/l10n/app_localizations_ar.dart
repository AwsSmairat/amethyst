// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'أماتيست';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get notFound => 'غير موجود';

  @override
  String get unknownReport => 'تقرير غير معروف';

  @override
  String get nothingHereYet => 'لا يوجد شيء بعد.';

  @override
  String get noSalesDaysRecorded => 'لا توجد أيام مبيعات مسجّلة بعد.';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signInSubtitle => 'استخدم حساب أماتيست';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get enterEmail => 'أدخل البريد الإلكتروني';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get notSignedIn => 'غير مسجّل الدخول';

  @override
  String get name => 'الاسم';

  @override
  String get emailLabel => 'البريد';

  @override
  String get role => 'الدور';

  @override
  String get phone => 'الهاتف';

  @override
  String get status => 'الحالة';

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get superAdmin => 'مسؤول عام';

  @override
  String get admin => 'مدير';

  @override
  String get driver => 'سائق';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get users => 'المستخدمون';

  @override
  String get admins => 'المديرون';

  @override
  String get products => 'المنتجات';

  @override
  String get menuStationStock => 'مخزون المحطة';

  @override
  String get vehicles => 'المركبات';

  @override
  String get vehicleLoads => 'تحميلات المركبات';

  @override
  String get stationSales => 'مبيعات المحطة';

  @override
  String get vehicleSales => 'مبيعات المركبات';

  @override
  String get expenses => 'المصاريف';

  @override
  String get reports => 'التقارير';

  @override
  String get inventoryMenu => 'المخزون';

  @override
  String get returns => 'المرتجعات';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get profileTooltip => 'الملف الشخصي';

  @override
  String get overview => 'نظرة عامة';

  @override
  String get operations => 'العمليات';

  @override
  String get stockSnapshot => 'المخزون';

  @override
  String get remainingStock => 'المخزون المتبقي';

  @override
  String stockLine(String station, String vehicle) {
    return 'المحطة: $station · على المركبات: $vehicle';
  }

  @override
  String get kpiUsers => 'المستخدمون';

  @override
  String get kpiAdmins => 'المديرون';

  @override
  String get kpiProductPrices => 'أسعار المنتجات';

  @override
  String get titleProductPrices => 'تعديل أسعار المنتجات';

  @override
  String get stationStockPricingSection => 'مخزون المحطة — التسعير';

  @override
  String get allProductsSectionTitle => 'جميع المنتجات';

  @override
  String get stationProductNotInCatalog =>
      'غير مُعرَّف في المنتجات. أضِف المنتج لتحديد السعر وربط المخزون.';

  @override
  String get addStationProductWithPrice => 'إضافة وتحديد السعر';

  @override
  String apiProductNameHint(String name) {
    return 'الاسم في النظام: $name';
  }

  @override
  String get editProductPriceTitle => 'تحديد سعر المنتج';

  @override
  String get productPriceFieldLabel => 'السعر';

  @override
  String get priceUpdated => 'تم حفظ السعر';

  @override
  String get enterValidPrice => 'أدخل سعراً أكبر من صفر';

  @override
  String get addProduct => 'إضافة منتج';

  @override
  String get productNameLabel => 'اسم المنتج (كما في النظام)';

  @override
  String get unitTypeLabel => 'نوع الوحدة';

  @override
  String get unitTypeGallon => 'جالون';

  @override
  String get unitTypeBottle => 'قارورة';

  @override
  String get unitTypeCarton => 'كرتون';

  @override
  String get unitTypeCoupon => 'كوبون';

  @override
  String get productTemplatesHint =>
      'اختر قالباً لملء الاسم تلقائياً (مطابق للتحميل والمبيعات)، ثم عدّل السعر.';

  @override
  String get productTemplateGallon => 'جالون';

  @override
  String get productTemplateBottle => 'قاروره';

  @override
  String get productTemplateCartonMahdi => 'مهدي (كرتون)';

  @override
  String get productTemplateCoupon1 => 'كوبون ١٢';

  @override
  String get productTemplateCoupon2 => 'كوبون ٢٤';

  @override
  String get productTemplateCoupon3 => 'كوبون ٥٠';

  @override
  String get productCreated => 'تم إنشاء المنتج';

  @override
  String get productDeleted => 'تم حذف المنتج';

  @override
  String get deleteProduct => 'حذف';

  @override
  String get deleteProductConfirmTitle => 'حذف المنتج';

  @override
  String deleteProductConfirmBody(String name) {
    return 'حذف $name؟ لا يمكن التراجع.';
  }

  @override
  String get productPricesEmptyHint =>
      'لا توجد منتجات بعد. اضغط «إضافة منتج» واستخدم القوالب (جالون، قاروره، مهدي، ق سعودي/اردني، ج فارغ، كوبون ١٢/٢٤/٥٠).';

  @override
  String get kpiDrivers => 'السائقون';

  @override
  String get kpiVehicles => 'المركبات';

  @override
  String get salesToday => 'مبيعات اليوم';

  @override
  String get profitToday => 'ربح اليوم';

  @override
  String get expensesToday => 'مصاريف اليوم';

  @override
  String get monthlyExpenses => 'المصاريف الشهرية';

  @override
  String get monthlySales => 'المبيعات الشهرية';

  @override
  String get cartonSalesMonthly => 'مبيع الكراتين';

  @override
  String get cartonStockLabel => 'مخزون كراتين';

  @override
  String get cartonPriceLabel => 'ثمن الكراتين';

  @override
  String get cartonSalesHomeLabel => 'بيع الكراتين منزل';

  @override
  String get cartonSalesStoreLabel => 'بيع الكراتين متجر';

  @override
  String get chipSalesToday => 'مبيعات اليوم';

  @override
  String get chipStation => 'المحطة';

  @override
  String get chipVehicle => 'المركبة';

  @override
  String get chipReturnsQty => 'المرتجعات (كمية)';

  @override
  String get chipMonthlySales => 'المبيعات الشهرية';

  @override
  String get chipActiveDrivers => 'السائقون النشطون';

  @override
  String get chipLoadsToday => 'التحميلات اليوم';

  @override
  String get revenue => 'الإيرادات';

  @override
  String get netProfit => 'صافي الربح';

  @override
  String get noExpensesPeriod => 'لا مصاريف في هذه الفترة.';

  @override
  String stationSalesAmount(String amount) {
    return 'مبيعات المحطة: $amount';
  }

  @override
  String vehicleSalesAmount(String amount) {
    return 'مبيعات المركبات: $amount';
  }

  @override
  String combinedSales(String amount) {
    return 'الإجمالي: $amount';
  }

  @override
  String transactionsSummary(int stationCount, int vehicleCount) {
    return 'معاملات: $stationCount محطة · $vehicleCount مركبة';
  }

  @override
  String salesTotal(String amount) {
    return 'إجمالي المبيعات: $amount';
  }

  @override
  String get totalSalesAmountLabel => 'إجمالي المبيعات';

  @override
  String get daysWithSales => 'أيام المبيعات';

  @override
  String get titleUsers => 'المستخدمون';

  @override
  String get addUser => 'إضافة مستخدم';

  @override
  String get titleDrivers => 'السائقون';

  @override
  String get addDriver => 'إضافة سائق';

  @override
  String get addVehicle => 'إضافة مركبة';

  @override
  String get vehicleNumberLabel => 'رقم / لوحة المركبة';

  @override
  String get vehicleNotesOptional => 'ملاحظات (اختياري)';

  @override
  String get driverOptionalLabel => 'السائق (اختياري)';

  @override
  String get vehicleCreated => 'تم إنشاء المركبة';

  @override
  String get vehicleDeleted => 'تم حذف المركبة';

  @override
  String get deleteVehicle => 'حذف';

  @override
  String get deleteVehicleConfirmTitle => 'حذف المركبة';

  @override
  String deleteVehicleConfirmBody(String name) {
    return 'هل تريد حذف المركبة $name؟';
  }

  @override
  String get deleteUser => 'حذف';

  @override
  String get deleteUserConfirmTitle => 'حذف المستخدم';

  @override
  String deleteUserConfirmBody(String name) {
    return 'هل تريد حذف $name؟';
  }

  @override
  String get userRoleLabel => 'الدور';

  @override
  String get userRoleAdminOption => 'مدير';

  @override
  String get userRoleDriverOption => 'سائق';

  @override
  String get userRoleSuperAdmin => 'مسؤول عام';

  @override
  String get userCreated => 'تم إنشاء المستخدم';

  @override
  String get userDeleted => 'تم حذف المستخدم';

  @override
  String get cannotDeleteSelf => 'لا يمكن حذف حسابك الحالي';

  @override
  String get newUserFullName => 'الاسم الكامل';

  @override
  String get newUserPhone => 'الهاتف';

  @override
  String get newUserEmail => 'البريد الإلكتروني';

  @override
  String get newUserPassword => 'كلمة المرور';

  @override
  String get titleAdmins => 'المديرون';

  @override
  String get titleProducts => 'المنتجات';

  @override
  String get titleVehicles => 'المركبات';

  @override
  String get titleVehicleLoads => 'تحميلات المركبات';

  @override
  String get titleStationSales => 'مبيعات المحطة';

  @override
  String get titleVehicleSales => 'مبيعات المركبات';

  @override
  String get titleExpenses => 'المصاريف';

  @override
  String get titleInventoryProducts => 'المخزون · المنتجات';

  @override
  String get titleReturns => 'المرتجعات';

  @override
  String get addLoad => 'إضافة تحميل';

  @override
  String get driverAssigned => 'سائق معيّن';

  @override
  String get noDriver => 'بدون سائق';

  @override
  String loadSubtitle(String status, String qty) {
    return '$status · كمية $qty';
  }

  @override
  String get reportsTitle => 'التقارير';

  @override
  String get inventory => 'المخزون';

  @override
  String get profitLoss => 'الأرباح والخسائر';

  @override
  String get currentVehicle => 'المركبة الحالية';

  @override
  String get shiftTime => 'الوردية';

  @override
  String get statusLabel => 'الحالة';

  @override
  String get quickAddSale => 'بيع';

  @override
  String get quickAddExpense => 'مصروف';

  @override
  String get quickLogReturn => 'إرجاع';

  @override
  String get todaysInventory => 'مخزون اليوم';

  @override
  String get updatedAgo => 'محدّث منذ دقيقتين';

  @override
  String get itemHeader => 'الصنف';

  @override
  String get loaded => 'المحمّل';

  @override
  String get sold => 'المباع';

  @override
  String get left => 'المتبقي';

  @override
  String get expensesSection => 'المصاريف';

  @override
  String get dailyNotes => 'ملاحظات اليوم';

  @override
  String get notesFromExpenses => 'من المصاريف';

  @override
  String get routeMapTitle => 'المسار';

  @override
  String get routeMapSubtitle => 'عرض تفاعلي قريباً';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navSales => 'المبيعات';

  @override
  String get navExpenses => 'المصاريف';

  @override
  String get navLoads => 'التحميلات';

  @override
  String get navNotes => 'الملاحظات';

  @override
  String get myExpenses => 'مصاريفي';

  @override
  String get gasolineExpenses => 'مصاريف بانزين';

  @override
  String get carRepairExpenses => 'مصاريف تصليح السيارة';

  @override
  String get otherExpenses => 'مصاريف أخرى';

  @override
  String get chooseExpenseCategory => 'اختر نوع المصروف';

  @override
  String get expenseDetailOptional => 'تفاصيل إضافية (اختياري)';

  @override
  String get otherExpenseDescriptionOptional => 'وصف المصروف (اختياري)';

  @override
  String get stationExpenses => 'مصاريف المحطة';

  @override
  String get stationBalanceTitle => 'رصيد المحطة';

  @override
  String get stationBalanceSubtitle => 'تسجيل أرصدة البنود';

  @override
  String get addStationBalance => 'تسجيل الرصيد';

  @override
  String get stationBalanceSaved => 'تم حفظ البيانات';

  @override
  String get stationBalanceField1 => 'ك مهدي';

  @override
  String get stationBalanceField2 => 'ك يافا';

  @override
  String get stationBalanceField3 => 'ش كبير';

  @override
  String get stationBalanceField4 => 'ش وسط';

  @override
  String get stationBalanceField5 => 'ش صغير';

  @override
  String get stationBalanceField6 => 'ق سعودي';

  @override
  String get stationBalanceField7 => 'ق اردني';

  @override
  String get stationBalanceField8 => 'ج فارغ';

  @override
  String get stationBalanceField9 => 'ق ١٠ لتر';

  @override
  String get stationBalanceField10 => 'ق ارضية';

  @override
  String get stationBalanceField11 => 'ج ارضية';

  @override
  String get stationBalanceField12 => 'دفتر كوبون';

  @override
  String get stationBalanceField13Optional => 'حقل إضافي (اختياري)';

  @override
  String get stationBalanceInvalidQuantity =>
      'تأكد أن الكميات أرقام صحيحة وغير سالبة.';

  @override
  String stationBalanceSaveRowUnlinked(String name) {
    return 'لا يوجد منتج في النظام يطابق البند: $name';
  }

  @override
  String get expenseTankWater => 'تنك مي';

  @override
  String get expenseCartons => 'كراتين مي';

  @override
  String get expenseCartonsWater => 'كراتين مي';

  @override
  String get expenseStaffSalaries => 'إيجار موظفين';

  @override
  String get expenseWorkersWages => 'إيجار موظفين';

  @override
  String get expenseStationCards => 'بطاقات';

  @override
  String get expenseStationCarTracking => 'تتبع سياره';

  @override
  String get expenseStationInternet => 'اشتراك نت';

  @override
  String get expenseStationShopRent => 'اجار محل';

  @override
  String get expenseStationRoomRent => 'اجار غرفه';

  @override
  String get expenseStationElectricity => 'اشتراك كهرباء';

  @override
  String get expenseStationBags => 'ثمن اكياس';

  @override
  String get expenseStationEmptyBottles => 'ثمن قوارير فارغ';

  @override
  String get expenseStationEmptyGallon => 'ثمن جالون فارغ';

  @override
  String get expenseStationSalt => 'ثمن مليح';

  @override
  String get expenseStationShrinkWrap => 'ثمن شرنكات';

  @override
  String get expenseStationFilters => 'ثمن فلاتر';

  @override
  String get stationExpenseNeedOneAmount => 'أدخل مبلغاً في حقل واحد على الأقل';

  @override
  String get attachReceiptOptional => 'إرفاق صورة (اختياري)';

  @override
  String get removeReceipt => 'إزالة الصورة';

  @override
  String amountDinars(String amount) {
    return '$amount دينار';
  }

  @override
  String expenseReportTotal(String amount) {
    return 'الإجمالي: $amount دينار';
  }

  @override
  String get expenseReportStationSource => 'المحطة';

  @override
  String get recordStationExpense => 'تسجيل مصاريف المحطة';

  @override
  String get openExpensesList => 'عرض قائمة المصاريف';

  @override
  String get newStationExpense => 'مصروف محطة جديد';

  @override
  String get addExpense => 'إضافة مصروف';

  @override
  String get newExpense => 'مصروف جديد';

  @override
  String get amount => 'المبلغ';

  @override
  String get noteOptional => 'ملاحظة (اختياري)';

  @override
  String get save => 'حفظ';

  @override
  String get expenseSaved => 'تم حفظ المصروف';

  @override
  String get brandSemantic => 'أماتيست';

  @override
  String get titleInventory => 'المخزون';

  @override
  String get profitTodayDetail => 'ربح اليوم';

  @override
  String get expensesTodayDetail => 'مصاريف اليوم';

  @override
  String get monthlyExpensesDetail => 'المصاريف الشهرية';

  @override
  String get monthlySalesDetail => 'المبيعات الشهرية';

  @override
  String get monthYearPeriodLabel => 'الشهر والسنة';

  @override
  String get combinedTotalLabel => 'الإجمالي';

  @override
  String get currentCalendarMonthChip => 'الشهر الحالي';

  @override
  String get previousCalendarMonthChip => 'الشهر السابق';

  @override
  String get monthlyExpensesTotalLabel => 'إجمالي مصاريف الشهر';

  @override
  String get noExpensesThisMonth => 'لا مصاريف في هذا الشهر.';

  @override
  String get expenseLinesSection => 'تفاصيل المصاريف';

  @override
  String get expenseDayDateLabel => 'التاريخ';

  @override
  String get expenseDayTotalLabel => 'إجمالي اليوم';

  @override
  String get noExpensesThisDay => 'لا مصاريف في هذا اليوم.';

  @override
  String get yesterdayChip => 'أمس';

  @override
  String get myVehicleSales => 'مبيعات مركبتي';

  @override
  String get notesAndSummary => 'ملاحظات وملخص';

  @override
  String get driverNotesTitle => 'ملاحظات';

  @override
  String get driverNotesFieldHint => 'اكتب ملاحظاتك هنا…';

  @override
  String get currentLoads => 'التحميلات الحالية';

  @override
  String get todaysLoadsSection => 'تحميلات اليوم';

  @override
  String get todaysLoadsExpandHint => 'اضغط لعرض المحمّل المسجّل لتاريخ اليوم';

  @override
  String get noLoadsForToday => 'لا تحميلات مفتوحة لتاريخ اليوم.';

  @override
  String get product => 'منتج';

  @override
  String get addSale => 'إضافة بيع';

  @override
  String qtyAmountSubtitle(String qty, String amount) {
    return 'الكمية $qty · $amount';
  }

  @override
  String amountNoteSubtitle(String amount, String note) {
    return '$amount · $note';
  }

  @override
  String get signOutTooltip => 'تسجيل الخروج';

  @override
  String get sectionToday => 'اليوم';

  @override
  String unitsSoldLine(String value) {
    return 'الوحدات المباعة: $value';
  }

  @override
  String salesAmountLine(String value) {
    return 'مبلغ المبيعات: $value';
  }

  @override
  String expensesLine(String value) {
    return 'المصاريف: $value';
  }

  @override
  String get noNotesYet => 'لا ملاحظات بعد.';

  @override
  String get noVehicleAssignedFull => 'لا مركبة معيّنة.';

  @override
  String vehicleWithNumber(String number) {
    return 'مركبة $number';
  }

  @override
  String get noOpenLoads => 'لا توجد تحميلات مفتوحة.';

  @override
  String loadQuantitiesLine(
    String loaded,
    String sold,
    String returned,
    String remaining,
  ) {
    return 'محمّل $loaded · مباع $sold · مرتجع $returned · متبقي $remaining';
  }

  @override
  String get submit => 'إرسال';

  @override
  String get fillAllFields => 'أكمل جميع الحقول';

  @override
  String get loadCreated => 'تم إنشاء التحميل';

  @override
  String get loadDate => 'تاريخ التحميل';

  @override
  String get createLoad => 'إنشاء تحميل';

  @override
  String get returnLogged => 'تم تسجيل الإرجاع';

  @override
  String get noOpenLoadsToReturn => 'لا توجد تحميلات مفتوحة للإرجاع.';

  @override
  String get selectLoadAndQuantity => 'اختر التحميل والكمية';

  @override
  String get checkQtyPrice => 'تحقق من الكمية والسعر';

  @override
  String get saleRecorded => 'تم تسجيل البيع';

  @override
  String get noVehicleContactAdmin => 'لا مركبة معيّنة. تواصل مع المدير.';

  @override
  String get enterValidAmount => 'أدخل مبلغاً صالحاً';

  @override
  String get newVehicleSale => 'تسجيل بيع من المركبة';

  @override
  String get quantity => 'الكمية';

  @override
  String get unitPrice => 'سعر الوحدة';

  @override
  String get newVehicleLoad => 'تحميل مركبة جديد';

  @override
  String get vehicleField => 'المركبة';

  @override
  String get driverField => 'السائق';

  @override
  String get quantityLoaded => 'الكمية المحمّلة';

  @override
  String get loadField => 'التحميل';

  @override
  String get quantityReturned => 'الكمية المرتجعة';

  @override
  String loadDropdownItem(String product, String remaining) {
    return '$product · متبقي $remaining';
  }

  @override
  String get logReturnSheetTitle => 'تسجيل إرجاع';

  @override
  String get expensesSectionUpper => 'المصاريف';

  @override
  String get dailyNotesUpper => 'ملاحظات اليوم';

  @override
  String get noCriticalUpdatesToday => 'لا تحديثات مهمة لليوم بعد...';

  @override
  String get superAdminDrawerFallback => 'مسؤول عام';

  @override
  String get adminDrawerFallback => 'مدير';

  @override
  String get openVehicleLoadsList => 'عرض قائمة التحميلات';

  @override
  String get loadStatusOpen => 'مفتوح';

  @override
  String get loadStatusClosed => 'مغلق';

  @override
  String get exportVehicleLoads => 'تصدير ملف';

  @override
  String get exportNoLoadsToday => 'لا توجد تحميلات لهذا اليوم للتصدير.';

  @override
  String get stationInsideSales => 'البيع داخل المحطة';

  @override
  String get newStationSale => 'تسجيل بيع من المحطة';

  @override
  String get stationSalePickKindTitle => 'اختر نوع البيع';

  @override
  String get stationSaleKindFilling => 'تعبئة';

  @override
  String get stationSaleKindEmptySale => 'بيع فارغ';

  @override
  String get stationSaleProductGallon => 'جالون';

  @override
  String get stationSaleProductBottle => 'قاروره';

  @override
  String get stationSaleProductMahdi => 'مهدي';

  @override
  String get stationSaleWithFilling => 'مع تعبئة';

  @override
  String get stationSaleWithFillingPriceHint =>
      'يُضاف ٠٫٥٠ لسعر كل وحدة على المنتجات التي تُباع.';

  @override
  String get stationSaleBack => 'رجوع';

  @override
  String get addStationSale => 'إضافة بيع';

  @override
  String get openStationSalesList => 'عرض قائمة مبيعات المحطة';

  @override
  String get stationSaleRecorded => 'تم تسجيل بيع المحطة';

  @override
  String get stationSalesRecorded => 'تم تسجيل مبيعات المحطة';

  @override
  String get stationSaleValidationNeedLine =>
      'حدّد كمية واحدة على الأقل لمنتج واحد (لا يلزم تعبئة كل الأعمدة).';

  @override
  String get stationSaleValidationInvalidRow =>
      'هذا المنتج غير مربوط في «أسعار المنتجات» أو غير موجود. اضبط المنتجات لدى السوبر أدمن، أو اجعل الكمية 0 للصفوف التي لا تبيعها.';

  @override
  String get stationSaleValidationCheckPrice =>
      'سعر أحد المنتجات غير معرّف — راجع «أسعار المنتجات».';

  @override
  String get stationSaleValidationInsufficientStock =>
      'الكمية أكبر من مخزون المحطة المتاح لهذا المنتج.';

  @override
  String get stationSaleSubmitInsufficientStock =>
      'المخزون تغيّر أو غير كافٍ. أعد فتح الشاشة أو قلّل الكمية.';

  @override
  String stationSaleStockAvailable(int count) {
    return 'المخزون: $count';
  }

  @override
  String get operationDateLabel => 'تاريخ العملية';

  @override
  String get sellerLabel => 'البائع';

  @override
  String get totalAmountLabel => 'الإجمالي';

  @override
  String get vehicleLoadProductsSection => 'المنتجات والكميات المحمّلة';

  @override
  String get vehicleLoadRowGallon => 'جالون';

  @override
  String get vehicleLoadRowBottle => 'قاروره';

  @override
  String get vehicleLoadRowCarton => 'ك مهدي';

  @override
  String get vehicleLoadCouponBook1 => 'كوبون ١٢';

  @override
  String get vehicleLoadCouponBook2 => 'كوبون ٢٤';

  @override
  String get vehicleLoadCouponBook3 => 'كوبون ٥٠';

  @override
  String productRow(int n) {
    return 'منتج $n';
  }

  @override
  String get vehicleLoadInvalidRow =>
      'أكمل المنتج والكمية (رقم ≥ 1) لكل صف تستخدمه.';

  @override
  String get vehicleLoadNeedOneLine =>
      'أضف منتجاً واحداً على الأقل مع كمية محمّلة.';

  @override
  String get loadsRecorded => 'تم تسجيل التحميلات';

  @override
  String get couponProduct => 'دفتر كوبون';

  @override
  String get vehicleSalesRecorded => 'تم تسجيل مبيعات المركبة';

  @override
  String get vehicleSaleChoosePlaceTitle => 'وجهة البيع';

  @override
  String get vehicleSaleTapToChoosePlace => 'اضغط لاختيار المنزل أو المتجر';

  @override
  String get vehicleSalePlaceHome => 'منزل';

  @override
  String get vehicleSalePlaceStore => 'متجر';

  @override
  String get vehicleSaleFromHome => 'البيع من: منزل';

  @override
  String get vehicleSaleFromStore => 'البيع من: متجر';

  @override
  String get couponButton => 'كوبون';
}
