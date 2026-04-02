import 'package:flutter/material.dart'; //để dùng Color và ChangeNotifier
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; //Thư viện firesotre

//CLASS THEME PROVIDER
// Class này giúp quản lý trạng thái màu sắc chủ đạo của ứng dụng
class ThemeProvider extends ChangeNotifier {
  Color _themeColor = Colors.blueGrey;
  Color get themeColor => _themeColor;

  // [MỚI] Hàm tải màu từ Firestore khi người dùng đăng nhập
  Future<void> loadThemeColor(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data()?['themeColor'] != null) {
        _themeColor = Color(doc.data()!['themeColor']); // Chuyển mã số (int) ngược lại thành màu
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Lỗi tải theme: $e");
    }
  }

  // [MỚI] Cập nhật màu và đồng bộ lên Firestore ngay lập tức
  Future<void> changeThemeColor(Color color, String? userId) async {
    _themeColor = color;
    notifyListeners();

    // Nếu có userId (đã đăng nhập) thì mới lưu lên cloud
    if (userId != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'themeColor': color.value, // Lưu mã số của màu (int)
        }, SetOptions(merge: true)); // Chỉ cập nhật field này, không xóa các field khác
      } catch (e) {
        debugPrint("Lỗi lưu theme: $e");
      }
    }
  }
}

//CLASS XỬ LÝ DẤU PHẨY
// Class này giúp tự động thêm dấu phẩy ngăn cách hàng nghìn khi nhập số tiền
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Nếu ô nhập trống thì trả về trống
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 1. Xóa tất cả các ký tự không phải là số để lấy số thô
    String valueStr = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Nếu xóa xong mà rỗng thì trả về rỗng
    if (valueStr.isEmpty) return newValue.copyWith(text: '');

    // 2. Chuyển thành số
    double value = double.parse(valueStr);

    // 3. Định dạng lại thành chuỗi có dấu phẩy (theo chuẩn Mỹ en_US)
    final formatter = NumberFormat("#,###", "en_US");
    String newText = formatter.format(value);

    // 4. Trả về chuỗi mới và đặt con trỏ chuột ở cuối dòng
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}