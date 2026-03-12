// 1. ĐỊNH NGHĨA DATA MODEL MỚI (DYNAMIC CATEGORY)

//Class đại diện cho Danh mục (Lưu trên Firebase thay vì Enum)
class CategoryItem {
  final String id;
  final String name;
  final int iconCode;   // Lưu mã số của Icon
  final int colorValue; // Lưu mã số của Màu
  final bool isExpense; // True: Chi, False: Thu

  CategoryItem({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.isExpense,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconCode': iconCode,
      'colorValue': colorValue,
      'isExpense': isExpense,
    };
  }

  factory CategoryItem.fromMap(Map<String, dynamic> map, String id) {
    return CategoryItem(
      id: id,
      name: map['name'] ?? 'Không tên',
      // Mặc định icon dấu hỏi nếu lỗi
      iconCode: map['iconCode'] ?? 0xe3d9, // 0xe3d9 là mã của Icons.help_outline
      // Mặc định màu xám nếu lỗi
      colorValue: map['colorValue'] ?? 0xFF9E9E9E, // 0xFF9E9E9E là màu xám
      isExpense: map['isExpense'] ?? true,
    );
  }
}

//Cập nhật Class Transaction để liên kết với CategoryItem qua ID
class Transaction {
  final String id;
  final double amount;
  final DateTime date;
  final String categoryId; // [QUAN TRỌNG] Lưu ID danh mục (String) thay vì Enum
  final String note;
  final bool isExpense;

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.note = '',
    required this.isExpense,
  });

  // Hàm đóng gói dữ liệu thành Map để gửi lên Firebase
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date.toIso8601String(), // Firebase lưu ngày dạng chuỗi
      'categoryId': categoryId,       // Lưu ID chuỗi
      'note': note,
      'isExpense': isExpense,
    };
  }

  // Hàm mở gói dữ liệu an toàn hơn (Chống lỗi Null)
  factory Transaction.fromMap(Map<String, dynamic> map, String id) {
    return Transaction(
      id: id,
      // dấu ? và ?? 0 (Nếu không có tiền thì coi là 0 đồng)
      amount: (map['amount'] as num? ?? 0).toDouble(),

      // Nếu không có ngày thì lấy ngày hiện tại
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),

      // Nếu không có categoryId thì để rỗng
      categoryId: map['categoryId'] ?? '',

      note: map['note'] ?? '',
      isExpense: map['isExpense'] ?? true,
    );
  }
}