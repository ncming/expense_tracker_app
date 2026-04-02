import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// [SỬA] Không cần import auth_screen.dart nữa vì AuthWrapper ở main.dart sẽ tự lo việc chuyển trang
import 'utils.dart'; // [SỬA] Import utils.dart để sử dụng ThemeProvider 

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final displayNameController = TextEditingController();

  // Danh sách các màu để người dùng chọn làm Theme
  final List<Color> appColors = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.red,
    Colors.blueGrey,
  ];

  @override
  void dispose() {
    displayNameController.dispose();
    super.dispose();
  }

  Widget _buildCheckRow(bool ok, String text) {
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16, color: ok ? Colors.green : Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12, color: ok ? Colors.green : Colors.grey)),
      ],
    );
  }

  String _validatePassword(String password) {
    if (password.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
    if (!password.contains(RegExp(r'[A-Z]'))) return 'Mật khẩu phải chứa ít nhất một chữ cái hoa';
    if (!password.contains(RegExp(r'[a-z]'))) return 'Mật khẩu phải chứa ít nhất một chữ cái thường';
    if (!password.contains(RegExp(r'[0-9]'))) return 'Mật khẩu phải chứa ít nhất một chữ số';
    return '';
  }

  // DIALOG: CẬP NHẬT TÀI KHOẢN (Giữ nguyên logic cực tốt của bạn)
  void _showAccountSettingsDialog() {
    final currentUser = FirebaseAuth.instance.currentUser;
    displayNameController.text = currentUser?.displayName ?? '';

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool isSavingName = false;
    bool isSavingPassword = false;
    String? nameError;
    String? passwordError;

    bool isLengthValid = false;
    bool hasUppercase = false;
    bool hasLowercase = false;
    bool hasNumber = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Cập nhật tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- ĐỔI TÊN ---
                    const Text('Tên hiển thị', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: displayNameController,
                      decoration: const InputDecoration(labelText: 'Tên hiển thị', border: OutlineInputBorder()),
                    ),
                    if (nameError != null) ...[
                      const SizedBox(height: 6),
                      Text(nameError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                      onPressed: isSavingName ? null : () async {
                        final newName = displayNameController.text.trim();
                        if (newName.isEmpty) {
                          setStateDialog(() => nameError = 'Tên hiển thị không được để trống');
                          return;
                        }
                        setStateDialog(() {
                          isSavingName = true;
                          nameError = null;
                        });
                        try {
                          await currentUser?.updateDisplayName(newName);
                          await currentUser?.reload();
                          setState(() {}); // Cập nhật lại UI chính
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi tên thành công!'), backgroundColor: Colors.green));
                        } catch (_) {
                          setStateDialog(() => nameError = 'Lỗi khi cập nhật');
                        } finally {
                          setStateDialog(() => isSavingName = false);
                        }
                      },
                      child: isSavingName ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.grey, strokeWidth: 2)) : const Text('Lưu tên hiển thị'),
                    ),
                    const Divider(height: 30),
                    
                    // --- ĐỔI MẬT KHẨU ---
                    const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_outline)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mật khẩu mới', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock_reset)),
                      onChanged: (value) {
                        setStateDialog(() {
                          isLengthValid = value.length >= 8;
                          hasUppercase = value.contains(RegExp(r'[A-Z]'));
                          hasLowercase = value.contains(RegExp(r'[a-z]'));
                          hasNumber = value.contains(RegExp(r'[0-9]'));
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildCheckRow(isLengthValid, 'Tối thiểu 8 ký tự'),
                    _buildCheckRow(hasUppercase, 'Chứa chữ hoa'),
                    _buildCheckRow(hasLowercase, 'Chứa chữ thường'),
                    _buildCheckRow(hasNumber, 'Chứa chữ số'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới', border: OutlineInputBorder(), prefixIcon: Icon(Icons.check_circle_outline)),
                    ),
                    if (passwordError != null) ...[
                      const SizedBox(height: 6),
                      Text(passwordError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                      onPressed: isSavingPassword ? null : () async {
                        final oldPass = currentPasswordController.text;
                        final newPass = newPasswordController.text;
                        final confirmPass = confirmPasswordController.text;

                        if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                          setStateDialog(() => passwordError = 'Vui lòng điền đủ thông tin.');
                          return;
                        }
                        if (newPass != confirmPass) {
                          setStateDialog(() => passwordError = 'Mật khẩu không khớp.');
                          return;
                        }
                        final pwdError = _validatePassword(newPass);
                        if (pwdError.isNotEmpty) {
                          setStateDialog(() => passwordError = pwdError);
                          return;
                        }

                        setStateDialog(() { isSavingPassword = true; passwordError = null; });
                        try {
                          final credential = EmailAuthProvider.credential(email: currentUser?.email ?? '', password: oldPass);
                          await currentUser?.reauthenticateWithCredential(credential);
                          await currentUser?.updatePassword(newPass);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: Colors.green));
                        } on FirebaseAuthException catch (e) {
                          setStateDialog(() => passwordError = (e.code == 'wrong-password' || e.code == 'invalid-credential') ? 'Mật khẩu hiện tại sai.' : 'Lỗi: ${e.message}');
                        } finally {
                          setStateDialog(() => isSavingPassword = false);
                        }
                      },
                      child: isSavingPassword ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Lưu mật khẩu'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
              ],
            );
          },
        );
      },
    );
  }

  // DIALOG: CHỌN MÀU THEME
  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn màu giao diện'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: appColors.map((color) {
            return GestureDetector(
              onTap: () {
                // [SỬA] Gọi hàm đổi màu thực tế từ ThemeProvider
                Provider.of<ThemeProvider>(context, listen: false).changeThemeColor(color);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // DIALOG: XÓA DỮ LIỆU
  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa toàn bộ dữ liệu?', style: TextStyle(color: Colors.red)),
        content: const Text('Hành động này sẽ xóa vĩnh viễn tất cả các bản ghi thu chi và không thể khôi phục. Bạn có chắc chắn không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx); // Đóng hộp thoại
              
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                try {
                  // Gọi lệnh xóa các subcollection như đã bàn (ví dụ xóa 'categories')
                  final categoriesRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('categories');
                  final snapshots = await categoriesRef.get();
                  final batch = FirebaseFirestore.instance.batch();
                  for (var doc in snapshots.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa sạch dữ liệu thu chi!')));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
                }
              }
            },
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  // DIALOG: THÔNG TIN ỨNG DỤNG
  void _showAppInfoDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Sổ Thu Chi',
      applicationVersion: 'Phiên bản 1.0.0',
      applicationIcon: const Icon(Icons.account_balance_wallet, size: 50, color: Colors.blueGrey),
      children: const [
        Text('Ứng dụng quản lý thu chi cá nhân an toàn và bảo mật.\n\nPhát triển bởi: Nhóm 8.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Luôn lấy currentUser mới nhất mỗi khi build lại giao diện
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // [SỬA] Đã mở khóa: Lấy màu theme hiện tại để làm điểm nhấn nhẹ cho các icon
    final currentThemeColor = Provider.of<ThemeProvider>(context).themeColor;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- 1. TÀI KHOẢN ---
        Text('Tài khoản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: currentThemeColor)),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: currentThemeColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: currentThemeColor)),
            title: Text(
              currentUser?.displayName?.isNotEmpty == true ? currentUser!.displayName! : (currentUser?.email ?? 'Chưa đăng nhập'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: currentUser?.displayName?.isNotEmpty == true ? Text(currentUser!.email ?? '') : null,
            trailing: const Icon(Icons.edit, size: 20),
            onTap: _showAccountSettingsDialog,
          ),
        ),
        const SizedBox(height: 24),

        // --- 2. CÀI ĐẶT ỨNG DỤNG ---
        Text('Cài đặt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: currentThemeColor)),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.color_lens, color: Colors.orange),
                title: const Text('Đổi màu giao diện'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showThemeDialog,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Xóa toàn bộ dữ liệu'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showDeleteDataDialog,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.blue),
                title: const Text('Thông tin ứng dụng'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showAppInfoDialog,
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // --- 3. ĐĂNG XUẤT ---
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            // [SỬA] Đã loại bỏ code chuyển trang thừa. 
            // Nhờ AuthWrapper, chỉ cần gọi hàm này là App tự biết đường đẩy về Login
            await FirebaseAuth.instance.signOut();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}