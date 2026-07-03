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
  String get confirm => 'تأكيد';

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
  String get printOverviewTooltip => 'طباعة أو مشاركة تقارير';

  @override
  String get printOverviewShareFailed => 'تعذّر تحضير الملخص';

  @override
  String get printColumnProduct => 'المنتج';

  @override
  String get printColumnUnitType => 'نوع الوحدة';

  @override
  String get printColumnDateTime => 'التاريخ';

  @override
  String get printColumnAmount => 'المبلغ';

  @override
  String get printColumnNote => 'ملاحظة';

  @override
  String get printColumnVehicle => 'المركبة';

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
  String get linkProductToRow => 'ربط المنتج في النظام';

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
  String get productTemplateStoreGallon => 'جالون متجر';

  @override
  String get productTemplateStoreBottle => 'قاروره متجر';

  @override
  String get productTemplateStoreCarton => 'مهدي متجر';

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
  String get profitMonth => 'الربح الشهري';

  @override
  String get expensesToday => 'مصاريف اليوم';

  @override
  String get expensesGrandTotal => 'مجموع المصاريف';

  @override
  String expenseCategoryTodayLine(String amount) {
    return 'اليوم: $amount';
  }

  @override
  String expenseCategoryMonthLine(String amount) {
    return 'الشهر: $amount';
  }

  @override
  String get monthlyExpenses => 'المصاريف الشهرية';

  @override
  String get monthlySales => 'المبيعات الشهرية';

  @override
  String get cartonSalesMonthly => 'مبيع الكراتين';

  @override
  String get staffNoteKpi => 'ملاحظة';

  @override
  String get staffNoteSendTitle => 'إرسال ملاحظة';

  @override
  String get staffNoteMessageHint => 'اكتب الملاحظة هنا...';

  @override
  String get staffNoteRecipientLabel => 'المستلم';

  @override
  String get staffNoteRecipientAllAdmins => 'المحطة';

  @override
  String get staffNoteSendButton => 'إرسال';

  @override
  String get staffNoteSentSuccess => 'تم إرسال الملاحظة';

  @override
  String staffNoteFromSender(String name) {
    return 'من: $name';
  }

  @override
  String get staffNoteMarkRead => 'تم القراءة';

  @override
  String get staffNoteEmptyMessage => 'الرجاء كتابة الملاحظة';

  @override
  String get staffNotePickDriver => 'اختر السائق';

  @override
  String get superAdminDebtListKpiCaption => 'غير مسدد — الاسم والمنتجات';

  @override
  String get cartonStockLabel => 'مخزون كراتين';

  @override
  String get cartonMonthlyExpensesLabel => 'مصاريف الكراتين الشهرية';

  @override
  String get cartonPriceLabel => 'مجموع مبلغ البيع (دينار)';

  @override
  String get cartonSalesTotalQtyLabel => 'مجموع الكراتين المباعة (عدد)';

  @override
  String get cartonSalesHomeLabel => 'بيع الكراتين منزل (المحطة + السيارة)';

  @override
  String get cartonSalesStoreLabel => 'بيع الكراتين متجر (من السيارة للمتاجر)';

  @override
  String get cartonDebtUnpaidLabel => 'كراتين دين (غير مسدد — الإجمالي الحالي)';

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
  String get titleUsers => 'إدارة المستخدمين';

  @override
  String get addUser => 'إضافة مستخدم';

  @override
  String get editUser => 'تعديل المستخدم';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get passwordResetSent =>
      'تم إرسال رابط إعادة تعيين كلمة المرور إلى البريد';

  @override
  String get userUpdated => 'تم تحديث المستخدم';

  @override
  String get userActivated => 'تم تفعيل المستخدم';

  @override
  String get userDeactivated => 'تم إيقاف المستخدم';

  @override
  String get activateUser => 'تفعيل';

  @override
  String get deactivateUser => 'إيقاف';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب';

  @override
  String get invalidEmail => 'بريد إلكتروني غير صالح';

  @override
  String get passwordMinLength => 'كلمة المرور ٦ أحرف على الأقل';

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
  String get vehicleSalesChooseVehicleHint =>
      'اختر مركبة لعرض مبيعاتها بحسب اليوم.';

  @override
  String vehicleSalesDaysListTitle(String vehicle) {
    return 'أيام المبيعات · $vehicle';
  }

  @override
  String get vehicleSalesLinesSectionTitle => 'تفاصيل المبيعات';

  @override
  String get vehicleSaleDebtRepaymentBadge => 'سداد دين';

  @override
  String get vehicleSaleDestinationHome => 'المنزل';

  @override
  String get vehicleSaleDestinationStore => 'المتجر';

  @override
  String vehicleSalesVehicleDayTitle(String vehicle, String date) {
    return '$vehicle — $date';
  }

  @override
  String get vehicleSalesPickDay => 'اختر اليوم';

  @override
  String get vehicleLoadsChooseVehicleHint =>
      'اختر مركبة لعرض تحميلاتها بحسب اليوم.';

  @override
  String vehicleLoadTodayQtyLine(String count) {
    return 'محمّل اليوم: $count';
  }

  @override
  String vehicleLoadMonthQtyLine(String count) {
    return 'محمّل الشهر: $count';
  }

  @override
  String vehicleLoadRemainingQtyLine(String count) {
    return 'المتبقي على السيارة: $count';
  }

  @override
  String vehicleLoadsDaysListTitle(String vehicle) {
    return 'أيام التحميل · $vehicle';
  }

  @override
  String get vehicleLoadsSalesSummaryTitle => 'ملخص مبيعات اليوم';

  @override
  String get vehicleLoadsLoadsSectionTitle => 'التحميل على المركبة';

  @override
  String vehicleLoadsBatchesSectionTitle(String count) {
    return 'حمولات اليوم ($count)';
  }

  @override
  String vehicleLoadsDayBatchCountLine(String count) {
    return '$count حمولة';
  }

  @override
  String vehicleLoadBatchTitle(String number) {
    return 'حمل $number';
  }

  @override
  String vehicleLoadBatchMetaLine(String products, String pieces, String time) {
    return '$products منتج · $pieces قطعة · $time';
  }

  @override
  String vehicleLoadsGrandTotalSales(String amount) {
    return 'إجمالي المبيعات: $amount';
  }

  @override
  String get stationSalesSummaryHeaderAmount => 'المبلغ';

  @override
  String get stationSalesSummaryHeaderQuantity => 'الكمية';

  @override
  String get stationSalesSummaryHeaderCoupon => 'كوبون';

  @override
  String stationSalesGrandTotalCoupon(String count) {
    return 'إجمالي الكوبون: $count';
  }

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
  String get driverQuickDebt => 'الدين';

  @override
  String get driverQuickRepayment => 'السداد';

  @override
  String get driverRepaymentInfoTitle => 'السداد';

  @override
  String get driverRepaymentInfoBody =>
      'يمكنك تسجيل السداد للديون التي قمتَ بتسجيلها أنت فقط. «قائمة الدين» تعرض الأسماء التي سجّلتها من السيارة (وليس ديون المحطة المسجّلة من المكتب).';

  @override
  String get driverRepaymentInfoOpenList => 'قائمة الدين';

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
  String get myExpenses => 'مصاريفي';

  @override
  String get gasolineExpenses => 'مصاريف ديزل';

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
  String get stationAvailableBalanceTitle => 'الرصيد المتوفر في المحطة';

  @override
  String get openStationCashBalance => 'عرض رصيد الأموال';

  @override
  String get stationCashBalanceTitle => 'رصيد الأموال';

  @override
  String get stationCashBalancePageHint =>
      'رصيد نقدي منفصل عن رصيد البنود. سجّل المبلغ المتوفّر في المحطة.';

  @override
  String get registerStationCashBalance => 'تسجيل الرصيد';

  @override
  String get addStationCashBalance => 'تسجيل رصيد الأموال';

  @override
  String get stationCashBalanceDashboardSubtitle =>
      'الرصيد النقدي المتوفّر في المحطة';

  @override
  String get stationCashBalanceYesterdayLabel => 'رصيد الأمس';

  @override
  String get stationCashBalanceNewAmountLabel => 'المبلغ';

  @override
  String get stationCashBalanceTodayLabel => 'رصيد اليوم';

  @override
  String get stationCashBalanceRegisterHint =>
      'المبلغ يُسجَّل كرصيد اليوم. الرصيد الحالي ينتقل إلى يوم أمس.';

  @override
  String get stationCashBalanceSaved => 'تم حفظ رصيد الأموال';

  @override
  String get stationCashBalanceInvalidTodayAmount =>
      'أدخل رصيد اليوم بشكل صحيح';

  @override
  String get stationCashBalanceHistoryTitle => 'سجل التسجيلات';

  @override
  String stationCashBalanceEntryLine(String previous, String when) {
    return 'كان $previous · $when';
  }

  @override
  String get stationBalanceTitle => 'رصيد المحطة';

  @override
  String get stationBalanceSubtitle => 'تسجيل أرصدة البنود';

  @override
  String get stationBalancePageHint =>
      'عرض مخزون المحطة حسب التصنيف. اضغط «تسجيل الرصيد» لتحديث الكميات.';

  @override
  String get stationBalanceSectionCartons => 'كراتين';

  @override
  String get stationBalanceSectionBags => 'شرنك';

  @override
  String get stationBalanceSectionBottles => 'قوارير';

  @override
  String get stationBalanceSectionGallons => 'جالونات';

  @override
  String get stationBalanceSectionStationFloor => 'أرضية المحطة';

  @override
  String get stationBalanceSectionCoupons => 'كوبونات';

  @override
  String get stationBalanceSectionOptional => 'بند إضافي';

  @override
  String stationBalanceSectionStockLine(String stock, String count) {
    return 'المجموع $stock · $count بند';
  }

  @override
  String get stationBalanceTotalUnits => 'إجمالي الوحدات في المحطة';

  @override
  String get stationBalanceItemsWithStock => 'بنود بمخزون';

  @override
  String get stationBalanceLowStock => 'مخزون منخفض';

  @override
  String get stationBalanceUnlinked => 'غير مربوط';

  @override
  String get stationBalanceRowUnlinkedHint => 'لم يُربط بمنتج في النظام';

  @override
  String get stationBalanceSuperAdminPricesHint =>
      'تعديل أسعار المنتجات من شاشة التسعير';

  @override
  String get stationBalancePricingHint =>
      'تعديل أسعار المنتجات من شاشة التسعير';

  @override
  String get addStationBalance => 'تسجيل الرصيد';

  @override
  String get stationBalanceSaved => 'تم حفظ البيانات';

  @override
  String get stationBalanceField1 => 'ك مهدي';

  @override
  String get stationBalanceField2 => 'ك يافا';

  @override
  String get stationBalanceField3 => 'شرنك كبير';

  @override
  String get stationBalanceField4 => 'شرنك وسط';

  @override
  String get stationBalanceField5 => 'شرنك صغير';

  @override
  String get stationBalanceField6 => 'ق سعودي';

  @override
  String get stationBalanceField7 => 'ق اردني';

  @override
  String get stationBalanceField8 => 'ج فارغ';

  @override
  String get stationBalanceField10 => 'ق ارضية';

  @override
  String get stationBalanceField11 => 'ج ارضية';

  @override
  String get stationBalanceField12 => 'كوبون ١٢';

  @override
  String get stationBalanceField13 => 'كوبون ٢٤';

  @override
  String get stationBalanceField14 => 'كوبون ٥٠';

  @override
  String get stationBalanceField15 => 'ق صغير فارغ';

  @override
  String get stationBalanceField16 => 'ج صغير فارغ';

  @override
  String get stationBalanceFieldOptional => 'حقل إضافي (اختياري)';

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
  String get expenseStationExtra => 'مصاريف زيادة';

  @override
  String get expenseStationExtraNoteHint => 'اكتب وصف المصروف';

  @override
  String get stationExpenseExtraNeedNote =>
      'أدخل ملاحظة مع مبلغ مصاريف الزيادة';

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
  String get profitMonthDetail => 'الربح الشهري';

  @override
  String get profitTodayBusSalesTotal => 'مجموع بيع الباص';

  @override
  String get profitTodayBingoSalesTotal => 'مجموع بيع البينقو';

  @override
  String get profitTodayStationCashBalance => 'رصيد أموال المحطة';

  @override
  String get profitTodayStationExpenses => 'مصاريف المحطة';

  @override
  String get profitTodayStationNetFormula =>
      'مجموع المحطة (مبيعات - مصاريف + رصيد)';

  @override
  String get profitTodayGrandTotalFormula => 'المجموع (محطة + باص + بينقو)';

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
  String get addSaleAndPrintInvoice => 'إضافة بيع وطباعة فاتورة';

  @override
  String get vehicleSalePaymentCash => 'كاش';

  @override
  String get vehicleSalePaymentCliq => 'كليك';

  @override
  String get vehicleSaleChoosePaymentMethod => 'طريقة الدفع';

  @override
  String get vehicleSalePaymentMethodRequired =>
      'اختر طريقة الدفع: كاش أو كليك';

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
  String get vehicleHasNoDriverHint =>
      'لا يوجد سائق معيّن لهذه المركبة. عيّن سائقاً من شاشة المركبات ثم أعد المحاولة.';

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
  String get returnAutomaticEndOfDay => 'إرجاع تلقائي (نهاية اليوم)';

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
  String get stationDebtPickKindTitle => 'اختر نوع الدين';

  @override
  String get stationSaleKindFilling => 'تعبئة';

  @override
  String get stationSaleKindEmptySale => 'بيع فارغ';

  @override
  String get stationSaleProductGallon => 'جالون';

  @override
  String get stationSaleProductBottle => 'قاروره';

  @override
  String get stationSaleProductSmallGallon => 'جالون صغير';

  @override
  String get stationSaleProductSmallBottle => 'قاروره صغير';

  @override
  String get stationSaleProductMahdi => 'مهدي';

  @override
  String get stationSaleWithFilling => 'مع تعبئة';

  @override
  String get stationSaleWithFillingNeedQuantity =>
      'أضف كمية لأحد منتجات هذا الصف أولاً.';

  @override
  String stationSaleWithFillingPriceHint(String amount) {
    return 'يُضاف $amount لسعر كل وحدة على المنتجات المباعة في هذا الصف.';
  }

  @override
  String get stationSaleBack => 'رجوع';

  @override
  String get addStationSale => 'إضافة بيع';

  @override
  String get openStationSalesList => 'عرض قائمة مبيعات المحطة';

  @override
  String get openStationDebtList => 'عرض قائمة الدين';

  @override
  String get titleStationDebtList => 'قائمة الدين';

  @override
  String stationDebtDebtorLineCount(int count) {
    return '$count سجل';
  }

  @override
  String get dashboardDebtRepaymentTitle => 'دين وسداد';

  @override
  String get dashboardDebtRepaymentAction => 'تسجيل دين';

  @override
  String get stationDebtRegistrationTitle => 'دين وسداد';

  @override
  String get stationDebtVehicleRegistrationTitle => 'تسجيل الدين من المركبة';

  @override
  String get driverRegisterVehicleDebt => 'تسجيل الدين من المركبة';

  @override
  String get driverVehicleDebtSheetTitle => 'تسجيل الدين من المركبة';

  @override
  String get stationDebtDebtorNameLabel => 'اسم صاحب الدين';

  @override
  String get stationDebtDebtorNameHint => 'اكتب الاسم كاملاً';

  @override
  String get stationDebtProductsSection => 'المنتجات والكميات (تسجيل دين)';

  @override
  String get stationDebtSubmit => 'تسجيل الدين';

  @override
  String get stationDebtRecorded => 'تم تسجيل الدين';

  @override
  String get stationDebtValidationNeedName => 'اكتب اسم صاحب الدين.';

  @override
  String get stationDebtValidationNeedLine =>
      'حدّد كمية واحدة على الأقل لمنتج.';

  @override
  String get stationDebtValidationMissingProduct =>
      'تعذّر ربط أحد الأعمدة بمنتج في النظام.';

  @override
  String get stationDebtErrorApiRouteMissing =>
      'تعذّر تنفيذ عملية الدين. تحقق من اتصال Firebase وقواعد الأمان في Firestore.';

  @override
  String get stationDebtErrorForbidden =>
      'لا تملك صلاحية لهذه العملية. راجع المسؤول أو تأكد أن حسابك نشط في Firebase.';

  @override
  String get stationDebtRepayNoUnpaid =>
      'لا يوجد دين غير مسدد لهذا الاسم. حدّث القائمة أو تحقق من الخادم.';

  @override
  String get stationDebtRepayButton => 'تم السداد';

  @override
  String get stationDebtRepayConfirmTitle => 'تأكيد السداد';

  @override
  String get stationDebtRepayConfirmMessage =>
      'سيتم تسجيل هذه المبالغ كمبيعات محطة لهذا اليوم وتدخل في الإجمالي (المخزون سبق خصمه عند تسجيل الدين). هل تريد المتابعة؟';

  @override
  String get stationDebtRepayConfirmMessageVehicle =>
      'سيُسجَّل السداد كمبيع سيارة لهذا اليوم (المخزون سبق خصمه عند تسجيل الدين). هل تريد المتابعة؟';

  @override
  String get stationDebtRepayConfirmMessageMixed =>
      'سيُسجَّل السداد: دين المحطة كمبيع محطة، ودين السيارة كمبيع سيارة — بدون خصم مخزون إضافي. هل تريد المتابعة؟';

  @override
  String get stationDebtRepaySuccessMixed =>
      'تم تسجيل السداد في مبيعات المحطة والسيارة.';

  @override
  String get stationDebtSectionStation => 'دين المحطة';

  @override
  String get stationDebtSectionVehicle => 'دين السيارة';

  @override
  String get stationDebtSectionMixed => 'دين محطة و سيارة';

  @override
  String get stationDebtKindStation => 'دين محطة';

  @override
  String get stationDebtKindVehicle => 'دين سيارة';

  @override
  String get stationDebtRepaySuccess => 'تم تسجيل السداد في مبيعات المحطة.';

  @override
  String get stationDebtRepaySuccessVehicle =>
      'تم تسجيل السداد في مبيعات السيارة.';

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
  String get vehicleLoadCatalogGapHint =>
      'بعض البنود غير مربوطة بمنتج في النظام. من «أسعار المنتجات» أنشئ منتجاً لكل اسم إنجليزي يظهر أدناه بنفس الحرفية.';

  @override
  String get vehicleLoadNoStationStockForRow =>
      'لا يُتحقق من مخزون المحطة ولا يُخصم عند التحميل لهذا البند.';

  @override
  String vehicleLoadInsufficientStationStock(String product, String available) {
    return 'الكمية تتجاوز مخزون المحطة لـ $product (المتاح: $available).';
  }

  @override
  String get vehicleLoadStationStockHint =>
      'يُتحقق من مخزون المحطة قبل التحميل ولا يُخصم منه.';

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

  @override
  String get printerSettingsTitle => 'إعدادات الطابعة';

  @override
  String get printerStatusTitle => 'حالة الطابعة';

  @override
  String get printerStatusConnected => 'متصل';

  @override
  String get printerStatusConnecting => 'جاري الاتصال';

  @override
  String get printerStatusDisconnected => 'غير متصل';

  @override
  String get printerStatusError => 'خطأ';

  @override
  String get printerNoPrinterSelected => 'لم يتم اختيار طابعة';

  @override
  String get printerDisconnect => 'قطع الاتصال';

  @override
  String get printerTestPrint => 'طباعة تجريبية';

  @override
  String get printerRegisterSaleAndPrint => 'تسجيل بيع وطباعة';

  @override
  String get printerTestMessage => 'اختبار طباعة أماتيست';

  @override
  String get printerPairedDevicesTitle => 'الطابعات المقترنة';

  @override
  String get printerNoDevicesFound =>
      'لا توجد طابعات مقترنة. اقترن بالطابعة من إعدادات البلوتوث ثم حدّث القائمة.';

  @override
  String get printerConnected => 'تم الاتصال بالطابعة';

  @override
  String get printerPrintSuccess => 'تمت الطباعة بنجاح';

  @override
  String get printerPromptTitle => 'طباعة الإيصال';

  @override
  String get printerPromptSubtitle =>
      'هل تريد طباعة إيصال على الطابعة الحرارية؟';

  @override
  String get printerPrintReceipt => 'طباعة الإيصال';

  @override
  String get printerSkip => 'تخطي';

  @override
  String get printerOpenSettings => 'إعدادات الطابعة';

  @override
  String get printerSaleInvoiceTitle => 'فاتورة بيع رسمية';

  @override
  String get printerDailySummaryTitle => 'ملخص مبيعات اليوم';

  @override
  String get printerInventoryReportTitle => 'تقرير جرد المركبة';

  @override
  String get printerPaymentCash => 'نقدي';

  @override
  String get printerPrintDailySummary => 'طباعة ملخص اليوم';

  @override
  String get printerPrintInventoryReport => 'طباعة تقرير الجرد';

  @override
  String get printerReceiptPreviewTitle => 'معاينة نمط الفاتورة';

  @override
  String get printerReceiptPreviewHint =>
      'معاينة تقريبية لشكل الإيصال على ورق ٥٨مم (الطباعة الفعلية من الموبايل فقط).';

  @override
  String get printerPreviewSaleTab => 'فاتورة بيع';

  @override
  String get printerPreviewSummaryTab => 'ملخص يومي';

  @override
  String get printerPreviewInventoryTab => 'تقرير جرد';

  @override
  String get printerPreviewSampleDriver => 'محمد السائق';

  @override
  String get printerPreviewSampleVehicle => '١٢٣٤';

  @override
  String get receiptStyleSettingsTitle => 'تخصيص نمط الطباعة';

  @override
  String get receiptStyleSettingsHint =>
      'عدّل عناوين الفاتورة والأعمدة والتذييل لهذا النمط.';

  @override
  String get receiptStyleDriverOnlyHint =>
      'ثلاثة أنماط طباعة للسائق — اختر نمطاً للتعديل ثم فعّله للطباعة.';

  @override
  String get receiptStylePattern1 => 'النمط ١';

  @override
  String get receiptStylePattern2 => 'النمط ٢';

  @override
  String get receiptStylePattern3 => 'النمط ٣';

  @override
  String get receiptStyleDisplayName => 'اسم النمط';

  @override
  String get receiptStyleActivePattern => 'هذا النمط مفعّل للطباعة';

  @override
  String get receiptStyleInactivePattern => 'هذا النمط غير مفعّل';

  @override
  String get receiptStyleUseForPrint => 'تفعيل للطباعة';

  @override
  String get receiptStyleActivated => 'تم تفعيل النمط للطباعة';

  @override
  String get receiptStyleResetPatternButton => 'إعادة هذا النمط للافتراضي';

  @override
  String get receiptStyleSectionHeader => 'العناوين';

  @override
  String get receiptStyleSectionColumns => 'أعمدة الجدول';

  @override
  String get receiptStyleSectionFooter => 'التذييل والخيارات';

  @override
  String get receiptStyleCompanyTitle => 'اسم الشركة على الفاتورة';

  @override
  String get receiptStyleCompanyTitleHint =>
      'اتركه فارغاً لاستخدام اسم التطبيق';

  @override
  String get receiptStyleSaleTitle => 'عنوان فاتورة البيع';

  @override
  String get receiptStyleSummaryTitle => 'عنوان الملخص اليومي';

  @override
  String get receiptStyleInventoryTitle => 'عنوان تقرير الجرد';

  @override
  String get receiptStyleColItem => 'عمود الصنف';

  @override
  String get receiptStyleColQty => 'عمود الكمية';

  @override
  String get receiptStyleColPrice => 'عمود السعر';

  @override
  String get receiptStyleColTotal => 'عمود الإجمالي';

  @override
  String get receiptStyleRemainingTitle => 'عنوان المخزون المتبقي';

  @override
  String get receiptStyleSignatureLabel => 'سطر توقيع المستلم';

  @override
  String get receiptStyleStampLabel => 'سطر ختم المحطة';

  @override
  String get receiptStyleFooterNote => 'ملاحظة إضافية في التذييل';

  @override
  String get receiptStyleFooterNoteHint =>
      'اختياري — مثال: شكراً لتعاملكم معنا';

  @override
  String get receiptStyleShowRemaining => 'إظهار المخزون المتبقي';

  @override
  String get receiptStyleShowSignature => 'إظهار توقيع المستلم';

  @override
  String get receiptStyleShowStamp => 'إظهار ختم المحطة';

  @override
  String get receiptStyleAutoCut => 'قص الورق تلقائياً بعد الطباعة';

  @override
  String get receiptStyleSave => 'حفظ نمط الطباعة';

  @override
  String get receiptStyleSaved => 'تم حفظ نمط الطباعة';

  @override
  String get receiptStyleResetButton => 'إعادة الإعدادات الافتراضية';

  @override
  String get receiptStyleReset => 'تمت إعادة نمط الطباعة للوضع الافتراضي';

  @override
  String get adminDailyReportCardTitle => 'تقرير يوم المحطة';

  @override
  String get adminDailyReportCardSubtitle =>
      'طباعة رصيد المحطة، المخزون المتبقي، ومبيعات المحطة والمركبات لليوم.';

  @override
  String get adminDailyReportPrintButton => 'طباعة تقرير اليوم';

  @override
  String get adminDailyReportTitle => 'تقرير يوم المحطة';

  @override
  String get adminDailyReportPrintFailed => 'تعذّر تحضير تقرير اليوم للطباعة';

  @override
  String get adminDailyReportCashSection => 'رصيد الأموال';

  @override
  String get adminDailyReportBalanceSection => 'رصيد المحطة والمخزون';

  @override
  String get adminDailyReportBalanceTotalUnits => 'إجمالي وحدات رصيد المحطة';

  @override
  String get adminDailyReportRemainingStationStock => 'مخزون متبقي في المحطة';

  @override
  String get adminDailyReportRemainingOnVehicles => 'مخزون متبقي على المركبات';

  @override
  String get adminDailyReportSalesSummarySection => 'ملخص مبيعات اليوم';

  @override
  String get adminDailyReportTotalSalesToday => 'إجمالي المبيعات اليوم';

  @override
  String get adminDailyReportStationSalesSection => 'مبيعات المحطة اليوم';

  @override
  String get adminDailyReportVehicleSalesSection => 'مبيعات المركبات اليوم';

  @override
  String get adminVehicleSalesLabel => 'مبيعات المركبات';
}
