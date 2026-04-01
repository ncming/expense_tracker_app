import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// SettingsTab: Widget chính cho tab cài đặt tài khoản
// Hiển thị thông tin tài khoản và cho phép cập nhật tên hiển thị và mật khẩu
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

// _SettingsTabState: State class quản lý trạng thái của SettingsTab
// Bao gồm controllers, user data, và các dialog cho cập nhật tài khoản
class _SettingsTabState extends State<SettingsTab> {
  // user: Lấy thông tin user hiện tại từ Firebase Auth
  final user = FirebaseAuth.instance.currentUser;

  // displayNameController: Controller cho TextField nhập tên hiển thị
  final displayNameController = TextEditingController();

  @override
  void dispose() {
    // Giải phóng controller khi widget bị hủy để tránh memory leak
    displayNameController.dispose();
    super.dispose();
  }

  // _buildCheckRow: Widget helper để hiển thị trạng thái kiểm tra mật khẩu
  // Hiển thị icon check hoặc uncheck với màu tương ứng
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

  // _validatePassword: Hàm kiểm tra tính hợp lệ của mật khẩu
  // Trả về chuỗi lỗi nếu không hợp lệ, rỗng nếu hợp lệ
  String _validatePassword(String password) {
    if (password.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Mật khẩu phải chứa ít nhất một chữ cái hoa';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Mật khẩu phải chứa ít nhất một chữ cái thường';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Mật khẩu phải chứa ít nhất một chữ số';
    }
    return '';
  }

