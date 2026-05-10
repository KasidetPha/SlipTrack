import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/monthly_kind.dart';
import 'package:frontend/pages/add_expense_page.dart';
import 'package:frontend/pages/add_income_page.dart';
import 'package:frontend/pages/budget_page/budget_page.dart';
import 'package:frontend/pages/category_see_all_page.dart';
import 'package:frontend/pages/dashboard_page/dashboard_page.dart';
import 'package:frontend/pages/manage_category_page.dart';
import 'package:frontend/pages/scan_page.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/widgets/drawer/sliptrack_drawer.dart';
import 'package:frontend/widgets/filter_month_year.dart';
import 'package:frontend/widgets/home_page_widgets/expense_card.dart';
import 'package:frontend/widgets/home_page_widgets/home_header.dart';
import 'package:frontend/widgets/home_page_widgets/income_card.dart';
import 'package:frontend/widgets/home_page_widgets/items_recent.dart';
import 'package:frontend/widgets/home_page_widgets/most_category.dart';
import 'package:frontend/widgets/home_page_widgets/summary_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:frontend/providers/transaction_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  bool _hasCategoryData = false;
  final ScrollController _scrollController = ScrollController();

  AppLanguage _lang = AppLanguage.th;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void onMonthYearChanged(int month, int year) {
    ref.read(calendarFiltersProvider.notifier).state = {'month': month, 'year': year};
    setState(() {
      selectedMonth = month;
      selectedYear = year;
      _hasCategoryData = false;
    });
  }

  String getMonthName(int month) {
    return DateFormat.MMMM().format(DateTime(0, month));
  }

  Future<void> _refreshHomeAfterTransaction() async {
    final oldOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;

    ref.read(transactionControllerProvider).refreshData();
    await ref.refresh(userProfileProvider.future);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          oldOffset.clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    return Scaffold(
      drawer: profileAsync.when(
        data: (profile) => SliptrackDrawer(
          profileImage: profile.profileImage,
          displayName: profile.displayName,
          email: profile.email,
          balance: profile.balance,
          onScanReceipt: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanPage()),
            );

            if (result == true) {
              await _refreshHomeAfterTransaction();
            }
          },

          onAddIncome: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddIncomePage()),
            );

            if (result == true) {
              await _refreshHomeAfterTransaction();
            }
          },

          onAddExpense: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddExpensePage()),
            );

            if (result == true) {
              await _refreshHomeAfterTransaction();
            }
          },
          
          onBudget: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetPage())),
          onCategory: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageCategoryPage())),
          onDashboard: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardPage())),
          language: _lang,
          onLanguageChanged: (v) {
            setState(() => _lang = v); // ตอนนี้แค่ UI เปลี่ยนปุ่ม
          },
        ),
          loading: () => const Drawer(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const Drawer(
            child: Center(child: Text('Error loading profile')),
          ),
        ),
      body: RefreshIndicator(
        onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 300));

        await Future.wait([
          ref.refresh(userProfileProvider.future),

          ref.refresh(transactionsProvider((
            categoryId: null,
            month: selectedMonth,
            year: selectedYear,
            entryType: null,
          )).future),

          ref.refresh(summaryProvider(MonthlyKind.income).future),
          ref.refresh(summaryProvider(MonthlyKind.expense).future),
          ref.refresh(summaryProvider(MonthlyKind.net).future),

          ref.refresh(categoryTotalsProvider((
            month: selectedMonth,
            year: selectedYear,
          )).future),
        ]);

        if (mounted) {
          setState(() {
            _hasCategoryData = false;
          });
        }
      },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 37, 98, 235),
                      Color.fromARGB(144, 76, 52, 234)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ), 
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    HomeHeader(),
                    SizedBox(height: 24),
                    FilterMonthYear(
                      // key: ValueKey('${selectedMonth}_${selectedYear}'),
                      initialMonth: selectedMonth,
                      initialYear: selectedYear,
                      onMonthYearChanged: onMonthYearChanged,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: IncomeCard(
                            // key: ValueKey('income_$refreshCount'),
                            selectedMonth: selectedMonth,
                            selectedYear: selectedYear,
                            // refreshCount: refreshCount,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ExpenseCard(
                            // key: ValueKey('expense_$refreshCount'),
                            selectedMonth: selectedMonth,
                            selectedYear: selectedYear,
                            // refreshCount: refreshCount,
                          )
                        )
                      ],
                    ),
                    SizedBox(height: 16),
                    ref.watch(summaryProvider(MonthlyKind.net)).when(
                      data: (summary) => SummaryCard(
                        selectedMonth: selectedMonth,
                        selectedYear: selectedYear,
                        title: "Current Balance ${getMonthName(selectedMonth)} $selectedYear",
                        totalOverride: summary.thisMonth,
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator(color: Colors.white,),),
                      ),
                      error: (err, stack) => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('Error loading balace', style: TextStyle(color: Colors.white),),))
                    )
                  ]
                )
              ),
              
              const SizedBox(height: 24),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(24,0,0,24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Spending by Categories", style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold )),
                    TextButton.icon(
                      style: TextButton.styleFrom(iconAlignment: IconAlignment.end),
                      onPressed: _hasCategoryData
                          ? () async {
                              final result = await Navigator.push<Map<String, int>>(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => CategorySeeAll(
                                    selectedMonth: selectedMonth,
                                    selectedYear: selectedYear,
                                  ),
                                ),
                              );

                              if (result != null && result['month'] != null && result['year'] != null) {
                                final newMonth = result['month']!;
                                final newYear = result['year']!;

                                setState(() {
                                  selectedMonth = newMonth;
                                  selectedYear = newYear;
                                  _hasCategoryData = false;
                                });
                              }
                            }
                          : null,
                      label: Text(
                        "See All",
                        style: GoogleFonts.prompt(color: Colors.grey),
                      ),
                      icon: const Icon(
                        Icons.chevron_right_outlined,
                        color: Colors.grey,
                        size: 18,
                      ),
                    )
                  ],
                ),
              ),
              MostCategory(
                selectedMonth: selectedMonth, 
                selectedYear: selectedYear,
                onHasDataChanged: (hasData) {
                  if (_hasCategoryData != hasData) {
                    setState(() => _hasCategoryData = hasData);
                  }
                },
              ),
              
              // const SizedBox(height: 24),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(24,24,24,24),
                child: Text("Recent Transactions", style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.bold ),),
              ),
              
              // const SizedBox(height: 24),
              
              ItemsRecent(
                // key: ValueKey('recent_${selectedMonth}_$selectedYear'),
                selectedMonth: selectedMonth,
                selectedYear: selectedYear,
                // refreshCount: refreshCount,
              )
            ],
          ),
        )
      )
    );
  }
}