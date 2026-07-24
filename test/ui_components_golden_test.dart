import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/model/expense_model.dart';
import 'package:to_do/widget/expense_summary_card.dart';
import 'package:to_do/widget/expense_tile.dart';
import 'package:to_do/utils/app_colors.dart';
import 'package:to_do/utils/app_design.dart';
import 'package:to_do/widget/glass_widgets.dart';

void main() {
  testWidgets('core liquid glass components', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final expense = Expense(
      title: 'Dinner with Alex',
      amount: 1250.50,
      date: '2026-07-20',
      type: 'Lent',
      contactName: 'Alex Morgan',
      reason: 'Weekend dinner',
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppColors.theme,
        home: Scaffold(
          body: AppBackground(
            child: SingleChildScrollView(
              child: RepaintBoundary(
                key: const Key('components'),
                child: Column(
                  children: [
                    const ExpenseSummaryCard(
                      totalBalance: 3000,
                      totalLent: 4250.50,
                      totalBorrowed: 1250.50,
                      currencySymbol: '₹',
                    ),
                    ExpenseTile(expense: expense, currencySymbol: '₹'),
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: GlassEmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'No transactions yet',
                        message: 'Tap + to add a transaction',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('components')),
      matchesGoldenFile('goldens/core_liquid_glass.png'),
    );
  });
}
