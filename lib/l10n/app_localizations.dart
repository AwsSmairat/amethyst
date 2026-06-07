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

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

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

  /// No description provided for @rememberMe.
  ///
  /// In ar, this message translates to:
  /// **'تذكرني'**
  String get rememberMe;

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

  /// No description provided for @menuStationStock.
  ///
  /// In ar, this message translates to:
  /// **'مخزون المحطة'**
  String get menuStationStock;

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

  /// No description provided for @printOverviewTooltip.
  ///
  /// In ar, this message translates to:
  /// **'طباعة أو مشاركة تقارير'**
  String get printOverviewTooltip;

  /// No description provided for @printOverviewShareFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحضير الملخص'**
  String get printOverviewShareFailed;

  /// No description provided for @printColumnProduct.
  ///
  /// In ar, this message translates to:
  /// **'المنتج'**
  String get printColumnProduct;

  /// No description provided for @printColumnUnitType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الوحدة'**
  String get printColumnUnitType;

  /// No description provided for @printColumnDateTime.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get printColumnDateTime;

  /// No description provided for @printColumnAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get printColumnAmount;

  /// No description provided for @printColumnNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get printColumnNote;

  /// No description provided for @printColumnVehicle.
  ///
  /// In ar, this message translates to:
  /// **'المركبة'**
  String get printColumnVehicle;

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

  /// No description provided for @kpiProductPrices.
  ///
  /// In ar, this message translates to:
  /// **'أسعار المنتجات'**
  String get kpiProductPrices;

  /// No description provided for @titleProductPrices.
  ///
  /// In ar, this message translates to:
  /// **'تعديل أسعار المنتجات'**
  String get titleProductPrices;

  /// No description provided for @stationStockPricingSection.
  ///
  /// In ar, this message translates to:
  /// **'مخزون المحطة — التسعير'**
  String get stationStockPricingSection;

  /// No description provided for @allProductsSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'جميع المنتجات'**
  String get allProductsSectionTitle;

  /// No description provided for @stationProductNotInCatalog.
  ///
  /// In ar, this message translates to:
  /// **'غير مُعرَّف في المنتجات. أضِف المنتج لتحديد السعر وربط المخزون.'**
  String get stationProductNotInCatalog;

  /// No description provided for @addStationProductWithPrice.
  ///
  /// In ar, this message translates to:
  /// **'إضافة وتحديد السعر'**
  String get addStationProductWithPrice;

  /// No description provided for @apiProductNameHint.
  ///
  /// In ar, this message translates to:
  /// **'الاسم في النظام: {name}'**
  String apiProductNameHint(String name);

  /// No description provided for @editProductPriceTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديد سعر المنتج'**
  String get editProductPriceTitle;

  /// No description provided for @productPriceFieldLabel.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get productPriceFieldLabel;

  /// No description provided for @priceUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ السعر'**
  String get priceUpdated;

  /// No description provided for @enterValidPrice.
  ///
  /// In ar, this message translates to:
  /// **'أدخل سعراً أكبر من صفر'**
  String get enterValidPrice;

  /// No description provided for @addProduct.
  ///
  /// In ar, this message translates to:
  /// **'إضافة منتج'**
  String get addProduct;

  /// No description provided for @linkProductToRow.
  ///
  /// In ar, this message translates to:
  /// **'ربط المنتج في النظام'**
  String get linkProductToRow;

  /// No description provided for @productNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم المنتج (كما في النظام)'**
  String get productNameLabel;

  /// No description provided for @unitTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الوحدة'**
  String get unitTypeLabel;

  /// No description provided for @unitTypeGallon.
  ///
  /// In ar, this message translates to:
  /// **'جالون'**
  String get unitTypeGallon;

  /// No description provided for @unitTypeBottle.
  ///
  /// In ar, this message translates to:
  /// **'قارورة'**
  String get unitTypeBottle;

  /// No description provided for @unitTypeCarton.
  ///
  /// In ar, this message translates to:
  /// **'كرتون'**
  String get unitTypeCarton;

  /// No description provided for @unitTypeCoupon.
  ///
  /// In ar, this message translates to:
  /// **'كوبون'**
  String get unitTypeCoupon;

  /// No description provided for @productTemplatesHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر قالباً لملء الاسم تلقائياً (مطابق للتحميل والمبيعات)، ثم عدّل السعر.'**
  String get productTemplatesHint;

  /// No description provided for @productTemplateGallon.
  ///
  /// In ar, this message translates to:
  /// **'جالون'**
  String get productTemplateGallon;

  /// No description provided for @productTemplateBottle.
  ///
  /// In ar, this message translates to:
  /// **'قاروره'**
  String get productTemplateBottle;

  /// No description provided for @productTemplateCartonMahdi.
  ///
  /// In ar, this message translates to:
  /// **'مهدي (كرتون)'**
  String get productTemplateCartonMahdi;

  /// No description provided for @productTemplateStoreGallon.
  ///
  /// In ar, this message translates to:
  /// **'جالون متجر'**
  String get productTemplateStoreGallon;

  /// No description provided for @productTemplateStoreBottle.
  ///
  /// In ar, this message translates to:
  /// **'قاروره متجر'**
  String get productTemplateStoreBottle;

  /// No description provided for @productTemplateStoreCarton.
  ///
  /// In ar, this message translates to:
  /// **'مهدي متجر'**
  String get productTemplateStoreCarton;

  /// No description provided for @productTemplateCoupon1.
  ///
  /// In ar, this message translates to:
  /// **'كوبون ١٢'**
  String get productTemplateCoupon1;

  /// No description provided for @productTemplateCoupon2.
  ///
  /// In ar, this message translates to:
  /// **'كوبون ٢٤'**
  String get productTemplateCoupon2;

  /// No description provided for @productTemplateCoupon3.
  ///
  /// In ar, this message translates to:
  /// **'كوبون ٥٠'**
  String get productTemplateCoupon3;

  /// No description provided for @productCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء المنتج'**
  String get productCreated;

  /// No description provided for @productDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف المنتج'**
  String get productDeleted;

  /// No description provided for @deleteProduct.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get deleteProduct;

  /// No description provided for @deleteProductConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف المنتج'**
  String get deleteProductConfirmTitle;

  /// No description provided for @deleteProductConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'حذف {name}؟ لا يمكن التراجع.'**
  String deleteProductConfirmBody(String name);

  /// No description provided for @productPricesEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منتجات بعد. اضغط «إضافة منتج» واستخدم القوالب (جالون، قاروره، مهدي، ق سعودي/اردني، ج فارغ، كوبون ١٢/٢٤/٥٠).'**
  String get productPricesEmptyHint;

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

  /// No description provided for @expensesGrandTotal.
  ///
  /// In ar, this message translates to:
  /// **'مجموع المصاريف'**
  String get expensesGrandTotal;

  /// No description provided for @expenseCategoryTodayLine.
  ///
  /// In ar, this message translates to:
  /// **'اليوم: {amount}'**
  String expenseCategoryTodayLine(String amount);

  /// No description provided for @expenseCategoryMonthLine.
  ///
  /// In ar, this message translates to:
  /// **'الشهر: {amount}'**
  String expenseCategoryMonthLine(String amount);

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

  /// No description provided for @cartonSalesMonthly.
  ///
  /// In ar, this message translates to:
  /// **'مبيع الكراتين'**
  String get cartonSalesMonthly;

  /// No description provided for @staffNoteKpi.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get staffNoteKpi;

  /// No description provided for @staffNoteSendTitle.
  ///
  /// In ar, this message translates to:
  /// **'إرسال ملاحظة'**
  String get staffNoteSendTitle;

  /// No description provided for @staffNoteMessageHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الملاحظة هنا...'**
  String get staffNoteMessageHint;

  /// No description provided for @staffNoteRecipientLabel.
  ///
  /// In ar, this message translates to:
  /// **'المستلم'**
  String get staffNoteRecipientLabel;

  /// No description provided for @staffNoteRecipientAllAdmins.
  ///
  /// In ar, this message translates to:
  /// **'المحطة'**
  String get staffNoteRecipientAllAdmins;

  /// No description provided for @staffNoteSendButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get staffNoteSendButton;

  /// No description provided for @staffNoteSentSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال الملاحظة'**
  String get staffNoteSentSuccess;

  /// No description provided for @staffNoteFromSender.
  ///
  /// In ar, this message translates to:
  /// **'من: {name}'**
  String staffNoteFromSender(String name);

  /// No description provided for @staffNoteMarkRead.
  ///
  /// In ar, this message translates to:
  /// **'تم القراءة'**
  String get staffNoteMarkRead;

  /// No description provided for @staffNoteEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء كتابة الملاحظة'**
  String get staffNoteEmptyMessage;

  /// No description provided for @staffNotePickDriver.
  ///
  /// In ar, this message translates to:
  /// **'اختر السائق'**
  String get staffNotePickDriver;

  /// No description provided for @superAdminDebtListKpiCaption.
  ///
  /// In ar, this message translates to:
  /// **'غير مسدد — الاسم والمنتجات'**
  String get superAdminDebtListKpiCaption;

  /// No description provided for @cartonStockLabel.
  ///
  /// In ar, this message translates to:
  /// **'مخزون كراتين'**
  String get cartonStockLabel;

  /// No description provided for @cartonMonthlyExpensesLabel.
  ///
  /// In ar, this message translates to:
  /// **'مصاريف الكراتين الشهرية'**
  String get cartonMonthlyExpensesLabel;

  /// No description provided for @cartonPriceLabel.
  ///
  /// In ar, this message translates to:
  /// **'مجموع بيع الكراتين'**
  String get cartonPriceLabel;

  /// No description provided for @cartonSalesHomeLabel.
  ///
  /// In ar, this message translates to:
  /// **'بيع الكراتين منزل (المحطة + السيارة)'**
  String get cartonSalesHomeLabel;

  /// No description provided for @cartonSalesStoreLabel.
  ///
  /// In ar, this message translates to:
  /// **'بيع الكراتين متجر (من السيارة للمتاجر)'**
  String get cartonSalesStoreLabel;

  /// No description provided for @cartonDebtUnpaidLabel.
  ///
  /// In ar, this message translates to:
  /// **'كراتين دين (غير مسدد — الإجمالي الحالي)'**
  String get cartonDebtUnpaidLabel;

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

  /// No description provided for @totalSalesAmountLabel.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المبيعات'**
  String get totalSalesAmountLabel;

  /// No description provided for @daysWithSales.
  ///
  /// In ar, this message translates to:
  /// **'أيام المبيعات'**
  String get daysWithSales;

  /// No description provided for @titleUsers.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المستخدمين'**
  String get titleUsers;

  /// No description provided for @addUser.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مستخدم'**
  String get addUser;

  /// No description provided for @editUser.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المستخدم'**
  String get editUser;

  /// No description provided for @resetPassword.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين كلمة المرور'**
  String get resetPassword;

  /// No description provided for @passwordResetSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رابط إعادة تعيين كلمة المرور إلى البريد'**
  String get passwordResetSent;

  /// No description provided for @userUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث المستخدم'**
  String get userUpdated;

  /// No description provided for @userActivated.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل المستخدم'**
  String get userActivated;

  /// No description provided for @userDeactivated.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف المستخدم'**
  String get userDeactivated;

  /// No description provided for @activateUser.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get activateUser;

  /// No description provided for @deactivateUser.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get deactivateUser;

  /// No description provided for @fieldRequired.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني غير صالح'**
  String get invalidEmail;

  /// No description provided for @passwordMinLength.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور ٦ أحرف على الأقل'**
  String get passwordMinLength;

  /// No description provided for @titleDrivers.
  ///
  /// In ar, this message translates to:
  /// **'السائقون'**
  String get titleDrivers;

  /// No description provided for @addDriver.
  ///
  /// In ar, this message translates to:
  /// **'إضافة سائق'**
  String get addDriver;

  /// No description provided for @addVehicle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مركبة'**
  String get addVehicle;

  /// No description provided for @vehicleNumberLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم / لوحة المركبة'**
  String get vehicleNumberLabel;

  /// No description provided for @vehicleNotesOptional.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات (اختياري)'**
  String get vehicleNotesOptional;

  /// No description provided for @driverOptionalLabel.
  ///
  /// In ar, this message translates to:
  /// **'السائق (اختياري)'**
  String get driverOptionalLabel;

  /// No description provided for @vehicleCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء المركبة'**
  String get vehicleCreated;

  /// No description provided for @vehicleDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف المركبة'**
  String get vehicleDeleted;

  /// No description provided for @deleteVehicle.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get deleteVehicle;

  /// No description provided for @deleteVehicleConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف المركبة'**
  String get deleteVehicleConfirmTitle;

  /// No description provided for @deleteVehicleConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف المركبة {name}؟'**
  String deleteVehicleConfirmBody(String name);

  /// No description provided for @deleteUser.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get deleteUser;

  /// No description provided for @deleteUserConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف المستخدم'**
  String get deleteUserConfirmTitle;

  /// No description provided for @deleteUserConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف {name}؟'**
  String deleteUserConfirmBody(String name);

  /// No description provided for @userRoleLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get userRoleLabel;

  /// No description provided for @userRoleAdminOption.
  ///
  /// In ar, this message translates to:
  /// **'مدير'**
  String get userRoleAdminOption;

  /// No description provided for @userRoleDriverOption.
  ///
  /// In ar, this message translates to:
  /// **'سائق'**
  String get userRoleDriverOption;

  /// No description provided for @userRoleSuperAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مسؤول عام'**
  String get userRoleSuperAdmin;

  /// No description provided for @userCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء المستخدم'**
  String get userCreated;

  /// No description provided for @userDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف المستخدم'**
  String get userDeleted;

  /// No description provided for @cannotDeleteSelf.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن حذف حسابك الحالي'**
  String get cannotDeleteSelf;

  /// No description provided for @newUserFullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get newUserFullName;

  /// No description provided for @newUserPhone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get newUserPhone;

  /// No description provided for @newUserEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get newUserEmail;

  /// No description provided for @newUserPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get newUserPassword;

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

  /// No description provided for @vehicleSalesChooseVehicleHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر مركبة لعرض مبيعاتها بحسب اليوم.'**
  String get vehicleSalesChooseVehicleHint;

  /// No description provided for @vehicleSalesDaysListTitle.
  ///
  /// In ar, this message translates to:
  /// **'أيام المبيعات · {vehicle}'**
  String vehicleSalesDaysListTitle(String vehicle);

  /// No description provided for @vehicleSalesLinesSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المبيعات'**
  String get vehicleSalesLinesSectionTitle;

  /// No description provided for @vehicleSaleDebtRepaymentBadge.
  ///
  /// In ar, this message translates to:
  /// **'سداد دين'**
  String get vehicleSaleDebtRepaymentBadge;

  /// No description provided for @vehicleSaleDestinationHome.
  ///
  /// In ar, this message translates to:
  /// **'المنزل'**
  String get vehicleSaleDestinationHome;

  /// No description provided for @vehicleSaleDestinationStore.
  ///
  /// In ar, this message translates to:
  /// **'المتجر'**
  String get vehicleSaleDestinationStore;

  /// No description provided for @vehicleSalesVehicleDayTitle.
  ///
  /// In ar, this message translates to:
  /// **'{vehicle} — {date}'**
  String vehicleSalesVehicleDayTitle(String vehicle, String date);

  /// No description provided for @vehicleSalesPickDay.
  ///
  /// In ar, this message translates to:
  /// **'اختر اليوم'**
  String get vehicleSalesPickDay;

  /// No description provided for @vehicleLoadsChooseVehicleHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر مركبة لعرض تحميلاتها بحسب اليوم.'**
  String get vehicleLoadsChooseVehicleHint;

  /// No description provided for @vehicleLoadTodayQtyLine.
  ///
  /// In ar, this message translates to:
  /// **'محمّل اليوم: {count}'**
  String vehicleLoadTodayQtyLine(String count);

  /// No description provided for @vehicleLoadMonthQtyLine.
  ///
  /// In ar, this message translates to:
  /// **'محمّل الشهر: {count}'**
  String vehicleLoadMonthQtyLine(String count);

  /// No description provided for @vehicleLoadRemainingQtyLine.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي على السيارة: {count}'**
  String vehicleLoadRemainingQtyLine(String count);

  /// No description provided for @vehicleLoadsDaysListTitle.
  ///
  /// In ar, this message translates to:
  /// **'أيام التحميل · {vehicle}'**
  String vehicleLoadsDaysListTitle(String vehicle);

  /// No description provided for @vehicleLoadsSalesSummaryTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملخص مبيعات اليوم'**
  String get vehicleLoadsSalesSummaryTitle;

  /// No description provided for @vehicleLoadsLoadsSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'التحميل على المركبة'**
  String get vehicleLoadsLoadsSectionTitle;

  /// No description provided for @vehicleLoadsBatchesSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'حمولات اليوم ({count})'**
  String vehicleLoadsBatchesSectionTitle(String count);

  /// No description provided for @vehicleLoadsDayBatchCountLine.
  ///
  /// In ar, this message translates to:
  /// **'{count} حمولة'**
  String vehicleLoadsDayBatchCountLine(String count);

  /// No description provided for @vehicleLoadBatchTitle.
  ///
  /// In ar, this message translates to:
  /// **'حمل {number}'**
  String vehicleLoadBatchTitle(String number);

  /// No description provided for @vehicleLoadBatchMetaLine.
  ///
  /// In ar, this message translates to:
  /// **'{products} منتج · {pieces} قطعة · {time}'**
  String vehicleLoadBatchMetaLine(String products, String pieces, String time);

  /// No description provided for @vehicleLoadsGrandTotalSales.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المبيعات: {amount}'**
  String vehicleLoadsGrandTotalSales(String amount);

  /// No description provided for @stationSalesSummaryHeaderAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get stationSalesSummaryHeaderAmount;

  /// No description provided for @stationSalesSummaryHeaderQuantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get stationSalesSummaryHeaderQuantity;

  /// No description provided for @stationSalesSummaryHeaderCoupon.
  ///
  /// In ar, this message translates to:
  /// **'كوبون'**
  String get stationSalesSummaryHeaderCoupon;

  /// No description provided for @stationSalesGrandTotalCoupon.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الكوبون: {count}'**
  String stationSalesGrandTotalCoupon(String count);

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

  /// No description provided for @driverQuickDebt.
  ///
  /// In ar, this message translates to:
  /// **'الدين'**
  String get driverQuickDebt;

  /// No description provided for @driverQuickRepayment.
  ///
  /// In ar, this message translates to:
  /// **'السداد'**
  String get driverQuickRepayment;

  /// No description provided for @driverRepaymentInfoTitle.
  ///
  /// In ar, this message translates to:
  /// **'السداد'**
  String get driverRepaymentInfoTitle;

  /// No description provided for @driverRepaymentInfoBody.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تسجيل السداد للديون التي قمتَ بتسجيلها أنت فقط. «قائمة الدين» تعرض الأسماء التي سجّلتها من السيارة (وليس ديون المحطة المسجّلة من المكتب).'**
  String get driverRepaymentInfoBody;

  /// No description provided for @driverRepaymentInfoOpenList.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الدين'**
  String get driverRepaymentInfoOpenList;

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

  /// No description provided for @myExpenses.
  ///
  /// In ar, this message translates to:
  /// **'مصاريفي'**
  String get myExpenses;

  /// No description provided for @gasolineExpenses.
  ///
  /// In ar, this message translates to:
  /// **'مصاريف ديزل'**
  String get gasolineExpenses;

  /// No description provided for @carRepairExpenses.
  ///
  /// In ar, this message translates to:
  /// **'مصاريف تصليح السيارة'**
  String get carRepairExpenses;

  /// No description provided for @otherExpenses.
  ///
  /// In ar, this message translates to:
  /// **'مصاريف أخرى'**
  String get otherExpenses;

  /// No description provided for @chooseExpenseCategory.
  ///
  /// In ar, this message translates to:
  /// **'اختر نوع المصروف'**
  String get chooseExpenseCategory;

  /// No description provided for @expenseDetailOptional.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل إضافية (اختياري)'**
  String get expenseDetailOptional;

  /// No description provided for @otherExpenseDescriptionOptional.
  ///
  /// In ar, this message translates to:
  /// **'وصف المصروف (اختياري)'**
  String get otherExpenseDescriptionOptional;

  /// No description provided for @stationExpenses.
  ///
  /// In ar, this message translates to:
  /// **'مصاريف المحطة'**
  String get stationExpenses;

  /// No description provided for @stationAvailableBalanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد المتوفر في المحطة'**
  String get stationAvailableBalanceTitle;

  /// No description provided for @openStationCashBalance.
  ///
  /// In ar, this message translates to:
  /// **'عرض رصيد الأموال'**
  String get openStationCashBalance;

  /// No description provided for @stationCashBalanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'رصيد الأموال'**
  String get stationCashBalanceTitle;

  /// No description provided for @stationCashBalancePageHint.
  ///
  /// In ar, this message translates to:
  /// **'رصيد نقدي منفصل عن رصيد البنود. سجّل المبلغ المتوفّر في المحطة.'**
  String get stationCashBalancePageHint;

  /// No description provided for @registerStationCashBalance.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الرصيد'**
  String get registerStationCashBalance;

  /// No description provided for @addStationCashBalance.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل رصيد الأموال'**
  String get addStationCashBalance;

  /// No description provided for @stationCashBalanceDashboardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد النقدي المتوفّر في المحطة'**
  String get stationCashBalanceDashboardSubtitle;

  /// No description provided for @stationCashBalanceYesterdayLabel.
  ///
  /// In ar, this message translates to:
  /// **'رصيد الأمس'**
  String get stationCashBalanceYesterdayLabel;

  /// No description provided for @stationCashBalanceNewAmountLabel.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get stationCashBalanceNewAmountLabel;

  /// No description provided for @stationCashBalanceTodayLabel.
  ///
  /// In ar, this message translates to:
  /// **'رصيد اليوم'**
  String get stationCashBalanceTodayLabel;

  /// No description provided for @stationCashBalanceRegisterHint.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ يُسجَّل كرصيد اليوم. الرصيد الحالي ينتقل إلى يوم أمس.'**
  String get stationCashBalanceRegisterHint;

  /// No description provided for @stationCashBalanceSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ رصيد الأموال'**
  String get stationCashBalanceSaved;

  /// No description provided for @stationCashBalanceInvalidTodayAmount.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رصيد اليوم بشكل صحيح'**
  String get stationCashBalanceInvalidTodayAmount;

  /// No description provided for @stationCashBalanceHistoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل التسجيلات'**
  String get stationCashBalanceHistoryTitle;

  /// No description provided for @stationCashBalanceEntryLine.
  ///
  /// In ar, this message translates to:
  /// **'كان {previous} · {when}'**
  String stationCashBalanceEntryLine(String previous, String when);

  /// No description provided for @stationBalanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'رصيد المحطة'**
  String get stationBalanceTitle;

  /// No description provided for @stationBalanceSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل أرصدة البنود'**
  String get stationBalanceSubtitle;

  /// No description provided for @stationBalancePageHint.
  ///
  /// In ar, this message translates to:
  /// **'عرض مخزون المحطة حسب التصنيف. اضغط «تسجيل الرصيد» لتحديث الكميات.'**
  String get stationBalancePageHint;

  /// No description provided for @stationBalanceSectionCartons.
  ///
  /// In ar, this message translates to:
  /// **'كراتين'**
  String get stationBalanceSectionCartons;

  /// No description provided for @stationBalanceSectionBags.
  ///
  /// In ar, this message translates to:
  /// **'شرنك'**
  String get stationBalanceSectionBags;

  /// No description provided for @stationBalanceSectionBottles.
  ///
  /// In ar, this message translates to:
  /// **'قوارير'**
  String get stationBalanceSectionBottles;

  /// No description provided for @stationBalanceSectionGallons.
  ///
  /// In ar, this message translates to:
  /// **'جالونات'**
  String get stationBalanceSectionGallons;

  /// No description provided for @stationBalanceSectionStationFloor.
  ///
  /// In ar, this message translates to:
  /// **'أرضية المحطة'**
  String get stationBalanceSectionStationFloor;

  /// No description provided for @stationBalanceSectionCoupons.
  ///
  /// In ar, this message translates to:
  /// **'كوبونات'**
  String get stationBalanceSectionCoupons;

  /// No description provided for @stationBalanceSectionOptional.
  ///
  /// In ar, this message translates to:
  /// **'بند إضافي'**
  String get stationBalanceSectionOptional;

  /// No description provided for @stationBalanceSectionStockLine.
  ///
  /// In ar, this message translates to:
  /// **'المجموع {stock} · {count} بند'**
  String stationBalanceSectionStockLine(String stock, String count);

  /// No description provided for @stationBalanceTotalUnits.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الوحدات في المحطة'**
  String get stationBalanceTotalUnits;

  /// No description provided for @stationBalanceItemsWithStock.
  ///
  /// In ar, this message translates to:
  /// **'بنود بمخزون'**
  String get stationBalanceItemsWithStock;

  /// No description provided for @stationBalanceLowStock.
  ///
  /// In ar, this message translates to:
  /// **'مخزون منخفض'**
  String get stationBalanceLowStock;

  /// No description provided for @stationBalanceUnlinked.
  ///
  /// In ar, this message translates to:
  /// **'غير مربوط'**
  String get stationBalanceUnlinked;

  /// No description provided for @stationBalanceRowUnlinkedHint.
  ///
  /// In ar, this message translates to:
  /// **'لم يُربط بمنتج في النظام'**
  String get stationBalanceRowUnlinkedHint;

  /// No description provided for @stationBalanceSuperAdminPricesHint.
  ///
  /// In ar, this message translates to:
  /// **'تعديل أسعار المنتجات من شاشة التسعير'**
  String get stationBalanceSuperAdminPricesHint;

  /// No description provided for @stationBalancePricingHint.
  ///
  /// In ar, this message translates to:
  /// **'تعديل أسعار المنتجات من شاشة التسعير'**
  String get stationBalancePricingHint;

  /// No description provided for @addStationBalance.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الرصيد'**
  String get addStationBalance;

  /// No description provided for @stationBalanceSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ البيانات'**
  String get stationBalanceSaved;

  /// No description provided for @stationBalanceField1.
  ///
  /// In ar, this message translates to:
  /// **'ك مهدي'**
  String get stationBalanceField1;

  /// No description provided for @stationBalanceField2.
  ///
  /// In ar, this message translates to:
  /// **'ك يافا'**
  String get stationBalanceField2;

  /// No description provided for @stationBalanceField3.
  ///
  /// In ar, this message translates to:
  /// **'شرنك كبير'**
  String get stationBalanceField3;

  /// No description provided for @stationBalanceField4.
  ///
  /// In ar, this message translates to:
  /// **'شرنك وسط'**
  String get stationBalanceField4;

  /// No description provided for @stationBalanceField5.
  ///
  /// In ar, this message translates to:
  /// **'شرنك صغير'**
  String get stationBalanceField5;

  /// No description provided for @stationBalanceField6.
  ///
  /// In ar, this message translates to:
  /// **'ق سعودي'**
  String get stationBalanceField6;

  /// No description provided for @stationBalanceField7.
  ///
  /// In ar, this message translates to:
  /// **'ق اردني'**
  String get stationBalanceField7;

  /// No description provided for @stationBalanceField8.
  ///
  /// In ar, this message translates to:
  /// **'ج فارغ'**
  String get stationBalanceField8;

  /// No description provided for @stationBalanceField10.
  ///
  /// In ar, this message translates to:
  /// **'ق ارضية'**
  String get stationBalanceField10;

  /// No description provided for @stationBalanceField11.
  ///
  /// In ar, this message translates to:
  /// **'ج ارضية'**
  String get stationBalanceField11;

  /// No description provided for @stationBalanceField12.
  ///
  /// In ar, this message translates to:
  /// **'كوبون ١٢'**
  String get stationBalanceField12;

  /// No description provided for @stationBalanceField13.
  ///
  /// In ar, this message translates to:
  /// **'كوبون ٢٤'**
  String get stationBalanceField13;

  /// No description provided for @stationBalanceField14.
  ///
  /// In ar, this message translates to:
  /// **'كوبون ٥٠'**
  String get stationBalanceField14;

  /// No description provided for @stationBalanceField15.
  ///
  /// In ar, this message translates to:
  /// **'ق صغير فارغ'**
  String get stationBalanceField15;

  /// No description provided for @stationBalanceField16.
  ///
  /// In ar, this message translates to:
  /// **'ج صغير فارغ'**
  String get stationBalanceField16;

  /// No description provided for @stationBalanceFieldOptional.
  ///
  /// In ar, this message translates to:
  /// **'حقل إضافي (اختياري)'**
  String get stationBalanceFieldOptional;

  /// No description provided for @stationBalanceField13Optional.
  ///
  /// In ar, this message translates to:
  /// **'حقل إضافي (اختياري)'**
  String get stationBalanceField13Optional;

  /// No description provided for @stationBalanceInvalidQuantity.
  ///
  /// In ar, this message translates to:
  /// **'تأكد أن الكميات أرقام صحيحة وغير سالبة.'**
  String get stationBalanceInvalidQuantity;

  /// No description provided for @stationBalanceSaveRowUnlinked.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد منتج في النظام يطابق البند: {name}'**
  String stationBalanceSaveRowUnlinked(String name);

  /// No description provided for @expenseTankWater.
  ///
  /// In ar, this message translates to:
  /// **'تنك مي'**
  String get expenseTankWater;

  /// No description provided for @expenseCartons.
  ///
  /// In ar, this message translates to:
  /// **'كراتين مي'**
  String get expenseCartons;

  /// No description provided for @expenseCartonsWater.
  ///
  /// In ar, this message translates to:
  /// **'كراتين مي'**
  String get expenseCartonsWater;

  /// No description provided for @expenseStaffSalaries.
  ///
  /// In ar, this message translates to:
  /// **'إيجار موظفين'**
  String get expenseStaffSalaries;

  /// No description provided for @expenseWorkersWages.
  ///
  /// In ar, this message translates to:
  /// **'إيجار موظفين'**
  String get expenseWorkersWages;

  /// No description provided for @expenseStationCards.
  ///
  /// In ar, this message translates to:
  /// **'بطاقات'**
  String get expenseStationCards;

  /// No description provided for @expenseStationCarTracking.
  ///
  /// In ar, this message translates to:
  /// **'تتبع سياره'**
  String get expenseStationCarTracking;

  /// No description provided for @expenseStationInternet.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك نت'**
  String get expenseStationInternet;

  /// No description provided for @expenseStationShopRent.
  ///
  /// In ar, this message translates to:
  /// **'اجار محل'**
  String get expenseStationShopRent;

  /// No description provided for @expenseStationRoomRent.
  ///
  /// In ar, this message translates to:
  /// **'اجار غرفه'**
  String get expenseStationRoomRent;

  /// No description provided for @expenseStationElectricity.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك كهرباء'**
  String get expenseStationElectricity;

  /// No description provided for @expenseStationBags.
  ///
  /// In ar, this message translates to:
  /// **'ثمن اكياس'**
  String get expenseStationBags;

  /// No description provided for @expenseStationEmptyBottles.
  ///
  /// In ar, this message translates to:
  /// **'ثمن قوارير فارغ'**
  String get expenseStationEmptyBottles;

  /// No description provided for @expenseStationEmptyGallon.
  ///
  /// In ar, this message translates to:
  /// **'ثمن جالون فارغ'**
  String get expenseStationEmptyGallon;

  /// No description provided for @expenseStationSalt.
  ///
  /// In ar, this message translates to:
  /// **'ثمن مليح'**
  String get expenseStationSalt;

  /// No description provided for @expenseStationShrinkWrap.
  ///
  /// In ar, this message translates to:
  /// **'ثمن شرنكات'**
  String get expenseStationShrinkWrap;

  /// No description provided for @expenseStationFilters.
  ///
  /// In ar, this message translates to:
  /// **'ثمن فلاتر'**
  String get expenseStationFilters;

  /// No description provided for @expenseStationExtra.
  ///
  /// In ar, this message translates to:
  /// **'مصاريف زيادة'**
  String get expenseStationExtra;

  /// No description provided for @expenseStationExtraNoteHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب وصف المصروف'**
  String get expenseStationExtraNoteHint;

  /// No description provided for @stationExpenseExtraNeedNote.
  ///
  /// In ar, this message translates to:
  /// **'أدخل ملاحظة مع مبلغ مصاريف الزيادة'**
  String get stationExpenseExtraNeedNote;

  /// No description provided for @stationExpenseNeedOneAmount.
  ///
  /// In ar, this message translates to:
  /// **'أدخل مبلغاً في حقل واحد على الأقل'**
  String get stationExpenseNeedOneAmount;

  /// No description provided for @attachReceiptOptional.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق صورة (اختياري)'**
  String get attachReceiptOptional;

  /// No description provided for @removeReceipt.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الصورة'**
  String get removeReceipt;

  /// No description provided for @amountDinars.
  ///
  /// In ar, this message translates to:
  /// **'{amount} دينار'**
  String amountDinars(String amount);

  /// No description provided for @expenseReportTotal.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي: {amount} دينار'**
  String expenseReportTotal(String amount);

  /// No description provided for @expenseReportStationSource.
  ///
  /// In ar, this message translates to:
  /// **'المحطة'**
  String get expenseReportStationSource;

  /// No description provided for @recordStationExpense.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل مصاريف المحطة'**
  String get recordStationExpense;

  /// No description provided for @openExpensesList.
  ///
  /// In ar, this message translates to:
  /// **'عرض قائمة المصاريف'**
  String get openExpensesList;

  /// No description provided for @newStationExpense.
  ///
  /// In ar, this message translates to:
  /// **'مصروف محطة جديد'**
  String get newStationExpense;

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

  /// No description provided for @monthYearPeriodLabel.
  ///
  /// In ar, this message translates to:
  /// **'الشهر والسنة'**
  String get monthYearPeriodLabel;

  /// No description provided for @combinedTotalLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get combinedTotalLabel;

  /// No description provided for @currentCalendarMonthChip.
  ///
  /// In ar, this message translates to:
  /// **'الشهر الحالي'**
  String get currentCalendarMonthChip;

  /// No description provided for @previousCalendarMonthChip.
  ///
  /// In ar, this message translates to:
  /// **'الشهر السابق'**
  String get previousCalendarMonthChip;

  /// No description provided for @monthlyExpensesTotalLabel.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي مصاريف الشهر'**
  String get monthlyExpensesTotalLabel;

  /// No description provided for @noExpensesThisMonth.
  ///
  /// In ar, this message translates to:
  /// **'لا مصاريف في هذا الشهر.'**
  String get noExpensesThisMonth;

  /// No description provided for @expenseLinesSection.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المصاريف'**
  String get expenseLinesSection;

  /// No description provided for @expenseDayDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get expenseDayDateLabel;

  /// No description provided for @expenseDayTotalLabel.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي اليوم'**
  String get expenseDayTotalLabel;

  /// No description provided for @noExpensesThisDay.
  ///
  /// In ar, this message translates to:
  /// **'لا مصاريف في هذا اليوم.'**
  String get noExpensesThisDay;

  /// No description provided for @yesterdayChip.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get yesterdayChip;

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

  /// No description provided for @todaysLoadsSection.
  ///
  /// In ar, this message translates to:
  /// **'تحميلات اليوم'**
  String get todaysLoadsSection;

  /// No description provided for @todaysLoadsExpandHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لعرض المحمّل المسجّل لتاريخ اليوم'**
  String get todaysLoadsExpandHint;

  /// No description provided for @noLoadsForToday.
  ///
  /// In ar, this message translates to:
  /// **'لا تحميلات مفتوحة لتاريخ اليوم.'**
  String get noLoadsForToday;

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

  /// No description provided for @addSaleAndPrintInvoice.
  ///
  /// In ar, this message translates to:
  /// **'إضافة بيع وطباعة فاتورة'**
  String get addSaleAndPrintInvoice;

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
  /// **'تسجيل بيع من المركبة'**
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

  /// No description provided for @vehicleHasNoDriverHint.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد سائق معيّن لهذه المركبة. عيّن سائقاً من شاشة المركبات ثم أعد المحاولة.'**
  String get vehicleHasNoDriverHint;

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

  /// No description provided for @returnAutomaticEndOfDay.
  ///
  /// In ar, this message translates to:
  /// **'إرجاع تلقائي (نهاية اليوم)'**
  String get returnAutomaticEndOfDay;

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

  /// No description provided for @openVehicleLoadsList.
  ///
  /// In ar, this message translates to:
  /// **'عرض قائمة التحميلات'**
  String get openVehicleLoadsList;

  /// No description provided for @loadStatusOpen.
  ///
  /// In ar, this message translates to:
  /// **'مفتوح'**
  String get loadStatusOpen;

  /// No description provided for @loadStatusClosed.
  ///
  /// In ar, this message translates to:
  /// **'مغلق'**
  String get loadStatusClosed;

  /// No description provided for @exportVehicleLoads.
  ///
  /// In ar, this message translates to:
  /// **'تصدير ملف'**
  String get exportVehicleLoads;

  /// No description provided for @exportNoLoadsToday.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تحميلات لهذا اليوم للتصدير.'**
  String get exportNoLoadsToday;

  /// No description provided for @stationInsideSales.
  ///
  /// In ar, this message translates to:
  /// **'البيع داخل المحطة'**
  String get stationInsideSales;

  /// No description provided for @newStationSale.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل بيع من المحطة'**
  String get newStationSale;

  /// No description provided for @stationSalePickKindTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر نوع البيع'**
  String get stationSalePickKindTitle;

  /// No description provided for @stationDebtPickKindTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر نوع الدين'**
  String get stationDebtPickKindTitle;

  /// No description provided for @stationSaleKindFilling.
  ///
  /// In ar, this message translates to:
  /// **'تعبئة'**
  String get stationSaleKindFilling;

  /// No description provided for @stationSaleKindEmptySale.
  ///
  /// In ar, this message translates to:
  /// **'بيع فارغ'**
  String get stationSaleKindEmptySale;

  /// No description provided for @stationSaleProductGallon.
  ///
  /// In ar, this message translates to:
  /// **'جالون'**
  String get stationSaleProductGallon;

  /// No description provided for @stationSaleProductBottle.
  ///
  /// In ar, this message translates to:
  /// **'قاروره'**
  String get stationSaleProductBottle;

  /// No description provided for @stationSaleProductSmallGallon.
  ///
  /// In ar, this message translates to:
  /// **'جالون صغير'**
  String get stationSaleProductSmallGallon;

  /// No description provided for @stationSaleProductSmallBottle.
  ///
  /// In ar, this message translates to:
  /// **'قاروره صغير'**
  String get stationSaleProductSmallBottle;

  /// No description provided for @stationSaleProductMahdi.
  ///
  /// In ar, this message translates to:
  /// **'مهدي'**
  String get stationSaleProductMahdi;

  /// No description provided for @stationSaleWithFilling.
  ///
  /// In ar, this message translates to:
  /// **'مع تعبئة'**
  String get stationSaleWithFilling;

  /// No description provided for @stationSaleWithFillingNeedQuantity.
  ///
  /// In ar, this message translates to:
  /// **'أضف كمية لأحد منتجات هذا الصف أولاً.'**
  String get stationSaleWithFillingNeedQuantity;

  /// No description provided for @stationSaleWithFillingPriceHint.
  ///
  /// In ar, this message translates to:
  /// **'يُضاف {amount} لسعر كل وحدة على المنتجات المباعة في هذا الصف.'**
  String stationSaleWithFillingPriceHint(String amount);

  /// No description provided for @stationSaleBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get stationSaleBack;

  /// No description provided for @addStationSale.
  ///
  /// In ar, this message translates to:
  /// **'إضافة بيع'**
  String get addStationSale;

  /// No description provided for @openStationSalesList.
  ///
  /// In ar, this message translates to:
  /// **'عرض قائمة مبيعات المحطة'**
  String get openStationSalesList;

  /// No description provided for @openStationDebtList.
  ///
  /// In ar, this message translates to:
  /// **'عرض قائمة الدين'**
  String get openStationDebtList;

  /// No description provided for @titleStationDebtList.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الدين'**
  String get titleStationDebtList;

  /// No description provided for @stationDebtDebtorLineCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} سجل'**
  String stationDebtDebtorLineCount(int count);

  /// No description provided for @dashboardDebtRepaymentTitle.
  ///
  /// In ar, this message translates to:
  /// **'دين وسداد'**
  String get dashboardDebtRepaymentTitle;

  /// No description provided for @dashboardDebtRepaymentAction.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل دين'**
  String get dashboardDebtRepaymentAction;

  /// No description provided for @stationDebtRegistrationTitle.
  ///
  /// In ar, this message translates to:
  /// **'دين وسداد'**
  String get stationDebtRegistrationTitle;

  /// No description provided for @stationDebtVehicleRegistrationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدين من المركبة'**
  String get stationDebtVehicleRegistrationTitle;

  /// No description provided for @driverRegisterVehicleDebt.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدين من المركبة'**
  String get driverRegisterVehicleDebt;

  /// No description provided for @driverVehicleDebtSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدين من المركبة'**
  String get driverVehicleDebtSheetTitle;

  /// No description provided for @stationDebtDebtorNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم صاحب الدين'**
  String get stationDebtDebtorNameLabel;

  /// No description provided for @stationDebtDebtorNameHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب الاسم كاملاً'**
  String get stationDebtDebtorNameHint;

  /// No description provided for @stationDebtProductsSection.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات والكميات (تسجيل دين)'**
  String get stationDebtProductsSection;

  /// No description provided for @stationDebtSubmit.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدين'**
  String get stationDebtSubmit;

  /// No description provided for @stationDebtRecorded.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدين'**
  String get stationDebtRecorded;

  /// No description provided for @stationDebtValidationNeedName.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم صاحب الدين.'**
  String get stationDebtValidationNeedName;

  /// No description provided for @stationDebtValidationNeedLine.
  ///
  /// In ar, this message translates to:
  /// **'حدّد كمية واحدة على الأقل لمنتج.'**
  String get stationDebtValidationNeedLine;

  /// No description provided for @stationDebtValidationMissingProduct.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر ربط أحد الأعمدة بمنتج في النظام.'**
  String get stationDebtValidationMissingProduct;

  /// No description provided for @stationDebtErrorApiRouteMissing.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تنفيذ عملية الدين. تحقق من اتصال Firebase وقواعد الأمان في Firestore.'**
  String get stationDebtErrorApiRouteMissing;

  /// No description provided for @stationDebtErrorForbidden.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية لهذه العملية. راجع المسؤول أو تأكد أن حسابك نشط في Firebase.'**
  String get stationDebtErrorForbidden;

  /// No description provided for @stationDebtRepayNoUnpaid.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد دين غير مسدد لهذا الاسم. حدّث القائمة أو تحقق من الخادم.'**
  String get stationDebtRepayNoUnpaid;

  /// No description provided for @stationDebtRepayButton.
  ///
  /// In ar, this message translates to:
  /// **'تم السداد'**
  String get stationDebtRepayButton;

  /// No description provided for @stationDebtRepayConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد السداد'**
  String get stationDebtRepayConfirmTitle;

  /// No description provided for @stationDebtRepayConfirmMessage.
  ///
  /// In ar, this message translates to:
  /// **'سيتم تسجيل هذه المبالغ كمبيعات محطة لهذا اليوم وتدخل في الإجمالي (المخزون سبق خصمه عند تسجيل الدين). هل تريد المتابعة؟'**
  String get stationDebtRepayConfirmMessage;

  /// No description provided for @stationDebtRepayConfirmMessageVehicle.
  ///
  /// In ar, this message translates to:
  /// **'سيُسجَّل السداد كمبيع سيارة لهذا اليوم (المخزون سبق خصمه عند تسجيل الدين). هل تريد المتابعة؟'**
  String get stationDebtRepayConfirmMessageVehicle;

  /// No description provided for @stationDebtRepayConfirmMessageMixed.
  ///
  /// In ar, this message translates to:
  /// **'سيُسجَّل السداد: دين المحطة كمبيع محطة، ودين السيارة كمبيع سيارة — بدون خصم مخزون إضافي. هل تريد المتابعة؟'**
  String get stationDebtRepayConfirmMessageMixed;

  /// No description provided for @stationDebtRepaySuccessMixed.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل السداد في مبيعات المحطة والسيارة.'**
  String get stationDebtRepaySuccessMixed;

  /// No description provided for @stationDebtSectionStation.
  ///
  /// In ar, this message translates to:
  /// **'دين المحطة'**
  String get stationDebtSectionStation;

  /// No description provided for @stationDebtSectionVehicle.
  ///
  /// In ar, this message translates to:
  /// **'دين السيارة'**
  String get stationDebtSectionVehicle;

  /// No description provided for @stationDebtSectionMixed.
  ///
  /// In ar, this message translates to:
  /// **'دين محطة و سيارة'**
  String get stationDebtSectionMixed;

  /// No description provided for @stationDebtKindStation.
  ///
  /// In ar, this message translates to:
  /// **'دين محطة'**
  String get stationDebtKindStation;

  /// No description provided for @stationDebtKindVehicle.
  ///
  /// In ar, this message translates to:
  /// **'دين سيارة'**
  String get stationDebtKindVehicle;

  /// No description provided for @stationDebtRepaySuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل السداد في مبيعات المحطة.'**
  String get stationDebtRepaySuccess;

  /// No description provided for @stationDebtRepaySuccessVehicle.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل السداد في مبيعات السيارة.'**
  String get stationDebtRepaySuccessVehicle;

  /// No description provided for @stationSaleRecorded.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل بيع المحطة'**
  String get stationSaleRecorded;

  /// No description provided for @stationSalesRecorded.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل مبيعات المحطة'**
  String get stationSalesRecorded;

  /// No description provided for @stationSaleValidationNeedLine.
  ///
  /// In ar, this message translates to:
  /// **'حدّد كمية واحدة على الأقل لمنتج واحد (لا يلزم تعبئة كل الأعمدة).'**
  String get stationSaleValidationNeedLine;

  /// No description provided for @stationSaleValidationInvalidRow.
  ///
  /// In ar, this message translates to:
  /// **'هذا المنتج غير مربوط في «أسعار المنتجات» أو غير موجود. اضبط المنتجات لدى السوبر أدمن، أو اجعل الكمية 0 للصفوف التي لا تبيعها.'**
  String get stationSaleValidationInvalidRow;

  /// No description provided for @stationSaleValidationCheckPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر أحد المنتجات غير معرّف — راجع «أسعار المنتجات».'**
  String get stationSaleValidationCheckPrice;

  /// No description provided for @stationSaleValidationInsufficientStock.
  ///
  /// In ar, this message translates to:
  /// **'الكمية أكبر من مخزون المحطة المتاح لهذا المنتج.'**
  String get stationSaleValidationInsufficientStock;

  /// No description provided for @stationSaleSubmitInsufficientStock.
  ///
  /// In ar, this message translates to:
  /// **'المخزون تغيّر أو غير كافٍ. أعد فتح الشاشة أو قلّل الكمية.'**
  String get stationSaleSubmitInsufficientStock;

  /// No description provided for @stationSaleStockAvailable.
  ///
  /// In ar, this message translates to:
  /// **'المخزون: {count}'**
  String stationSaleStockAvailable(int count);

  /// No description provided for @operationDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ العملية'**
  String get operationDateLabel;

  /// No description provided for @sellerLabel.
  ///
  /// In ar, this message translates to:
  /// **'البائع'**
  String get sellerLabel;

  /// No description provided for @totalAmountLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get totalAmountLabel;

  /// No description provided for @vehicleLoadProductsSection.
  ///
  /// In ar, this message translates to:
  /// **'المنتجات والكميات المحمّلة'**
  String get vehicleLoadProductsSection;

  /// No description provided for @vehicleLoadRowGallon.
  ///
  /// In ar, this message translates to:
  /// **'جالون'**
  String get vehicleLoadRowGallon;

  /// No description provided for @vehicleLoadRowBottle.
  ///
  /// In ar, this message translates to:
  /// **'قاروره'**
  String get vehicleLoadRowBottle;

  /// No description provided for @vehicleLoadRowCarton.
  ///
  /// In ar, this message translates to:
  /// **'ك مهدي'**
  String get vehicleLoadRowCarton;

  /// No description provided for @vehicleLoadCouponBook1.
  ///
  /// In ar, this message translates to:
  /// **'كوبون ١٢'**
  String get vehicleLoadCouponBook1;

  /// No description provided for @vehicleLoadCouponBook2.
  ///
  /// In ar, this message translates to:
  /// **'كوبون ٢٤'**
  String get vehicleLoadCouponBook2;

  /// No description provided for @vehicleLoadCouponBook3.
  ///
  /// In ar, this message translates to:
  /// **'كوبون ٥٠'**
  String get vehicleLoadCouponBook3;

  /// No description provided for @productRow.
  ///
  /// In ar, this message translates to:
  /// **'منتج {n}'**
  String productRow(int n);

  /// No description provided for @vehicleLoadInvalidRow.
  ///
  /// In ar, this message translates to:
  /// **'أكمل المنتج والكمية (رقم ≥ 1) لكل صف تستخدمه.'**
  String get vehicleLoadInvalidRow;

  /// No description provided for @vehicleLoadNeedOneLine.
  ///
  /// In ar, this message translates to:
  /// **'أضف منتجاً واحداً على الأقل مع كمية محمّلة.'**
  String get vehicleLoadNeedOneLine;

  /// No description provided for @vehicleLoadCatalogGapHint.
  ///
  /// In ar, this message translates to:
  /// **'بعض البنود غير مربوطة بمنتج في النظام. من «أسعار المنتجات» أنشئ منتجاً لكل اسم إنجليزي يظهر أدناه بنفس الحرفية.'**
  String get vehicleLoadCatalogGapHint;

  /// No description provided for @vehicleLoadNoStationStockForRow.
  ///
  /// In ar, this message translates to:
  /// **'لا يُتحقق من مخزون المحطة ولا يُخصم عند التحميل لهذا البند.'**
  String get vehicleLoadNoStationStockForRow;

  /// No description provided for @vehicleLoadInsufficientStationStock.
  ///
  /// In ar, this message translates to:
  /// **'الكمية تتجاوز مخزون المحطة لـ {product} (المتاح: {available}).'**
  String vehicleLoadInsufficientStationStock(String product, String available);

  /// No description provided for @vehicleLoadStationStockHint.
  ///
  /// In ar, this message translates to:
  /// **'يُتحقق من مخزون المحطة قبل التحميل ولا يُخصم منه.'**
  String get vehicleLoadStationStockHint;

  /// No description provided for @loadsRecorded.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل التحميلات'**
  String get loadsRecorded;

  /// No description provided for @couponProduct.
  ///
  /// In ar, this message translates to:
  /// **'دفتر كوبون'**
  String get couponProduct;

  /// No description provided for @vehicleSalesRecorded.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل مبيعات المركبة'**
  String get vehicleSalesRecorded;

  /// No description provided for @vehicleSaleChoosePlaceTitle.
  ///
  /// In ar, this message translates to:
  /// **'وجهة البيع'**
  String get vehicleSaleChoosePlaceTitle;

  /// No description provided for @vehicleSaleTapToChoosePlace.
  ///
  /// In ar, this message translates to:
  /// **'اضغط لاختيار المنزل أو المتجر'**
  String get vehicleSaleTapToChoosePlace;

  /// No description provided for @vehicleSalePlaceHome.
  ///
  /// In ar, this message translates to:
  /// **'منزل'**
  String get vehicleSalePlaceHome;

  /// No description provided for @vehicleSalePlaceStore.
  ///
  /// In ar, this message translates to:
  /// **'متجر'**
  String get vehicleSalePlaceStore;

  /// No description provided for @vehicleSaleFromHome.
  ///
  /// In ar, this message translates to:
  /// **'البيع من: منزل'**
  String get vehicleSaleFromHome;

  /// No description provided for @vehicleSaleFromStore.
  ///
  /// In ar, this message translates to:
  /// **'البيع من: متجر'**
  String get vehicleSaleFromStore;

  /// No description provided for @couponButton.
  ///
  /// In ar, this message translates to:
  /// **'كوبون'**
  String get couponButton;

  /// No description provided for @printerSettingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الطابعة'**
  String get printerSettingsTitle;

  /// No description provided for @printerStatusTitle.
  ///
  /// In ar, this message translates to:
  /// **'حالة الطابعة'**
  String get printerStatusTitle;

  /// No description provided for @printerStatusConnected.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get printerStatusConnected;

  /// No description provided for @printerStatusConnecting.
  ///
  /// In ar, this message translates to:
  /// **'جاري الاتصال'**
  String get printerStatusConnecting;

  /// No description provided for @printerStatusDisconnected.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get printerStatusDisconnected;

  /// No description provided for @printerStatusError.
  ///
  /// In ar, this message translates to:
  /// **'خطأ'**
  String get printerStatusError;

  /// No description provided for @printerNoPrinterSelected.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم اختيار طابعة'**
  String get printerNoPrinterSelected;

  /// No description provided for @printerDisconnect.
  ///
  /// In ar, this message translates to:
  /// **'قطع الاتصال'**
  String get printerDisconnect;

  /// No description provided for @printerTestPrint.
  ///
  /// In ar, this message translates to:
  /// **'طباعة تجريبية'**
  String get printerTestPrint;

  /// No description provided for @printerRegisterSaleAndPrint.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل بيع وطباعة'**
  String get printerRegisterSaleAndPrint;

  /// No description provided for @printerTestMessage.
  ///
  /// In ar, this message translates to:
  /// **'اختبار طباعة أماتيست'**
  String get printerTestMessage;

  /// No description provided for @printerPairedDevicesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطابعات المقترنة'**
  String get printerPairedDevicesTitle;

  /// No description provided for @printerNoDevicesFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طابعات مقترنة. اقترن بالطابعة من إعدادات البلوتوث ثم حدّث القائمة.'**
  String get printerNoDevicesFound;

  /// No description provided for @printerConnected.
  ///
  /// In ar, this message translates to:
  /// **'تم الاتصال بالطابعة'**
  String get printerConnected;

  /// No description provided for @printerPrintSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت الطباعة بنجاح'**
  String get printerPrintSuccess;

  /// No description provided for @printerPromptTitle.
  ///
  /// In ar, this message translates to:
  /// **'طباعة الإيصال'**
  String get printerPromptTitle;

  /// No description provided for @printerPromptSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد طباعة إيصال على الطابعة الحرارية؟'**
  String get printerPromptSubtitle;

  /// No description provided for @printerPrintReceipt.
  ///
  /// In ar, this message translates to:
  /// **'طباعة الإيصال'**
  String get printerPrintReceipt;

  /// No description provided for @printerSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get printerSkip;

  /// No description provided for @printerOpenSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الطابعة'**
  String get printerOpenSettings;

  /// No description provided for @printerSaleInvoiceTitle.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة بيع رسمية'**
  String get printerSaleInvoiceTitle;

  /// No description provided for @printerDailySummaryTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملخص مبيعات اليوم'**
  String get printerDailySummaryTitle;

  /// No description provided for @printerInventoryReportTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقرير جرد المركبة'**
  String get printerInventoryReportTitle;

  /// No description provided for @printerPaymentCash.
  ///
  /// In ar, this message translates to:
  /// **'نقدي'**
  String get printerPaymentCash;

  /// No description provided for @printerPrintDailySummary.
  ///
  /// In ar, this message translates to:
  /// **'طباعة ملخص اليوم'**
  String get printerPrintDailySummary;

  /// No description provided for @printerPrintInventoryReport.
  ///
  /// In ar, this message translates to:
  /// **'طباعة تقرير الجرد'**
  String get printerPrintInventoryReport;

  /// No description provided for @printerReceiptPreviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'معاينة نمط الفاتورة'**
  String get printerReceiptPreviewTitle;

  /// No description provided for @printerReceiptPreviewHint.
  ///
  /// In ar, this message translates to:
  /// **'معاينة تقريبية لشكل الإيصال على ورق ٥٨مم (الطباعة الفعلية من الموبايل فقط).'**
  String get printerReceiptPreviewHint;

  /// No description provided for @printerPreviewSaleTab.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة بيع'**
  String get printerPreviewSaleTab;

  /// No description provided for @printerPreviewSummaryTab.
  ///
  /// In ar, this message translates to:
  /// **'ملخص يومي'**
  String get printerPreviewSummaryTab;

  /// No description provided for @printerPreviewInventoryTab.
  ///
  /// In ar, this message translates to:
  /// **'تقرير جرد'**
  String get printerPreviewInventoryTab;

  /// No description provided for @printerPreviewSampleDriver.
  ///
  /// In ar, this message translates to:
  /// **'محمد السائق'**
  String get printerPreviewSampleDriver;

  /// No description provided for @printerPreviewSampleVehicle.
  ///
  /// In ar, this message translates to:
  /// **'١٢٣٤'**
  String get printerPreviewSampleVehicle;

  /// No description provided for @receiptStyleSettingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص نمط الطباعة'**
  String get receiptStyleSettingsTitle;

  /// No description provided for @receiptStyleSettingsHint.
  ///
  /// In ar, this message translates to:
  /// **'عدّل عناوين الفاتورة والأعمدة والتذييل لهذا النمط.'**
  String get receiptStyleSettingsHint;

  /// No description provided for @receiptStyleDriverOnlyHint.
  ///
  /// In ar, this message translates to:
  /// **'ثلاثة أنماط طباعة للسائق — اختر نمطاً للتعديل ثم فعّله للطباعة.'**
  String get receiptStyleDriverOnlyHint;

  /// No description provided for @receiptStylePattern1.
  ///
  /// In ar, this message translates to:
  /// **'النمط ١'**
  String get receiptStylePattern1;

  /// No description provided for @receiptStylePattern2.
  ///
  /// In ar, this message translates to:
  /// **'النمط ٢'**
  String get receiptStylePattern2;

  /// No description provided for @receiptStylePattern3.
  ///
  /// In ar, this message translates to:
  /// **'النمط ٣'**
  String get receiptStylePattern3;

  /// No description provided for @receiptStyleDisplayName.
  ///
  /// In ar, this message translates to:
  /// **'اسم النمط'**
  String get receiptStyleDisplayName;

  /// No description provided for @receiptStyleActivePattern.
  ///
  /// In ar, this message translates to:
  /// **'هذا النمط مفعّل للطباعة'**
  String get receiptStyleActivePattern;

  /// No description provided for @receiptStyleInactivePattern.
  ///
  /// In ar, this message translates to:
  /// **'هذا النمط غير مفعّل'**
  String get receiptStyleInactivePattern;

  /// No description provided for @receiptStyleUseForPrint.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل للطباعة'**
  String get receiptStyleUseForPrint;

  /// No description provided for @receiptStyleActivated.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل النمط للطباعة'**
  String get receiptStyleActivated;

  /// No description provided for @receiptStyleResetPatternButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة هذا النمط للافتراضي'**
  String get receiptStyleResetPatternButton;

  /// No description provided for @receiptStyleSectionHeader.
  ///
  /// In ar, this message translates to:
  /// **'العناوين'**
  String get receiptStyleSectionHeader;

  /// No description provided for @receiptStyleSectionColumns.
  ///
  /// In ar, this message translates to:
  /// **'أعمدة الجدول'**
  String get receiptStyleSectionColumns;

  /// No description provided for @receiptStyleSectionFooter.
  ///
  /// In ar, this message translates to:
  /// **'التذييل والخيارات'**
  String get receiptStyleSectionFooter;

  /// No description provided for @receiptStyleCompanyTitle.
  ///
  /// In ar, this message translates to:
  /// **'اسم الشركة على الفاتورة'**
  String get receiptStyleCompanyTitle;

  /// No description provided for @receiptStyleCompanyTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'اتركه فارغاً لاستخدام اسم التطبيق'**
  String get receiptStyleCompanyTitleHint;

  /// No description provided for @receiptStyleSaleTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان فاتورة البيع'**
  String get receiptStyleSaleTitle;

  /// No description provided for @receiptStyleSummaryTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الملخص اليومي'**
  String get receiptStyleSummaryTitle;

  /// No description provided for @receiptStyleInventoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان تقرير الجرد'**
  String get receiptStyleInventoryTitle;

  /// No description provided for @receiptStyleColItem.
  ///
  /// In ar, this message translates to:
  /// **'عمود الصنف'**
  String get receiptStyleColItem;

  /// No description provided for @receiptStyleColQty.
  ///
  /// In ar, this message translates to:
  /// **'عمود الكمية'**
  String get receiptStyleColQty;

  /// No description provided for @receiptStyleColPrice.
  ///
  /// In ar, this message translates to:
  /// **'عمود السعر'**
  String get receiptStyleColPrice;

  /// No description provided for @receiptStyleColTotal.
  ///
  /// In ar, this message translates to:
  /// **'عمود الإجمالي'**
  String get receiptStyleColTotal;

  /// No description provided for @receiptStyleRemainingTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان المخزون المتبقي'**
  String get receiptStyleRemainingTitle;

  /// No description provided for @receiptStyleSignatureLabel.
  ///
  /// In ar, this message translates to:
  /// **'سطر توقيع المستلم'**
  String get receiptStyleSignatureLabel;

  /// No description provided for @receiptStyleStampLabel.
  ///
  /// In ar, this message translates to:
  /// **'سطر ختم المحطة'**
  String get receiptStyleStampLabel;

  /// No description provided for @receiptStyleFooterNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة إضافية في التذييل'**
  String get receiptStyleFooterNote;

  /// No description provided for @receiptStyleFooterNoteHint.
  ///
  /// In ar, this message translates to:
  /// **'اختياري — مثال: شكراً لتعاملكم معنا'**
  String get receiptStyleFooterNoteHint;

  /// No description provided for @receiptStyleShowRemaining.
  ///
  /// In ar, this message translates to:
  /// **'إظهار المخزون المتبقي'**
  String get receiptStyleShowRemaining;

  /// No description provided for @receiptStyleShowSignature.
  ///
  /// In ar, this message translates to:
  /// **'إظهار توقيع المستلم'**
  String get receiptStyleShowSignature;

  /// No description provided for @receiptStyleShowStamp.
  ///
  /// In ar, this message translates to:
  /// **'إظهار ختم المحطة'**
  String get receiptStyleShowStamp;

  /// No description provided for @receiptStyleAutoCut.
  ///
  /// In ar, this message translates to:
  /// **'قص الورق تلقائياً بعد الطباعة'**
  String get receiptStyleAutoCut;

  /// No description provided for @receiptStyleSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ نمط الطباعة'**
  String get receiptStyleSave;

  /// No description provided for @receiptStyleSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ نمط الطباعة'**
  String get receiptStyleSaved;

  /// No description provided for @receiptStyleResetButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإعدادات الافتراضية'**
  String get receiptStyleResetButton;

  /// No description provided for @receiptStyleReset.
  ///
  /// In ar, this message translates to:
  /// **'تمت إعادة نمط الطباعة للوضع الافتراضي'**
  String get receiptStyleReset;

  /// No description provided for @adminDailyReportCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقرير يوم المحطة'**
  String get adminDailyReportCardTitle;

  /// No description provided for @adminDailyReportCardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'طباعة رصيد المحطة، المخزون المتبقي، ومبيعات المحطة والمركبات لليوم.'**
  String get adminDailyReportCardSubtitle;

  /// No description provided for @adminDailyReportPrintButton.
  ///
  /// In ar, this message translates to:
  /// **'طباعة تقرير اليوم'**
  String get adminDailyReportPrintButton;

  /// No description provided for @adminDailyReportTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقرير يوم المحطة'**
  String get adminDailyReportTitle;

  /// No description provided for @adminDailyReportPrintFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحضير تقرير اليوم للطباعة'**
  String get adminDailyReportPrintFailed;

  /// No description provided for @adminDailyReportCashSection.
  ///
  /// In ar, this message translates to:
  /// **'رصيد الأموال'**
  String get adminDailyReportCashSection;

  /// No description provided for @adminDailyReportBalanceSection.
  ///
  /// In ar, this message translates to:
  /// **'رصيد المحطة والمخزون'**
  String get adminDailyReportBalanceSection;

  /// No description provided for @adminDailyReportBalanceTotalUnits.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي وحدات رصيد المحطة'**
  String get adminDailyReportBalanceTotalUnits;

  /// No description provided for @adminDailyReportRemainingStationStock.
  ///
  /// In ar, this message translates to:
  /// **'مخزون متبقي في المحطة'**
  String get adminDailyReportRemainingStationStock;

  /// No description provided for @adminDailyReportRemainingOnVehicles.
  ///
  /// In ar, this message translates to:
  /// **'مخزون متبقي على المركبات'**
  String get adminDailyReportRemainingOnVehicles;

  /// No description provided for @adminDailyReportSalesSummarySection.
  ///
  /// In ar, this message translates to:
  /// **'ملخص مبيعات اليوم'**
  String get adminDailyReportSalesSummarySection;

  /// No description provided for @adminDailyReportTotalSalesToday.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المبيعات اليوم'**
  String get adminDailyReportTotalSalesToday;

  /// No description provided for @adminDailyReportStationSalesSection.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات المحطة اليوم'**
  String get adminDailyReportStationSalesSection;

  /// No description provided for @adminDailyReportVehicleSalesSection.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات المركبات اليوم'**
  String get adminDailyReportVehicleSalesSection;

  /// No description provided for @adminVehicleSalesLabel.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات المركبات'**
  String get adminVehicleSalesLabel;
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
