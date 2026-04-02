import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //Import thư viện này để xử lý việc định dạng số (dấu phẩy) trong ô nhập liệu
import 'package:intl/intl.dart';
import 'models.dart';
import 'utils.dart';

// FORM NHẬP LIỆU THU CHI
class TransactionForm extends StatefulWidget {
  final List<CategoryItem> categories;
  // Callback trả về dữ liệu khi bấm Lưu
  final Function(double, DateTime, String, String, bool) onSubmit;
  final Transaction? existingTx; // Nếu có dữ liệu này -> Chế độ Sửa

  const TransactionForm({
    super.key,
    required this.categories,
    required this.onSubmit,
    this.existingTx,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedCategoryId; // Lưu ID thay vì Enum
  bool _isExpense = true;
  // Hàm này sẽ được gọi khi bấm nút Lưu
  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Nếu là chế độ Sửa, điền sẵn dữ liệu cũ
    if (widget.existingTx != null) {
      final tx = widget.existingTx!;
      //Định dạng lại số tiền cũ có dấu phẩy khi mở lên sửa
      final formatter = NumberFormat("#,###", "en_US");
      _amountController.text = formatter.format(tx.amount);

      _noteController.text = tx.note;
      _selectedDate = tx.date;
      _selectedCategoryId = tx.categoryId;
      _isExpense = tx.isExpense;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lọc danh mục theo loại đang chọn (Chỉ hiện Chi tiêu hoặc Thu nhập)
    final currentCategories = widget.categories
        .where((c) => c.isExpense == _isExpense)
        .toList();

    // Reset lựa chọn nếu danh mục cũ không còn khớp với loại (trừ khi đang mở form sửa)
    if (_selectedCategoryId != null &&
        currentCategories.every((c) => c.id != _selectedCategoryId)) {
      // Nếu đang trong chế độ sửa và danh mục vẫn hợp lệ với loại, giữ nguyên.
      // Nếu user chuyển tab Thu/Chi, mới reset.
      // (Logic đơn giản: nếu ID không nằm trong list hiện tại -> reset)
      _selectedCategoryId = null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Loại:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              ToggleButtons(
                isSelected: [_isExpense, !_isExpense],
                onPressed: (int index) {
                  setState(() {
                    _isExpense = index == 0;
                    _selectedCategoryId = null;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white,
                fillColor: _isExpense ? Colors.redAccent : Colors.green,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Chi tiêu'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Thu nhập'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          //Thêm inputFormatters để tự động thêm dấu phẩy
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Số tiền'),
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Chỉ cho nhập số
              ThousandsSeparatorInputFormatter(), // Tự động thêm dấu phẩy
            ],
          ),

          const SizedBox(height: 10),

          // [QUAN TRỌNG] Dropdown hiển thị danh mục lấy từ Firebase
          DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            hint: const Text("Chọn danh mục"),
            items: currentCategories.map((cat) {
              return DropdownMenuItem(
                value: cat.id,
                child: Row(
                  children: [
                    Icon(
                      IconData(cat.iconCode, fontFamily: 'MaterialIcons'),
                      color: Color(cat.colorValue),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(cat.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedCategoryId = val),
          ),

          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Ghi chú'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedDate == null
                      ? 'Chưa chọn ngày'
                      : 'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                ),
              ),
              TextButton(
                onPressed: () {
                  showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    locale: const Locale('vi', 'VN'),
                  ).then((d) {
                    if (d != null) setState(() => _selectedDate = d);
                  });
                },
                child: const Text('Chọn ngày'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (_amountController.text.isEmpty ||
                  _selectedCategoryId == null ||
                  _selectedDate == null) {
                return;
              }

              // [QUAN TRỌNG] Phải xóa hết dấu phẩy trước khi đổi sang số (1,000,000 -> 1000000)
              String cleanAmount = _amountController.text.replaceAll(',', '');
              double finalAmount = double.tryParse(cleanAmount) ?? 0;

              // Gọi hàm submit (Thêm hoặc Sửa)
              widget.onSubmit(
                finalAmount,
                _selectedDate!,
                _selectedCategoryId!,
                _noteController.text,
                _isExpense,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isExpense ? Colors.redAccent : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(widget.existingTx == null ? 'Lưu' : 'Cập nhật'),
          ),
        ],
      ),
    );
  }
}
