import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart'; // Import models để sử dụng CategoryItem

class ReportTab extends StatefulWidget {
  final String userId;
  const ReportTab({super.key, required this.userId});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedYear = DateTime.now();
  bool _isAnnualView = false; // Thêm biến để chọn chế độ xem

  // Hàm chuyển đổi tháng
  void _changeMonth(int offset) {
    final now = DateTime.now();
    final newMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + offset,
      1,
    );

    // Không cho phép chọn tháng trong tương lai
    if (newMonth.year > now.year ||
        (newMonth.year == now.year && newMonth.month > now.month)) {
      return;
    }

    setState(() {
      _selectedMonth = newMonth;
    });
  }

  // Hàm chuyển đổi năm
  void _changeYear(int offset) {
    final now = DateTime.now();
    final newYear = DateTime(_selectedYear.year + offset, 1, 1);

    // Không cho phép chọn năm trong tương lai
    if (newYear.year > now.year) {
      return;
    }

    setState(() {
      _selectedYear = newYear;
    });
  }

  // Hàm định dạng tiền tệ (Ví dụ: 1000000 -> 1.000.000đ)
  String _formatCurrency(double amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- 1. TOGGLE VIEW MODE ---
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _isAnnualView = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_isAnnualView
                      ? const Color(0xFF43A047)
                      : const Color(0xFFBDBDBD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: !_isAnnualView ? 6 : 2,
                ),
                child: const Text(
                  'Theo Tháng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => setState(() => _isAnnualView = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAnnualView
                      ? const Color(0xFF1E88E5)
                      : const Color(0xFFBDBDBD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: _isAnnualView ? 6 : 2,
                ),
                child: const Text(
                  'Theo Năm',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // --- 2. THANH CHỌN THÁNG/NĂM ---
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 30),
                onPressed: () =>
                    _isAnnualView ? _changeYear(-1) : _changeMonth(-1),
              ),
              Text(
                _isAnnualView
                    ? 'Năm ${_selectedYear.year}'
                    : 'Tháng ${_selectedMonth.month} năm ${_selectedMonth.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 30),
                onPressed: () =>
                    _isAnnualView ? _changeYear(1) : _changeMonth(1),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // --- 3. KHU VỰC HIỂN THỊ SỐ LIỆU ---
        Expanded(
          child: _isAnnualView ? _buildAnnualView() : _buildMonthlyView(),
        ),
      ],
    );
  }

  Widget _buildMonthlyView() {
    // Tính toán ngày đầu tiên và ngày cuối cùng của tháng được chọn
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
      23,
      59,
      59,
    );

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('transactions')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .snapshots(),
      builder: (context, transactionSnapshot) {
        if (transactionSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (transactionSnapshot.hasError) {
          return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu.'));
        }

        // Lấy categories
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('categories')
              .snapshots(),
          builder: (context, categorySnapshot) {
            if (categorySnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (categorySnapshot.hasError) {
              return const Center(
                child: Text('Đã xảy ra lỗi khi tải danh mục.'),
              );
            }

            // Xử lý dữ liệu
            final categories = categorySnapshot.data!.docs
                .map(
                  (doc) => CategoryItem.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList();

            final categoryMap = {for (var cat in categories) cat.id: cat};

            double totalIncome = 0;
            double totalExpense = 0;
            Map<String, double> categoryExpenses = {};
            Map<String, double> categoryIncomes = {};

            if (transactionSnapshot.hasData &&
                transactionSnapshot.data!.docs.isNotEmpty) {
              for (var doc in transactionSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data['amount'] ?? 0).toDouble();
                final isExpense = data['isExpense'] ?? true;
                final categoryId = data['categoryId'] ?? '';

                if (isExpense) {
                  totalExpense += amount;
                  categoryExpenses[categoryId] =
                      (categoryExpenses[categoryId] ?? 0) + amount;
                } else {
                  totalIncome += amount;
                  categoryIncomes[categoryId] =
                      (categoryIncomes[categoryId] ?? 0) + amount;
                }
              }
            }

            final balance = totalIncome - totalExpense;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Tổng quan tháng
                _buildSummaryCard(
                  title: 'SỐ DƯ TỔNG CỘNG',
                  amount: balance,
                  color: Theme.of(context).colorScheme.primary,
                  icon: Icons.account_balance_wallet,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'THU NHẬP',
                        amount: totalIncome,
                        color: Colors.green,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'CHI TIÊU',
                        amount: totalExpense,
                        color: Colors.red,
                        icon: Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Chi Tiêu Theo Danh Mục',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...categoryExpenses.entries.map((entry) {
                  final category = categoryMap[entry.key];
                  if (category == null) return const SizedBox.shrink();
                  return _buildCategoryCard(category, entry.value, Colors.red);
                }).toList(),
                if (categoryExpenses.isEmpty)
                  const Text('Không có chi tiêu trong tháng này.'),
                const SizedBox(height: 24),
                const Text(
                  'Thu Nhập Theo Danh Mục',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...categoryIncomes.entries.map((entry) {
                  final category = categoryMap[entry.key];
                  if (category == null) return const SizedBox.shrink();
                  return _buildCategoryCard(
                    category,
                    entry.value,
                    Colors.green,
                  );
                }).toList(),
                if (categoryIncomes.isEmpty)
                  const Text('Không có thu nhập trong tháng này.'),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAnnualView() {
    final startOfYear = DateTime(_selectedYear.year, 1, 1);
    final endOfYear = DateTime(_selectedYear.year + 1, 1, 0, 23, 59, 59);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('transactions')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
          .snapshots(),
      builder: (context, transactionSnapshot) {
        if (transactionSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (transactionSnapshot.hasError) {
          return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu.'));
        }

        // Lấy categories
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('categories')
              .snapshots(),
          builder: (context, categorySnapshot) {
            if (categorySnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (categorySnapshot.hasError) {
              return const Center(
                child: Text('Đã xảy ra lỗi khi tải danh mục.'),
              );
            }

            // Xử lý dữ liệu
            final categories = categorySnapshot.data!.docs
                .map(
                  (doc) => CategoryItem.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList();

            final categoryMap = {for (var cat in categories) cat.id: cat};

            // Tính tổng cho mỗi tháng và theo danh mục
            Map<int, Map<String, double>> monthlyData = {};
            double totalIncome = 0;
            double totalExpense = 0;
            Map<String, double> categoryExpenses = {};
            Map<String, double> categoryIncomes = {};

            if (transactionSnapshot.hasData &&
                transactionSnapshot.data!.docs.isNotEmpty) {
              for (var doc in transactionSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data['amount'] ?? 0).toDouble();
                final isExpense = data['isExpense'] ?? true;
                final date = data['date'] is Timestamp
                    ? (data['date'] as Timestamp).toDate()
                    : DateTime.now();
                final month = date.month;
                final categoryId = data['categoryId'] ?? '';

                monthlyData[month] ??= {'income': 0, 'expense': 0};
                if (isExpense) {
                  monthlyData[month]!['expense'] =
                      (monthlyData[month]!['expense'] ?? 0) + amount;
                  totalExpense += amount;
                  categoryExpenses[categoryId] =
                      (categoryExpenses[categoryId] ?? 0) + amount;
                } else {
                  monthlyData[month]!['income'] =
                      (monthlyData[month]!['income'] ?? 0) + amount;
                  totalIncome += amount;
                  categoryIncomes[categoryId] =
                      (categoryIncomes[categoryId] ?? 0) + amount;
                }
              }
            }

            final balance = totalIncome - totalExpense;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Tổng quan năm
                _buildSummaryCard(
                  title: 'SỐ DƯ TỔNG CỘNG NĂM',
                  amount: balance,
                  color: Theme.of(context).colorScheme.primary,
                  icon: Icons.account_balance_wallet,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'THU NHẬP NĂM',
                        amount: totalIncome,
                        color: Colors.green,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'CHI TIÊU NĂM',
                        amount: totalExpense,
                        color: Colors.red,
                        icon: Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Chi Tiêu Theo Danh Mục (Năm)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...categoryExpenses.entries.map((entry) {
                  final category = categoryMap[entry.key];
                  if (category == null) return const SizedBox.shrink();
                  return _buildCategoryCard(category, entry.value, Colors.red);
                }).toList(),
                if (categoryExpenses.isEmpty)
                  const Text('Không có chi tiêu trong năm này.'),
                const SizedBox(height: 24),
                const Text(
                  'Thu Nhập Theo Danh Mục (Năm)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...categoryIncomes.entries.map((entry) {
                  final category = categoryMap[entry.key];
                  if (category == null) return const SizedBox.shrink();
                  return _buildCategoryCard(
                    category,
                    entry.value,
                    Colors.green,
                  );
                }).toList(),
                if (categoryIncomes.isEmpty)
                  const Text('Không có thu nhập trong năm này.'),
                const SizedBox(height: 24),
                const Text(
                  'Báo Cáo Theo Tháng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...List.generate(12, (index) {
                  final month = index + 1;
                  final data =
                      monthlyData[month] ?? {'income': 0.0, 'expense': 0.0};
                  final monthBalance = data['income']! - data['expense']!;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('Tháng $month'),
                      subtitle: Text(
                        'Thu nhập: ${_formatCurrency(data['income']!)} | Chi tiêu: ${_formatCurrency(data['expense']!)}',
                      ),
                      trailing: Text(
                        _formatCurrency(monthBalance),
                        style: TextStyle(
                          color: monthBalance >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  // Hàm tạo giao diện cho từng Thẻ báo cáo (Card)
  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Hàm tạo card cho category
  Widget _buildCategoryCard(CategoryItem category, double amount, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(category.colorValue).withOpacity(0.15),
          child: Icon(
            IconData(category.iconCode, fontFamily: 'MaterialIcons'),
            color: Color(category.colorValue),
          ),
        ),
        title: Text(category.name),
        trailing: Text(
          _formatCurrency(amount),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
