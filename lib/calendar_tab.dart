import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'models.dart';
import 'transaction_form.dart';

class CalendarTab extends StatefulWidget {
  final String userId;
  // Nhận hàm mở tháng/năm và thêm/sửa từ HomeScreen nếu cần, 
  // hoặc tự quản lý ở đây. Để độc lập, mình sẽ tự quản lý ở đây.
  const CalendarTab({super.key, required this.userId});

  @override
  State<CalendarTab> createState() => CalendarTabState();
}

// Bỏ chữ _ ở State để file khác (HomeScreen) có thể truy cập được các hàm bên trong
class CalendarTabState extends State<CalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  void _addNewTransaction(double amount, DateTime chosenDate, String categoryId, String note, bool isExpense) {
    final newTx = Transaction(id: '', amount: amount, date: chosenDate, categoryId: categoryId, note: note, isExpense: isExpense);
    FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('transactions').add(newTx.toMap());
    setState(() { _selectedDay = chosenDate; _focusedDay = chosenDate; });
  }

  void _updateTransaction(String txId, double amount, DateTime chosenDate, String categoryId, String note, bool isExpense) {
    FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('transactions').doc(txId)
        .update({'amount': amount, 'date': Timestamp.fromDate(chosenDate), 'categoryId': categoryId, 'note': note, 'isExpense': isExpense});
    setState(() { _selectedDay = chosenDate; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật giao dịch!')));
  }

  void _deleteTransaction(String id) {
    FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('transactions').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa!')));
  }

  // Hàm này sẽ được gọi từ Nút "+" ở AppBar của HomeScreen
  void showTransactionForm(BuildContext ctx, List<CategoryItem> categories, {Transaction? existingTx}) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: TransactionForm(
          categories: categories,
          existingTx: existingTx,
          onSubmit: (amount, date, catId, note, isExpense) {
            if (existingTx == null) _addNewTransaction(amount, date, catId, note, isExpense);
            else _updateTransaction(existingTx.id, amount, date, catId, note, isExpense);
          },
        ),
      ),
    );
  }

  // Hàm này được gọi khi bấm nút Lịch trên AppBar
  void showMonthYearPicker(BuildContext context) {
    showDatePicker(context: context, initialDate: _focusedDay, firstDate: DateTime(2020), lastDate: DateTime.now(), locale: const Locale('vi', 'VN'), initialDatePickerMode: DatePickerMode.year).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() { _focusedDay = pickedDate; _selectedDay = pickedDate; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Lồng 2 StreamBuilder: Lấy Categories -> Lấy Transactions
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('categories').snapshots(),
      builder: (context, catSnapshot) {
        if (!catSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        final categories = catSnapshot.data!.docs.map((doc) => CategoryItem.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
        final categoryMap = {for (var item in categories) item.id: item};

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('transactions').snapshots(),
          builder: (context, txSnapshot) {
            if (txSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final allTransactions = txSnapshot.data!.docs.map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
            final selectedTransactions = allTransactions.where((tx) => isSameDay(tx.date, _selectedDay)).toList();

            double dailyIncome = 0; double dailyExpense = 0;
            for (var tx in selectedTransactions) { if (tx.isExpense) dailyExpense += tx.amount; else dailyIncome += tx.amount; }
            double dailyTotal = dailyIncome - dailyExpense;

            return Column(
              children: [
                TableCalendar(firstDay: DateTime(2020), lastDay: DateTime(2030), focusedDay: _focusedDay, currentDay: DateTime.now(), locale: 'vi_VN', calendarFormat: isLandscape ? CalendarFormat.twoWeeks : CalendarFormat.month, startingDayOfWeek: StartingDayOfWeek.monday, headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true), onHeaderTapped: (_) => showMonthYearPicker(context), calendarStyle: const CalendarStyle(selectedDecoration: BoxDecoration(color: Colors.blueGrey, shape: BoxShape.circle), todayDecoration: BoxDecoration(color: Colors.blueGrey, shape: BoxShape.circle), markerDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle)), selectedDayPredicate: (day) => isSameDay(_selectedDay, day), onDaySelected: (s, f) => setState(() { _selectedDay = s; _focusedDay = f; }), eventLoader: (day) => allTransactions.where((tx) => isSameDay(tx.date, day)).toList()),
                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), color: Colors.white, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(children: [const Text('Thu nhập', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)), Text(NumberFormat.compact(locale: 'vi').format(dailyIncome), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]), Column(children: [const Text('Chi tiêu', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), Text(NumberFormat.compact(locale: 'vi').format(dailyExpense), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]), Column(children: [const Text('Tổng kết', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)), Text(NumberFormat.compact(locale: 'vi').format(dailyTotal), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: dailyTotal >= 0 ? Colors.blue : Colors.red))])])),
                const Divider(height: 1, thickness: 1),
                Expanded(child: selectedTransactions.isEmpty ? Center(child: Text('Không có chi thu nào\nvào ngày ${DateFormat('dd/MM').format(_selectedDay)}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16))) : ListView.builder(itemCount: selectedTransactions.length, itemBuilder: (ctx, index) { final tx = selectedTransactions[index]; final cat = categoryMap[tx.categoryId]; return Dismissible(key: ValueKey(tx.id), background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10), child: const Icon(Icons.delete, color: Colors.white)), direction: DismissDirection.endToStart, onDismissed: (direction) => _deleteTransaction(tx.id), child: Card(elevation: 2, margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10), child: ListTile(leading: CircleAvatar(radius: 25, backgroundColor: (cat != null ? Color(cat.colorValue) : Colors.grey).withOpacity(0.2), child: Icon(cat != null ? IconData(cat.iconCode, fontFamily: 'MaterialIcons') : Icons.help, color: cat != null ? Color(cat.colorValue) : Colors.grey)), title: Text(cat?.name ?? 'Không xác định', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: tx.note.isNotEmpty ? Text(tx.note) : null, trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text('${tx.isExpense ? '-' : '+'}${NumberFormat.currency(locale: 'vi', symbol: 'đ', decimalDigits: 0).format(tx.amount)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: tx.isExpense ? Colors.red : Colors.green)), IconButton(icon: const Icon(Icons.edit), color: Colors.grey, iconSize: 20, onPressed: () => showTransactionForm(context, categories, existingTx: tx))])))); })),
              ],
            );
          },
        );
      }
    );
  }
}