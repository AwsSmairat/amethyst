import 'package:amethyst/core/l10n/context_l10n.dart';
import 'package:amethyst/core/widgets/expense_category_hints_section.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// شاشة المصاريف للأدمن/السوبر أدمن: تعرض التصنيفات فقط (بدون قائمة).
class ExpensesHubPage extends StatelessWidget {
  const ExpensesHubPage({
    super.key,
    required this.basePath,
  });

  /// مثال: `/admin` أو `/super-admin`.
  final String basePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.titleExpenses),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          ExpenseCategoryHintsSection(
            includeStationExpense: true,
            onCategoryTap: (String key) =>
                context.push('$basePath/expenses/report/$key'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

