import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart'; // Import provider để quản lý state

//Import thư viện Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; //Thư viện xác thực

// Import các file vừa chia
import 'auth_screen.dart';
import 'home_screen.dart';
import 'utils.dart'; // Import utils để sử dụng ThemeProvider

void main() async {
  //Đảm bảo Flutter Binding được khởi tạo trước khi gọi code bất đồng bộ
  WidgetsFlutterBinding.ensureInitialized();

  //Khởi động Firebase
  await Firebase.initializeApp();

  // Phải dùng .then() vì đây là hàm bất đồng bộ
  initializeDateFormatting('vi_VN', null).then((_) {
    // [SỬA] Bọc MyApp bằng ChangeNotifierProvider để truyền ThemeProvider đi toàn app
    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: const MyApp(),
      ),
    );
  });
}

//BỘ ĐIỀU HƯỚNG VÀ XÁC THỰC
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // [MỚI] Lấy màu sắc hiện tại từ ThemeProvider
    final themeColor = Provider.of<ThemeProvider>(context).themeColor;

    return MaterialApp(
      debugShowCheckedModeBanner: false, // Tắt banner debug
      title: 'Sổ Thu Chi',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeColor,
          brightness: Brightness.light,
        ),
        //Pha màu chủ đạo vào nền trắng để tạo lớp nền đặc (solid)
        scaffoldBackgroundColor: Color.alphaBlend(
          themeColor.withValues(alpha: 0.08),
          Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('vi', 'VN')],

      //Bộ lọc không vào thẳng Home nữa
      home: const AuthWrapper(),
    );
  }
}

//Widget Check login
//login: to MyHomePage
//nuh uh: AuthScreen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), //trạng thái đăng nhập
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const MyHomePage(); //User -> HomePage
        }
        return const AuthScreen();
      },
    );
  }
}
