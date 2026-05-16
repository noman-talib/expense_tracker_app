import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const KharchaApp());
}

// ─── Model ───────────────────────────────────────────────────────────────────

class Expense {
  final String id;
  final double amount;
  final String detail;
  final DateTime date;

  Expense({
    required this.id,
    required this.amount,
    required this.detail,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'detail': detail,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        amount: (json['amount'] as num).toDouble(),
        detail: json['detail'],
        date: DateTime.parse(json['date']),
      );
}

// ─── Storage ─────────────────────────────────────────────────────────────────

class ExpenseStorage {
  static const _key = 'expenses';

  static Future<List<Expense>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded.map((e) => Expense.fromJson(e)).toList();
  }

  static Future<void> save(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(expenses.map((e) => e.toJson()).toList()));
  }
}

// ─── App ─────────────────────────────────────────────────────────────────────

class KharchaApp extends StatelessWidget {
  const KharchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B4513),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ─── Home Screen ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List<Expense> _expenses = [];
  late TabController _tabController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final data = await ExpenseStorage.load();
    setState(() {
      _expenses = data;
      _loading = false;
    });
  }

  Future<void> _addExpense(double amount, String detail) async {
    final expense = Expense(
      id: const Uuid().v4(),
      amount: amount,
      detail: detail,
      date: DateTime.now(),
    );
    setState(() => _expenses.add(expense));
    await ExpenseStorage.save(_expenses);
  }

  Future<void> _deleteExpense(String id) async {
    setState(() => _expenses.removeWhere((e) => e.id == id));
    await ExpenseStorage.save(_expenses);
  }

  void _showAddDialog() {
    final amountCtrl = TextEditingController();
    final detailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add New Expense',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMM yyyy, EEEE').format(DateTime.now()),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Amount Field
              TextFormField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (PKR)',
                  prefixIcon: const Icon(Icons.currency_rupee,
                      color: Color(0xFF8B4513)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFF8B4513), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAF6F3),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount is required';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  if (double.parse(v) <= 0)
                    return 'Amount must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Detail Field
              TextFormField(
                controller: detailCtrl,
                decoration: InputDecoration(
                  labelText: 'Expense Details',
                  prefixIcon: const Icon(Icons.description_outlined,
                      color: Color(0xFF8B4513)),
                  hintText: 'Like: Groceries, Fuel, Food, etc...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFF8B4513), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAF6F3),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Details are required';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _addExpense(
                        double.parse(amountCtrl.text),
                        detailCtrl.text.trim(),
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add Expense',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Tracker',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Your daily expense tracker',
              style: TextStyle(color: Color(0xFFDCBEA8), fontSize: 12),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFDCBEA8),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'Daily'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Monthly'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                DailyView(expenses: _expenses, onDelete: _deleteExpense),
                MonthlyView(expenses: _expenses),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF8B4513),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Expense',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ─── Daily View ──────────────────────────────────────────────────────────────

class DailyView extends StatelessWidget {
  final List<Expense> expenses;
  final Future<void> Function(String id) onDelete;

  const DailyView({
    super.key,
    required this.expenses,
    required this.onDelete,
  });

  Map<String, List<Expense>> get _grouped {
    final Map<String, List<Expense>> map = {};
    for (final e in expenses) {
      final key = DateFormat('yyyy-MM-dd').format(e.date);
      map.putIfAbsent(key, () => []).add(e);
    }
    // Sort by date descending
    final sorted = Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    if (grouped.isEmpty) {
      return _EmptyState(
        icon: Icons.receipt_long_outlined,
        message: 'No expenses yet\nAdd one using the button below!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: grouped.length,
      itemBuilder: (ctx, i) {
        final dateKey = grouped.keys.elementAt(i);
        final dayExpenses = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);
        final total = dayExpenses.fold(0.0, (sum, e) => sum + e.amount);
        final isToday =
            dateKey == DateFormat('yyyy-MM-dd').format(DateTime.now());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day Header
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isToday ? const Color(0xFF8B4513) : const Color(0xFFA0522D),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isToday ? Icons.today : Icons.calendar_today,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isToday
                            ? 'Today — ${DateFormat('dd MMM, EEEE').format(date)}'
                            : DateFormat('dd MMM yyyy, EEEE').format(date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'PKR ${_fmt(total)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            // Expense Cards
            ...dayExpenses.map(
              (e) => _ExpenseCard(expense: e, onDelete: onDelete),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final Future<void> Function(String) onDelete;

  const _ExpenseCard({required this.expense, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text('Delete?'),
            content: Text('Do you want to delete "${expense.detail}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Yes, Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(expense.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFF5EFEC),
            child: Text(
              expense.detail.isNotEmpty ? expense.detail[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFF8B4513),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            expense.detail,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            DateFormat('hh:mm a').format(expense.date),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EFEC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'PKR ${_fmt(expense.amount)}',
              style: const TextStyle(
                color: Color(0xFF8B4513),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Monthly View ─────────────────────────────────────────────────────────────

class MonthlyView extends StatelessWidget {
  final List<Expense> expenses;

  const MonthlyView({super.key, required this.expenses});

  Map<String, List<Expense>> get _grouped {
    final Map<String, List<Expense>> map = {};
    for (final e in expenses) {
      final key = DateFormat('yyyy-MM').format(e.date);
      map.putIfAbsent(key, () => []).add(e);
    }
    final sorted = Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    if (grouped.isEmpty) {
      return _EmptyState(
        icon: Icons.bar_chart_outlined,
        message: 'No expenses found\nAdd some first!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: grouped.length,
      itemBuilder: (ctx, i) {
        final monthKey = grouped.keys.elementAt(i);
        final monthExpenses = grouped[monthKey]!;
        final date = DateTime.parse('$monthKey-01');
        final total = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
        final isCurrentMonth =
            monthKey == DateFormat('yyyy-MM').format(DateTime.now());

        // Group by day within the month
        final Map<String, List<Expense>> byDay = {};
        for (final e in monthExpenses) {
          final dayKey = DateFormat('yyyy-MM-dd').format(e.date);
          byDay.putIfAbsent(dayKey, () => []).add(e);
        }
        final sortedDays = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Header
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCurrentMonth
                      ? [const Color(0xFF8B4513), const Color(0xFFA0522D)]
                      : [const Color(0xFFBD7C5C), const Color(0xFFD4A574)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCurrentMonth
                                ? 'This month\'s expenses'
                                : DateFormat('MMMM yyyy').format(date),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          if (isCurrentMonth)
                            Text(
                              DateFormat('MMMM yyyy').format(date),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Total',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            'PKR ${_fmt(total)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatChip(
                          icon: Icons.receipt,
                          label: '${monthExpenses.length} expenses'),
                      const SizedBox(width: 8),
                      _StatChip(
                          icon: Icons.calendar_today,
                          label: '${byDay.length} days'),
                      const SizedBox(width: 8),
                      _StatChip(
                          icon: Icons.trending_down,
                          label: 'Avg PKR ${_fmt(total / byDay.length)}/day'),
                    ],
                  ),
                ],
              ),
            ),

            // Day-wise breakdown within month
            ...sortedDays.map((dayKey) {
              final dayExpenses = byDay[dayKey]!;
              final dayTotal =
                  dayExpenses.fold(0.0, (sum, e) => sum + e.amount);
              final dayDate = DateTime.parse(dayKey);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EFEC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('dd').format(dayDate),
                        style: const TextStyle(
                          color: Color(0xFF8B4513),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    title: Text(
                      DateFormat('EEEE, dd MMM').format(dayDate),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${dayExpenses.length} expenses',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    trailing: Text(
                      'PKR ${_fmt(dayTotal)}',
                      style: const TextStyle(
                        color: Color(0xFF8B4513),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    children: dayExpenses
                        .map(
                          (e) => ListTile(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            leading: const Icon(
                              Icons.arrow_right,
                              color: Color(0xFFD4A574),
                            ),
                            title: Text(e.detail,
                                style: const TextStyle(fontSize: 13)),
                            subtitle: Text(
                              DateFormat('hh:mm a').format(e.date),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[400]),
                            ),
                            trailing: Text(
                              'PKR ${_fmt(e.amount)}',
                              style: const TextStyle(
                                color: Color(0xFFA0522D),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

String _fmt(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toInt().toString();
  }
  return amount.toStringAsFixed(2);
}
