import 'package:flutter/material.dart'; //để dùng Color và ChangeNotifier
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

//CLASS THEME PROVIDER
// Class này giúp quản lý trạng thái màu sắc chủ đạo của ứng dụng
class ThemeProvider extends ChangeNotifier {
  Color _themeColor = Colors.blueGrey; //Màu mặc định
  
  Color get themeColor => _themeColor; // Getter để lấy màu hiện tại
  void changeThemeColor(Color color) {
    _themeColor = color; // Cập nhật màu mới
    notifyListeners(); // Thông báo cho UI cập nhật lại
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