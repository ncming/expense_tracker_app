import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportTab extends StatefulWidget {
  final String userId;
  const ReportTab({super.key, required this.userId});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  DateTime _selectedMonth = DateTime.now();

  // Hàm chuyển đổi tháng
  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
    });
  }

  // Hàm định dạng tiền tệ (Ví dụ: 1000000 -> 1.000.000 đ)
  String _formatCurrency(double amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ";
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán ngày đầu tiên và ngày cuối cùng của tháng được chọn
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

    return Column(
      children: [
        // --- 1. THANH CHỌN THÁNG/NĂM ---
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 30),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                'Tháng ${_selectedMonth.month} năm ${_selectedMonth.year}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 30),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // --- 2. KHU VỰC HIỂN THỊ SỐ LIỆU TỪ FIREBASE ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // Truy vấn lấy các giao dịch trong tháng được chọn
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .collection('transactions')
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
                .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu.'));
              }

              // Khởi tạo biến tính tổng
              double totalIncome = 0;
              double totalExpense = 0;

              // Lặp qua các dữ liệu lấy về để cộng dồn
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  
                  // Lấy dữ liệu (sửa lại tên trường này nếu model của bạn đặt tên khác)
                  final amount = (data['amount'] ?? 0).toDouble();
                  final isExpense = data['isExpense'] ?? true; 

                  if (isExpense) {
                    totalExpense += amount;
                  } else {
                    totalIncome += amount;
                  }
                }
              }

              final balance = totalIncome - totalExpense;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Thẻ Số Dư
                  _buildSummaryCard(
                    title: 'SỐ DƯ TỔNG CỘNG',
                    amount: balance,
                    color: Theme.of(context).colorScheme.primary,
                    icon: Icons.account_balance_wallet,
                  ),
                  const SizedBox(height: 16),
                  
                  // Thẻ Thu Nhập & Chi Tiêu
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
                ],
              );
            },
          ),
        ),
      ],
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(amount),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}