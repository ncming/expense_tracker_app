import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final user = FirebaseAuth.instance.currentUser;

  // --- HÀM HIỂN THỊ POPUP ĐỔI MẬT KHẨU TRỰC TIẾP ---
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStatePopup) {
          return AlertDialog(
            title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null) ...[
                    Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu hiện tại',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu mới',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_reset),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  final currentPass = currentPasswordController.text;
                  final newPass = newPasswordController.text;
                  final confirmPass = confirmPasswordController.text;

                  if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                    setStatePopup(() => errorMessage = "Vui lòng nhập đầy đủ thông tin.");
                    return;
                  }
                  if (newPass != confirmPass) {
                    setStatePopup(() => errorMessage = "Mật khẩu mới không khớp nhau.");
                    return;
                  }
                  if (newPass.length < 6) {
                    setStatePopup(() => errorMessage = "Mật khẩu mới phải từ 6 ký tự trở lên.");
                    return;
                  }

                  setStatePopup(() {
                    isLoading = true;
                    errorMessage = null;
                  });

                  try {
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: user!.email!,
                      password: currentPass,
                    );
                    await user!.reauthenticateWithCredential(credential);
                    await user!.updatePassword(newPass);

                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đổi mật khẩu thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    setStatePopup(() {
                      isLoading = false;
                      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                        errorMessage = "Mật khẩu hiện tại không đúng.";
                      } else {
                        errorMessage = "Lỗi hệ thống: ${e.message}";
                      }
                    });
                  } catch (e) {
                    setStatePopup(() {
                      isLoading = false;
                      errorMessage = "Đã xảy ra lỗi không xác định.";
                    });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Cập nhật', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- CHỈ CÒN LẠI PHẦN THÔNG TIN TÀI KHOẢN ---
        const Text(
          'Tài khoản',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey.shade100,
                  child: const Icon(Icons.person, color: Colors.blueGrey),
                ),
                title: Text(user?.email ?? 'Chưa đăng nhập', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_reset, color: Colors.blue),
                title: const Text('Đổi mật khẩu'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showChangePasswordDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }
}