import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar')];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'أماتيست'**
  String get appTitle;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @notFound.
  ///
  /// In ar, this message translates to:
  /// **'غير موجود'**
  String get notFound;

  /// No description provided for @unknownReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير غير معروف'**
  String get unknownReport;

  /// No description provided for @nothingHereYet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد شيء بعد.'**
  String get nothingHereYet;

  /// No description provided for @noSalesDaysRecorded.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أيام مبيعات مسجّلة بعد.'**
  String get noSalesDaysRecorded;

  /// No description provided for @signIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get signIn;

  /// No description provided for @signInSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'استخدم حساب أماتيست'**
  String get signInSubtitle;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @enterEmail.
  ///
  /// In ar, this message translates to:
  /// **'أدخل البريد الإلكتروني'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور'**
  String get enterPassword;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profile;

  /// No description provided for @notSignedIn.
  ///
  /// In ar, this message translates to:
  /// **'غير مسجّل الدخول'**
  String get notSignedIn;

  /// No description provided for @name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get name;

  /// No description provided for @emailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد'**
  String get emailLabel;

  /// No description provided for @role.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get role;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get phone;

  /// No description provided for @status.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get status;

  /// No description provided for @active.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In ar, this message translates to:
  /// **'غير نشط'**
  String get inactive;

  /// No description provided for @superAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مسؤول عام'**
  String get superAdmin;

  /// No description provided for @admin.
  ///
  /// In ar, this message translates to:
  /// **'مدير'**
  String get admin;

  /// No description provided for @driver.
  ///
  /// In ar, this message translates to:
  /// **'سائق'**
  String get driver;

  /// No description provided for @dashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get dashboard;

  /// No description provided for @users.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون'**
  String get users;

  /// No description provided for @admins.
  ///
  /// In ar, this message translates to:
  /// **'المديرون'**
  String get admins;

  /// No description provided for @products.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get products;

  /// No description provided for @vehicles.
  ///
  /// In ar, this message translates to:
  /// **'المركبات'**
  String get vehicles;

  /// No description provided for @vehicleLoads.
  ///
  /// In ar, this message translates to:
  /// **'تحميلات المركبات'**
  String get vehicleLoads;

  /// No description provided for @stationSales.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات المحطة'**
  String get stationSales;

  /// No description provided for @vehicleSales.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات المركبات'**
  String get vehicleSales;

  /// No description provided for @expenses.
  ///
  /// In ar, this message translates to:
  /// **'المصاريف'**
  String get expenses;

  /// No description provided for @reports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reports;

  /// No description provided for @inventoryMenu.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get inventoryMenu;

  /// No description provided for @returns.
  ///
  /// In ar, this message translates to:
  /// **'المرتجعات'**
  String get returns;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @profileTooltip.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profileTooltip;

  /// No description provided for @overview.
  ///
  /// In ar, this message translates to:
  /// **'نظرة عامة'**
  String get overview;

  /// No description provided for @operations.
  ///
  /// In ar, this message translates to:
  /// **'العمليات'**
  String get operations;

  /// No description provided for @stockSnapshot.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get stockSnapshot;

  /// No description provided for @remainingStock.
  ///
  /// In ar, this message translates to:
  /// **'المخزون المتبقي'**
  String get remainingStock;

  /// No description provided for @stockLine.
  ///
  /// In ar, this message translates to:
  /// **'المحطة: {station} · على المركبات: {vehicle}'**
  String stockLine(String station, String vehicle);

  /// No description provided for @kpiUsers.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون'**
  String get kpiUsers;

  /// No description provided for @kpiAdmins.
  ///
  /// In ar, this message translates to:
  /// **'المديرون'**
  String get kpiAdmins;

  /// No description provided for @kpiDrivers.
  ///
  /// In ar, this message translates to:
  /// **'السائقون'**
  String get kpiDrivers;

  /// No description provided for @kpiVehicles.
  ///
  /// In ar, this message translates to:
  /// **'المركبات'**
  String get kpiVehicles;

  /// No description provided for @salesToday.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات اليوم'**
  String get salesToday;

  /// No description provided for @profitToday.
  ///
  /// In ar, this message translates to:
  /// **'ربح اليوم'**
  String get profitToday;

  /// No description provided for @expensesToday.
  ///
  /// In ar, this message translates to:
  /// **'مصاريف اليوم'**
  String get expensesToday;

  /// No description provided for @monthlyExpenses.
  ///
  /// In ar, this message translates to:
  /// **'المصاريف الشهرية'**
  String get monthlyExpenses;

  /// No description provided for @monthlySales.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات الشهرية'**
  String get monthlySales;

  /// No description provided for @chipSalesToday.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات اليوم'**
  String get chipSalesToday;

  /// No description provided for @chipStation.
  ///
  /// In ar, this message translates to:
  /// **'المحطة'**
  String get chipStation;

  /// No description provided for @chipVehicle.
  ///
  /// In ar, this message translates to:
  /// **'المركبة'**
  String get chipVehicle;

  /// No description provided for @chipReturnsQty.
  ///
  /// In ar, this message translates to:
  /// **'المرتجعات (كمية)'**
  String get chipReturnsQty;

  /// No description provided for @chipMonthlySales.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات الشهرية'**
  String get chipMonthlySales;

  /// No description provided for @chipActiveDrivers.
  ///
  /// In ar, this message translates to:
  /// **'السائقون النشطون'**
  String get chipActiveDrivers;

  /// No description provided for @chipLoadsToday.
  ///
  /// In ar, this message translates to:
  /// **'التحميلات اليوم'**
  String get chipLoadsToday;

  /// No description provided for @revenue.
  ///
  /// In ar, this message translates to:
  /// **'الإيرادات'**
  String get revenue;

  /// No description provided for @netProfit.
  ///
  /// In ar, this message translates to:
  /// **'صافي الربح'**
  String get netProfit;

  /// No description provided for @noExpensesPeriod.
  ///
  /// In ar, this message translates to:
  /// **'لا مصاريف في هذه الفترة.'**
  String get noExpensesPeriod;

  /// No description provided for @stationSalesAmount.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات المحطة: {amount}'**
  String stationSalesAmount(String amount);

  /// No description provided for @vehicleSalesAmount.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات المركبات: {amount}'**
  String vehicleSalesAmount(String amount);

  /// No description provided for @combinedSales.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي: {amount}'**
  String combinedSales(String amount);

  /// No description provided for @transactionsSummary.
  ///
  /// In ar, this message translates to:
  /// **'معاملات: {stationCount} محطة · {vehicleCount} مركبة'**
  String transactionsSummary(int stationCount, int vehicleCount);

  /// No description provided for @salesTotal.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المبيعات: {amount}'**
  String salesTotal(String amount);

  /// No description provided for @daysWithSales.
  ///
  /// In ar, this message translates to:
  /// **'أيام المبيعات'**
  String get daysWithSales;

  /// No description provided for @titleUsers.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون'**
  String get titleUsers;

  /// No description provided for @titleAdmins.
  ///
  /// In ar, this message translates to:
  /// **'المديرون'**
  String get titleAdmins;

  /// No description provided for @titleProducts.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات'**
  String get titleProducts;

  /// No description provided for @titleVehicles.
  ///
  /// In ar, this message translates to:
  /// **'المركبات'**
  String get titleVehicles;

  /// No description provided for @titleVehicleLoads.
  ///
  /// In ar, this message translates to:
  /// **'تحميلات المركبات'**
  String get titleVehicleLoads;

  /// No description provided for @titleStationSales.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات المحطة'**
  String get titleStationSales;

  /// No description provided for @titleVehicleSales.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات المركبات'**
  String get titleVehicleSales;

  /// No description provided for @titleExpenses.
  ///
  /// In ar, this message translates to:
  /// **'المصاريف'**
  String get titleExpenses;

  /// No description provided for @titleInventoryProducts.
  ///
  /// In ar, this message translates to:
  /// **'المخزون · المنتجات'**
  String get titleInventoryProducts;

  /// No description provided for @titleReturns.
  ///
  /// In ar, this message translates to:
  /// **'المرتجعات'**
  String get titleReturns;

  /// No description provided for @addLoad.
  ///
  /// In ar, this message translates to:
  /// **'إضافة تحميل'**
  String get addLoad;

  /// No description provided for @driverAssigned.
  ///
  /// In ar, this message translates to:
  /// **'سائق معيّن'**
  String get driverAssigned;

  /// No description provided for @noDriver.
  ///
  /// In ar, this message translates to:
  /// **'بدون سائق'**
  String get noDriver;

  /// No description provided for @loadSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'{status} · كمية {qty}'**
  String loadSubtitle(String status, String qty);

  /// No description provided for @reportsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reportsTitle;

  /// No description provided for @inventory.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get inventory;

  /// No description provided for @profitLoss.
  ///
  /// In ar, this message translates to:
  /// **'الأرباح والخسائر'**
  String get profitLoss;

  /// No description provided for @currentVehicle.
  ///
  /// In ar, this message translates to:
  /// **'المركبة الحالية'**
  String get currentVehicle;

  /// No description provided for @shiftTime.
  ///
  /// In ar, this message translates to:
  /// **'الوردية'**
  String get shiftTime;

  /// No description provided for @statusLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get statusLabel;

  /// No description provided for @quickAddSale.
  ///
  /// In ar, this message translates to:
  /// **'بيع'**
  String get quickAddSale;

  /// No description provided for @quickAddExpense.
  ///
  /// In ar, this message translates to:
  /// **'مصروف'**
  String get quickAddExpense;

  /// No description provided for @quickLogReturn.
  ///
  /// In ar, this message translates to:
  /// **'إرجاع'**
  String get quickLogReturn;

  /// No description provided for @todaysInventory.
  ///
  /// In ar, this message translates to:
  /// **'مخزون اليوم'**
  String get todaysInventory;

  /// No description provided for @updatedAgo.
  ///
  /// In ar, this message translates to:
  /// **'محدّث منذ دقيقتين'**
  String get updatedAgo;

  /// No description provided for @itemHeader.
  ///
  /// In ar, this message translates to:
  /// **'الصنف'**
  String get itemHeader;

  /// No description provided for @loaded.
  ///
  /// In ar, this message translates to:
  /// **'المحمّل'**
  String get loaded;

  /// No description provided for @sold.
  ///
  /// In ar, this message translates to:
  /// **'المباع'**
  String get sold;

  /// No description provided for @left.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي'**
  String get left;

  /// No description provided for @expensesSection.
  ///
  /// In ar, this message translates to:
  /// **'المصاريف'**
  String get expensesSection;

  /// No description provided for @dailyNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات اليوم'**
  String get dailyNotes;

  /// No description provided for @notesFromExpenses.
  ///
  /// In ar, this message translates to:
  /// **'من المصاريف'**
  String get notesFromExpenses;

  /// No description provided for @routeMapTitle.
  ///
  /// In ar, this message translates to:
  /// **'المسار'**
  String get routeMapTitle;

  /// No description provided for @routeMapSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'عرض تفاعلي قريباً'**
  String get routeMapSubtitle;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navSales.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات'**
  String get navSales;

  /// No description provided for @navExpenses.
  ///
  /// In ar, this message translates to:
  /// **'المصاريف'**
  String get navExpenses;

  /// No description provided for @navLoads.
  ///
  /// In ar, this message translates to:
  /// **'التحميلات'**
  String get navLoads;

  /// No description provided for @navNotes.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات'**
  String get navNotes;

  /// No description provided for @myExpenses.
  ///
  /// In ar, this message translates to:
  /// **'مصاريفي'**
  String get myExpenses;

  /// No description provided for @addExpense.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مصروف'**
  String get addExpense;

  /// No description provided for @newExpense.
  ///
  /// In ar, this message translates to:
  /// **'مصروف جديد'**
  String get newExpense;

  /// No description provided for @amount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get amount;

  /// No description provided for @noteOptional.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختياري)'**
  String get noteOptional;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @expenseSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ المصروف'**
  String get expenseSaved;

  /// No description provided for @brandSemantic.
  ///
  /// In ar, this message translates to:
  /// **'أماتيست'**
  String get brandSemantic;

  /// No description provided for @titleInventory.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get titleInventory;

  /// No description provided for @profitTodayDetail.
  ///
  /// In ar, this message translates to:
  /// **'ربح اليوم'**
  String get profitTodayDetail;

  /// No description provided for @expensesTodayDetail.
  ///
  /// In ar, this message translates to:
  /// **'مصاريف اليوم'**
  String get expensesTodayDetail;

  /// No description provided for @monthlyExpensesDetail.
  ///
  /// In ar, this message translates to:
  /// **'المصاريف الشهرية'**
  String get monthlyExpensesDetail;

  /// No description provided for @monthlySalesDetail.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات الشهرية'**
  String get monthlySalesDetail;

  /// No description provided for @myVehicleSales.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات مركبتي'**
  String get myVehicleSales;

  /// No description provided for @notesAndSummary.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات وملخص'**
  String get notesAndSummary;

  /// No description provided for @currentLoads.
  ///
  /// In ar, this message translates to:
  /// **'التحميلات الحالية'**
  String get currentLoads;

  /// No description provided for @product.
  ///
  /// In ar, this message translates to:
  /// **'منتج'**
  String get product;

  /// No description provided for @addSale.
  ///
  /// In ar, this message translates to:
  /// **'إضافة بيع'**
  String get addSale;

  /// No description provided for @qtyAmountSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الكمية {qty} · {amount}'**
  String qtyAmountSubtitle(String qty, String amount);

  /// No description provided for @amountNoteSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'{amount} · {note}'**
  String amountNoteSubtitle(String amount, String note);

  /// No description provided for @signOutTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOutTooltip;

  /// No description provided for @sectionToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get sectionToday;

  /// No description provided for @unitsSoldLine.
  ///
  /// In ar, this message translates to:
  /// **'الوحدات المباعة: {value}'**
  String unitsSoldLine(String value);

  /// No description provided for @salesAmountLine.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ المبيعات: {value}'**
  String salesAmountLine(String value);

  /// No description provided for @expensesLine.
  ///
  /// In ar, this message translates to:
  /// **'المصاريف: {value}'**
  String expensesLine(String value);

  /// No description provided for @noNotesYet.
  ///
  /// In ar, this message translates to:
  /// **'لا ملاحظات بعد.'**
  String get noNotesYet;

  /// No description provided for @noVehicleAssignedFull.
  ///
  /// In ar, this message translates to:
  /// **'لا مركبة معيّنة.'**
  String get noVehicleAssignedFull;

  /// No description provided for @vehicleWithNumber.
  ///
  /// In ar, this message translates to:
  /// **'مركبة {number}'**
  String vehicleWithNumber(String number);

  /// No description provided for @noOpenLoads.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تحميلات مفتوحة.'**
  String get noOpenLoads;

  /// No description provided for @loadQuantitiesLine.
  ///
  /// In ar, this message translates to:
  /// **'محمّل {loaded} · مباع {sold} · مرتجع {returned} · متبقي {remaining}'**
  String loadQuantitiesLine(
    String loaded,
    String sold,
    String returned,
    String remaining,
  );

  /// No description provided for @submit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get submit;

  /// No description provided for @fillAllFields.
  ///
  /// In ar, this message translates to:
  /// **'أكمل جميع الحقول'**
  String get fillAllFields;

  /// No description provided for @loadCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء التحميل'**
  String get loadCreated;

  /// No description provided for @loadDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ التحميل'**
  String get loadDate;

  /// No description provided for @createLoad.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء تحميل'**
  String get createLoad;

  /// No description provided for @returnLogged.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الإرجاع'**
  String get returnLogged;

  /// No description provided for @noOpenLoadsToReturn.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تحميلات مفتوحة للإرجاع.'**
  String get noOpenLoadsToReturn;

  /// No description provided for @selectLoadAndQuantity.
  ///
  /// In ar, this message translates to:
  /// **'اختر التحميل والكمية'**
  String get selectLoadAndQuantity;

  /// No description provided for @checkQtyPrice.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من الكمية والسعر'**
  String get checkQtyPrice;

  /// No description provided for @saleRecorded.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل البيع'**
  String get saleRecorded;

  /// No description provided for @noVehicleContactAdmin.
  ///
  /// In ar, this message translates to:
  /// **'لا مركبة معيّنة. تواصل مع المدير.'**
  String get noVehicleContactAdmin;

  /// No description provided for @enterValidAmount.
  ///
  /// In ar, this message translates to:
  /// **'أدخل مبلغاً صالحاً'**
  String get enterValidAmount;

  /// No description provided for @newVehicleSale.
  ///
  /// In ar, this message translates to:
  /// **'بيع مركبة جديد'**
  String get newVehicleSale;

  /// No description provided for @quantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get quantity;

  /// No description provided for @unitPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر الوحدة'**
  String get unitPrice;

  /// No description provided for @newVehicleLoad.
  ///
  /// In ar, this message translates to:
  /// **'تحميل مركبة جديد'**
  String get newVehicleLoad;

  /// No description provided for @vehicleField.
  ///
  /// In ar, this message translates to:
  /// **'المركبة'**
  String get vehicleField;

  /// No description provided for @driverField.
  ///
  /// In ar, this message translates to:
  /// **'السائق'**
  String get driverField;

  /// No description provided for @quantityLoaded.
  ///
  /// In ar, this message translates to:
  /// **'الكمية المحمّلة'**
  String get quantityLoaded;

  /// No description provided for @loadField.
  ///
  /// In ar, this message translates to:
  /// **'التحميل'**
  String get loadField;

  /// No description provided for @quantityReturned.
  ///
  /// In ar, this message translates to:
  /// **'الكمية المرتجعة'**
  String get quantityReturned;

  /// No description provided for @loadDropdownItem.
  ///
  /// In ar, this message translates to:
  /// **'{product} · متبقي {remaining}'**
  String loadDropdownItem(String product, String remaining);

  /// No description provided for @logReturnSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل إرجاع'**
  String get logReturnSheetTitle;

  /// No description provided for @expensesSectionUpper.
  ///
  /// In ar, this message translates to:
  /// **'المصاريف'**
  String get expensesSectionUpper;

  /// No description provided for @dailyNotesUpper.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات اليوم'**
  String get dailyNotesUpper;

  /// No description provided for @noCriticalUpdatesToday.
  ///
  /// In ar, this message translates to:
  /// **'لا تحديثات مهمة لليوم بعد...'**
  String get noCriticalUpdatesToday;

  /// No description provided for @superAdminDrawerFallback.
  ///
  /// In ar, this message translates to:
  /// **'مسؤول عام'**
  String get superAdminDrawerFallback;

  /// No description provided for @adminDrawerFallback.
  ///
  /// In ar, this message translates to:
  /// **'مدير'**
  String get adminDrawerFallback;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