  // _showAccountSettingsDialog: Hiển thị dialog cập nhật tài khoản
  // Bao gồm form đổi tên hiển thị và đổi mật khẩu trong cùng một dialog
  void _showAccountSettingsDialog() {
    // Khởi tạo giá trị ban đầu cho tên hiển thị
    displayNameController.text = user?.displayName ?? '';

    // Controllers cho các trường mật khẩu
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // Biến trạng thái cho loading và lỗi
    bool isSavingName = false;
    bool isSavingPassword = false;
    String? nameError;
    String? passwordError;

    // Biến trạng thái cho kiểm tra mật khẩu
    bool isLengthValid = false;
    bool hasUppercase = false;
    bool hasLowercase = false;
    bool hasNumber = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Không cho phép đóng dialog bằng cách chạm bên ngoài
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) { // StatefulBuilder để cập nhật trạng thái dialog
            return AlertDialog(
              title: const Text('Cập nhật tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView( // Cho phép cuộn nếu nội dung dài
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phần đổi tên hiển thị
                    const Text('Tên hiển thị', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên hiển thị',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (nameError != null) ...[
                      const SizedBox(height: 6),
                      Text(nameError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                    const SizedBox(height: 12),
                    // Nút lưu tên hiển thị
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade700,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.blueGrey.shade900, width: 1.5),
                        ),
                      ),
                      onPressed: isSavingName
                          ? null
                          : () async {
                              // Validation tên hiển thị
                              final newName = displayNameController.text.trim();
                              if (newName.isEmpty) {
                                setStateDialog(() => nameError = 'Tên hiển thị không được để trống');
                                return;
                              }
                              if (newName.length < 3) {
                                setStateDialog(() => nameError = 'Tên hiển thị phải ít nhất 3 ký tự');
                                return;
                              }
                              // Bắt đầu lưu
                              setStateDialog(() {
                                isSavingName = true;
                                nameError = null;
                              });
                              try {
                                // Cập nhật displayName trên Firebase Auth
                                await user?.updateDisplayName(newName);
                                await user?.reload(); // Reload user data
                                setState(() {}); // Cập nhật UI chính
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi tên hiển thị thành công!'), backgroundColor: Colors.green));
                                }
                              } catch (_) {
                                setStateDialog(() => nameError = 'Lỗi khi cập nhật tên hiển thị');
                              } finally {
                                setStateDialog(() => isSavingName = false);
                              }
                            },
                      child: isSavingName
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.grey, strokeWidth: 2))
                          : const Text('Lưu tên hiển thị', style: TextStyle(color: Colors.white)),
                    ),
                    const Divider(height: 30), // Ngăn cách giữa hai phần
                    // Phần đổi mật khẩu
                    const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // Trường nhập mật khẩu hiện tại
                    TextField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu hiện tại',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Trường nhập mật khẩu mới với validation real-time
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu mới',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_reset),
                        helperText: '8 ký tự, chữ hoa, chữ thường và số',
                      ),
                      onChanged: (value) {
                        // Cập nhật trạng thái validation khi người dùng nhập
                        setStateDialog(() {
                          isLengthValid = value.length >= 8;
                          hasUppercase = value.contains(RegExp(r'[A-Z]'));
                          hasLowercase = value.contains(RegExp(r'[a-z]'));
                          hasNumber = value.contains(RegExp(r'[0-9]'));
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // Hiển thị trạng thái validation mật khẩu
                    _buildCheckRow(isLengthValid, 'Tối thiểu 8 ký tự'),
                    _buildCheckRow(hasUppercase, 'Chứa chữ hoa'),
                    _buildCheckRow(hasLowercase, 'Chứa chữ thường'),
                    _buildCheckRow(hasNumber, 'Chứa chữ số'),
                    const SizedBox(height: 8),
                    // Trường xác nhận mật khẩu mới
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle_outline),
                      ),
                    ),
                    if (passwordError != null) ...[
                      const SizedBox(height: 6),
                      Text(passwordError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                    const SizedBox(height: 8),
                    // Nút lưu mật khẩu
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade700,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.blueGrey.shade900, width: 1.5),
                        ),
                      ),
                      onPressed: isSavingPassword
                          ? null
                          : () async {
                              // Validation các trường mật khẩu
                              final oldPass = currentPasswordController.text;
                              final newPass = newPasswordController.text;
                              final confirmPass = confirmPasswordController.text;

                              if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                                setStateDialog(() => passwordError = 'Vui lòng điền đầy đủ thông tin.');
                                return;
                              }
                              if (newPass != confirmPass) {
                                setStateDialog(() => passwordError = 'Mật khẩu mới không khớp nhau.');
                                return;
                              }
                              final pwdError = _validatePassword(newPass);
                              if (pwdError.isNotEmpty) {
                                setStateDialog(() => passwordError = pwdError);
                                return;
                              }

                              // Bắt đầu lưu mật khẩu
                              setStateDialog(() {
                                isSavingPassword = true;
                                passwordError = null;
                              });
                              try {
                                // Reauthenticate trước khi đổi mật khẩu
                                final credential = EmailAuthProvider.credential(email: user?.email ?? '', password: oldPass);
                                await user?.reauthenticateWithCredential(credential);
                                await user?.updatePassword(newPass);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: Colors.green));
                                }
                              } on FirebaseAuthException catch (e) {
                                setStateDialog(() => passwordError = (e.code == 'wrong-password' || e.code == 'invalid-credential') ? 'Mật khẩu hiện tại không đúng.' : 'Lỗi hệ thống: ${e.message}');
                              } catch (_) {
                                setStateDialog(() => passwordError = 'Đã xảy ra lỗi không xác định.');
                              } finally {
                                setStateDialog(() => isSavingPassword = false);
                              }
                            },
                      child: isSavingPassword ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Lưu mật khẩu', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              // Actions của dialog: nút đóng
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple.shade700,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => Navigator.pop(ctx), // Đóng dialog
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // build: Xây dựng UI chính của SettingsTab
  // Hiển thị thông tin tài khoản trong Card với ListTile có thể tap
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tiêu đề section tài khoản
        const Text(
          'Tài khoản',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
        const SizedBox(height: 10),
        // Card chứa thông tin tài khoản
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              // ListTile hiển thị thông tin user và cho phép tap để mở dialog
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey.shade100,
                  child: const Icon(Icons.person, color: Colors.blueGrey),
                ),
                title: Text(
                  // Hiển thị displayName nếu có, ngược lại hiển thị email
                  user?.displayName?.isNotEmpty == true ? user!.displayName! : (user?.email ?? 'Chưa đăng nhập'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                // Hiển thị email ở subtitle nếu có displayName
                subtitle: user?.displayName?.isNotEmpty == true ? Text(user!.email ?? '') : null,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16), // Icon mũi tên
                onTap: _showAccountSettingsDialog, // Mở dialog khi tap
              ),
            ],
          ),
        ),
      ],
    );
  }
}
