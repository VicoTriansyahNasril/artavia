import 'package:get/get.dart';
import 'package:artavia/page/data_transfer/data_transfer_binding.dart';
import 'package:artavia/page/data_transfer/export_screen.dart';
import 'package:artavia/page/data_transfer/import_history_screen.dart';
import 'package:artavia/page/data_transfer/import_mapping_screen.dart';
import 'package:artavia/page/data_transfer/import_review_screen.dart';
import 'package:artavia/page/backup/backup_binding.dart';
import 'package:artavia/page/backup/backup_screen.dart';
import 'package:artavia/page/backup/restore_found_screen.dart';
import 'package:artavia/page/text_size/text_size_screen.dart';
import 'package:artavia/page/text_size/text_size_binding.dart';
import 'package:artavia/page/home/home_screen.dart';
import 'package:artavia/page/home/home_binding.dart';
import 'package:artavia/page/add_transaction/add_transaction_screen.dart';
import 'package:artavia/page/add_transaction/add_transaction_binding.dart';
import 'package:artavia/page/account_management/account_management_screen.dart';
import 'package:artavia/page/account_management/add_account_screen.dart';
import 'package:artavia/page/account_management/account_management_binding.dart';
import 'package:artavia/page/calendar/calendar_screen.dart';
import 'package:artavia/page/calendar/calendar_binding.dart';
import 'package:artavia/page/transaction_detail/transaction_detail_screen.dart';
import 'package:artavia/page/category_management/category_management_screen.dart';
import 'package:artavia/page/category_management/add_category_screen.dart';
import 'package:artavia/page/category_management/category_management_binding.dart';
import 'package:artavia/page/search/search_screen.dart';
import 'package:artavia/page/search/search_binding.dart';
import 'package:artavia/page/settings/settings_screen.dart';
import 'package:artavia/page/settings/settings_binding.dart';
import 'package:artavia/page/pin/pin_screen.dart';
import 'package:artavia/page/pin/pin_binding.dart';
import 'package:artavia/page/recurring/recurring_screen.dart';
import 'package:artavia/page/recurring/recurring_form_screen.dart';
import 'package:artavia/page/recurring/recurring_binding.dart';
import 'package:artavia/page/budget/budget_screen.dart';
import 'package:artavia/page/budget/budget_binding.dart';

const homeRoute = '/';
const transferRoute = '/transfer';
const budgetRoute = '/budget';
const addTransactionRoute = '/add-transaction';
const accountManagementRoute = '/account-management';
const addAccountRoute = '/add-account';
const calendarRoute = '/calendar';
const transactionDetailRoute = '/transaction-detail';
const categoryManagementRoute = '/category-management';
const addCategoryRoute = '/add-category';
const searchRoute = '/search';
const settingsRoute = '/settings';
const pinRoute = '/pin';
const recurringRoute = '/recurring';
const recurringFormRoute = '/recurring/form';
const textSizeRoute = '/text-size';
const backupRoute = '/backup';
const restoreFoundRoute = '/backup/restore';
const exportRoute = '/data/export';
const importMappingRoute = '/data/import/mapping';
const importReviewRoute = '/data/import/review';
const importHistoryRoute = '/data/import/history';

var route = [
  GetPage(
    name: homeRoute,
    page: () => const HomeScreen(),
    binding: HomeBinding(),
  ),
  GetPage(
    name: addTransactionRoute,
    page: () => const AddTransactionScreen(),
    binding: AddTransactionBinding(),
  ),
  GetPage(
    name: accountManagementRoute,
    page: () => const AccountManagementScreen(),
    binding: AccountManagementBinding(),
  ),
  GetPage(
    name: addAccountRoute,
    page: () => const AddAccountScreen(),
    binding: AccountManagementBinding(), // reusing binding
  ),
  GetPage(
    name: calendarRoute,
    page: () => const CalendarScreen(),
    binding: CalendarBinding(),
  ),
  GetPage(
    name: transactionDetailRoute,
    page: () => const TransactionDetailScreen(),
  ),
  GetPage(
    name: categoryManagementRoute,
    page: () => const CategoryManagementScreen(),
    binding: CategoryManagementBinding(),
  ),
  GetPage(
    name: addCategoryRoute,
    page: () => const AddCategoryScreen(),
    binding: CategoryManagementBinding(),
  ),
  GetPage(
    name: searchRoute,
    page: () => const SearchScreen(),
    binding: SearchBinding(),
  ),
  GetPage(
    name: settingsRoute,
    page: () => const SettingsScreen(),
    binding: SettingsBinding(),
  ),
  GetPage(
    name: pinRoute,
    page: () => const PinScreen(),
    binding: PinBinding(),
  ),
  GetPage(
    name: recurringRoute,
    page: () => const RecurringScreen(),
    binding: RecurringBinding(),
  ),
  GetPage(
    name: recurringFormRoute,
    page: () => const RecurringFormScreen(),
    binding: RecurringBinding(),
  ),
  // Transfer is a segment of Catat (FR-006); the route opens it there.
  GetPage(
    name: transferRoute,
    page: () => const AddTransactionScreen(),
    binding: AddTransactionBinding(initialTab: 'Transfer'),
  ),
  GetPage(
    name: budgetRoute,
    page: () => const BudgetScreen(),
    binding: BudgetBinding(),
  ),
  GetPage(
    name: textSizeRoute,
    page: () => const TextSizeScreen(),
    binding: TextSizeBinding(),
  ),
  GetPage(
    name: backupRoute,
    page: () => const BackupScreen(),
    binding: BackupBinding(),
  ),
  GetPage(
    name: restoreFoundRoute,
    page: () => const RestoreFoundScreen(),
    binding: BackupBinding(),
  ),
  GetPage(
    name: exportRoute,
    page: () => const ExportScreen(),
    binding: DataTransferBinding(),
  ),
  GetPage(
    name: importMappingRoute,
    page: () => const ImportMappingScreen(),
    binding: DataTransferBinding(),
  ),
  GetPage(
    name: importReviewRoute,
    page: () => const ImportReviewScreen(),
    binding: DataTransferBinding(),
  ),
  GetPage(
    name: importHistoryRoute,
    page: () => const ImportHistoryScreen(),
    binding: ImportHistoryBinding(),
  ),
];
