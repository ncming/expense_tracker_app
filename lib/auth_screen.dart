import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; //Thư viện xác thực
import 'package:google_sign_in/google_sign_in.dart';

//LOGIN|REGISTER SCREEN
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController(); //Controller xác nhận mật khẩu

  bool _isLogin = true; //switch login & reg
  bool _isLoading = false;
  bool _obscurePassword = true; //Ẩn hiện mật khẩu
  bool _obscureConfirmPassword = true;
  // Hàm này sẽ được gọi khi bấm nút Login/Register
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // T-Kiểm tra định dạng email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // T-Kiểm tra độ mạnh mật khẩu
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

  void _submitAuthForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // T-Kiểm tra input không để trống
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng điền đầy đủ email và mật khẩu."),
        ),
      );
      return;
    }

    // T-Kiểm tra định dạng email
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email không hợp lệ. Ví dụ: user@example.com'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // T-Kiểm tra độ mạnh mật khẩu khi đăng ký
    if (!_isLogin) {
      final passwordError = _validatePassword(password);
      if (passwordError.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(passwordError),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // T-Kiểm tra mật khẩu xác nhận
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mật khẩu xác nhận không khớp!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // T-Login
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // T-Register
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      // AuthWrapper tự chuyển trang khi đăng nhập thành công
    } on FirebaseAuthException catch (e) {
      // T-Xử lý lỗi bảo mật từ Firebase
      String message = "Lỗi: ${e.code}";
      if (e.code == 'weak-password') {
        message = 'Mật khẩu yếu (cần ít nhất 6 ký tự).';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email này đã được sử dụng.';
      } else if (e.code == 'user-not-found') {
        message = 'Không tìm thấy tài khoản.';
      } else if (e.code == 'wrong-password') {
        message = 'Sai mật khẩu.';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ.';
      } else if (e.code == 'too-many-requests') {
        message = 'Quá nhiều lần thử. Vui lòng thử lại sau.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Chức năng này hiện không khả dụng.';
      } else if (e.code == 'invalid-credential') {
        message = 'Thông tin xác thực không hợp lệ.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: Không thể kết nối. Vui lòng kiểm tra mạng.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        // T-Xóa hay bảo vệ dữ liệu nhạy cảm
        if (_isLogin) {
          _passwordController.clear();
        }
      }
    }
  }

  //Hàm gửi mail khôi phục mật khẩu
  void _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập email hợp lệ để đặt lại mật khẩu."),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Email đặt lại mật khẩu đã được gửi. Vui lòng kiểm tra hộp thư của bạn.",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi: Không thể gửi email khôi phục."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Đăng nhập bằng tài khoản Google
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn đã hủy đăng nhập Google.')),
          );
        }
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập Google thất bại: ${e.message ?? e.code}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on PlatformException catch (e) {
      var message = 'Đăng nhập Google thất bại: ${e.message ?? e.code}';

      // ApiException 10 thường do thiếu SHA hoặc google-services.json chưa đúng package.
      if ((e.message ?? '').contains('ApiException: 10')) {
        message =
            'Google Sign-In lỗi cấu hình (ApiException: 10). Kiểm tra SHA-1/SHA-256 và tải lại google-services.json.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể đăng nhập Google: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //Bọc GestureDetector để ẩn bàn phím khi chạm ra ngoài
    return GestureDetector(
      onTap: () =>
          FocusScope.of(context).unfocus(), // Chạm ra ngoài để ẩn bàn phím
      child: Scaffold(
        backgroundColor: Colors.blueGrey,
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo3.PNG',
                    fit: BoxFit.contain,
                    height: 80,
                    width: 80,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isLogin ? "Đăng Nhập" : "Đăng Ký",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- EMAIL ---
                  TextField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email),
                      helperText: "Nhập email hợp lệ (ví dụ: user@example.com)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // --- PASSWORD ---
                  TextField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      helperText: !_isLogin
                          ? 'Tối thiểu 8 ký tự, chứa chữ hoa, chữ thường & số'
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: _isLogin
                        ? TextInputAction.done
                        : TextInputAction.next,
                    onChanged: (_) =>
                        setState(() {}), // Cập nhật yêu cầu mật khẩu khi nhập
                    onSubmitted: (_) {
                      if (_isLogin) _submitAuthForm();
                    },
                  ),
                  const SizedBox(height: 16),

                  //Nút quên mật khẩu chỉ hiển thị khi đang ở chế độ đăng nhập
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: Text(
                          "Quên mật khẩu?",
                          style: TextStyle(
                            color: Colors.blueGrey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // --- CONFIRM PASSWORD (Chỉ hiện khi Đăng ký) ---
                  if (!_isLogin) ...[
                    TextField(
                      controller: _confirmPasswordController,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: "Xác nhận mật khẩu",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submitAuthForm(),
                    ),
                    const SizedBox(height: 12),
                    // T-Hiển thị yêu cầu mật khẩu khi đang đăng ký
                    _buildPasswordRequirements(),
                    const SizedBox(height: 16),
                  ],

                  // --- BUTTON & LOADING ---
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _submitAuthForm,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: Colors.blueGrey.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(
                            _isLogin ? Icons.login : Icons.app_registration,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isLogin ? "Đăng Nhập" : "Đăng Ký",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _confirmPasswordController.clear();
                              _passwordController.clear();
                            });
                          },
                          child: Text(
                            _isLogin
                                ? "Chưa có tài khoản? Đăng ký ngay"
                                : "Đã có tài khoản? Đăng nhập",
                            style: TextStyle(color: Colors.blueGrey.shade700),
                          ),
                        ),
                        if (_isLogin) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  'hoặc',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade700,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              side: BorderSide(color: Colors.blueGrey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: const Text(
                              'Tiếp tục với Google',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // T-Widget hiển thị yêu cầu mật khẩu
  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;
    final hasMinLength = password.length >= 8;
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yêu cầu mật khẩu:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          _buildRequirement('Tối thiểu 8 ký tự', hasMinLength),
          _buildRequirement('Chữ cái hoa (A-Z)', hasUpperCase),
          _buildRequirement('Chữ cái thường (a-z)', hasLowerCase),
          _buildRequirement('Chữ số (0-9)', hasDigit),
        ],
      ),
    );
  }

  // T-Requirement item
  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMet ? Colors.green : Colors.transparent,
              border: Border.all(
                color: isMet ? Colors.green : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: isMet
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.grey,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
