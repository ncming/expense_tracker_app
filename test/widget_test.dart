// Test widget cho màn hình đăng nhập.
//
// Mục tiêu test này:
// 1) Đảm bảo AuthScreen render đúng các thành phần quan trọng của mode Đăng Nhập.
// 2) Phát hiện sớm lỗi UI khi refactor (đổi text, mất field, mất nút Google...).
// 3) Giữ test nhẹ, không phụ thuộc Firebase/network để chạy nhanh trong CI.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_money_no_me/auth_screen.dart';

void main() {
  // Smoke test cho giao diện đăng nhập mặc định.
  // Không test flow bấm nút ở đây, chỉ xác nhận các widget cốt lõi xuất hiện.
  testWidgets('AuthScreen shows login UI', (WidgetTester tester) async {
    // Bọc bằng MaterialApp để cung cấp Material context cho Scaffold/TextField/Button.
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    // "Đăng Nhập" xuất hiện ở cả title và label nút nên dùng findsWidgets.
    expect(find.text('Đăng Nhập'), findsWidgets);

    // Ở mode login mặc định có đúng 2 ô nhập: Email + Mật khẩu.
    expect(find.byType(TextField), findsNWidgets(2));

    // Kiểm tra các text/CTA quan trọng của màn hình.
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
  });
}
