import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; //Thư viện xác thực

//LOGIN|REGISTER SCREEN
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // [MỚI] Controller xác nhận mật khẩu

  bool _isLogin = true; //switch login & reg
  bool _isLoading = false;

  void _submitAuthForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim(); // [MỚI] Lấy giá trị xác nhận

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chưa nhập email và mật khẩu.")));
      return;
    }

    //Kiểm tra mật khẩu xác nhận khi Đăng ký
    if (!_isLogin && password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu xác nhận không khớp!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        //Login
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        //register
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      }
      // AuthWrapper tu chuyen trang khi dang nhap thanh cong
    } on FirebaseAuthException catch (e) {
     // In mã lỗi ra để biết đường sửa
      String message = "Lỗi: ${e.code} - ${e.message}";
      if (e.code == 'weak-password') message = 'Mật khẩu yếu (cần ít nhất 6 ký tự).';
      else if (e.code == 'email-already-in-use') message = 'Email này đã được sử dụng.';
      else if (e.code == 'user-not-found') message = 'Không tìm thấy tài khoản.';
      else if (e.code == 'wrong-password') message = 'Sai mật khẩu.';
      else if (e.code == 'invalid-email') message = 'Email không hợp lệ.';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet, size: 80, color: Colors.blueGrey.shade700),
                const SizedBox(height: 10),
                Text(_isLogin ? "Login" : "Register", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // --- EMAIL ---
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next, // [MỚI] Enter -> Next
                ),
                
                // --- PASSWORD ---
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: "Mật khẩu", prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                  //Nếu login thì Enter -> Done, nếu Register thì Enter -> Next
                  textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                  onSubmitted: (_) {
                    if (_isLogin) _submitAuthForm(); // Đăng nhập ngay nếu bấm Enter
                  },
                ),

                //--- CONFIRM PASSWORD (Chỉ hiện khi Đăng ký) ---
                if (!_isLogin)
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(labelText: "Xác nhận mật khẩu", prefixIcon: Icon(Icons.lock_outline)),
                    obscureText: true,
                    textInputAction: TextInputAction.done, // [MỚI] Enter -> Done
                    onSubmitted: (_) => _submitAuthForm(), // Đăng ký ngay nếu bấm Enter
                  ),

                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _submitAuthForm,
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                        child: Text(_isLogin ? "Login" : "Register"),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _confirmPasswordController.clear(); // Xóa ô xác nhận khi chuyển tab
                          });
                        },
                        child: Text(_isLogin ? "Chưa có tài khoản? Đăng ký ngay" : "Đã có tài khoản? Đăng nhập"),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}