import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';
import 'package:provider/provider.dart'; // [MỚI] Thêm import provider

// Import các tab
import 'calendar_tab.dart';
import 'utilities_tab.dart';
import 'settings_tab.dart'; // Import tab cài đặt mới
import 'report_tab.dart'; // Thêm dòng này
import 'utils.dart'; // [MỚI] Đảm bảo import utils để dùng ThemeProvider

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // Quản lý Tabbar
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // GlobalKey giúp HomeScreen liên kết được với các hàm bên trong CalendarTab và UtilitiesTab
  final GlobalKey<CalendarTabState> _calendarTabKey =
      GlobalKey<CalendarTabState>();
  final GlobalKey<UtilitiesTabState> _utilitiesTabKey =
      GlobalKey<UtilitiesTabState>(); // [MỚI] Key cho tiện ích

  // [MỚI] Hàm lấy tiêu đề AppBar tương ứng với từng Tab
  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Sổ Thu Chi';
      case 1:
        return 'Báo cáo Thống kê';
      case 2:
        return 'Quản lý Danh mục';
      case 3:
        return 'Cài đặt Tài khoản';
      default:
        return 'Sổ Thu Chi';
    }
  }

  // --- Hàm khởi tạo: Chạy ngay khi mở ứng dụng ---
  @override
  void initState() {
    super.initState();
    _checkAndCreateDefaultCategories();

    // Tự động tải màu giao diện cá nhân của người dùng từ Firestore
    // Dùng Future.microtask để đảm bảo Context đã sẵn sàng
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<ThemeProvider>(context, listen: false).loadThemeColor(userId);
    });
  }

  // --- Hàm tự động tạo danh mục mẫu cho tài khoản mới ---
  void _checkAndCreateDefaultCategories() async {
    final catRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('categories');
    final snapshot = await catRef.get();

    // Chỉ tạo khi người dùng chưa có bất kỳ danh mục nào
    if (snapshot.docs.isEmpty) {
      final List<CategoryItem> defaultCategories = [
        // ---------- DANH MỤC CHI TIÊU ----------
        CategoryItem(
          id: '',
          name: 'Ăn uống',
          iconCode: Icons.fastfood.codePoint,
          colorValue: Colors.orange.toARGB32(),
          isExpense: true,
        ),
        CategoryItem(
          id: '',
          name: 'Di chuyển',
          iconCode: Icons.directions_bus.codePoint,
          colorValue: Colors.blue.toARGB32(),
          isExpense: true,
        ),
        CategoryItem(
          id: '',
          name: 'Mua sắm',
          iconCode: Icons.shopping_bag.codePoint,
          colorValue: Colors.pink.toARGB32(),
          isExpense: true,
        ),
        CategoryItem(
          id: '',
          name: 'Hóa đơn',
          iconCode: Icons.lightbulb.codePoint,
          colorValue: Colors.amber.toARGB32(),
          isExpense: true,
        ),
        CategoryItem(
          id: '',
          name: 'Sức khỏe',
          iconCode: Icons.medical_services.codePoint,
          colorValue: Colors.red.toARGB32(),
          isExpense: true,
        ),
        CategoryItem(
          id: '',
          name: 'Giải trí',
          iconCode: Icons.movie.codePoint,
          colorValue: Colors.deepPurple.toARGB32(),
          isExpense: true,
        ),
        CategoryItem(
          id: '',
          name: 'Cafe & Bạn bè',
          iconCode: Icons.local_cafe.codePoint,
          colorValue: Colors.brown.toARGB32(),
          isExpense: true,
        ),

        // ---------- DANH MỤC THU NHẬP ----------
        CategoryItem(
          id: '',
          name: 'Tiền lương',
          iconCode: Icons.attach_money.codePoint,
          colorValue: Colors.green.shade700.toARGB32(),
          isExpense: false,
        ),
        CategoryItem(
          id: '',
          name: 'Tiền thưởng',
          iconCode: Icons.card_giftcard.codePoint,
          colorValue: Colors.teal.toARGB32(),
          isExpense: false,
        ),
        CategoryItem(
          id: '',
          name: 'Đầu tư',
          iconCode: Icons.trending_up.codePoint,
          colorValue: Colors.indigo.toARGB32(),
          isExpense: false,
        ),
      ];

      // Dùng vòng lặp để đẩy toàn bộ danh sách mẫu lên Firebase
      for (var cat in defaultCategories) {
        await catRef.add(cat.toMap());
      }

      // Báo cho giao diện biết để load lại sau khi đã thêm xong
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc muốn đăng xuất không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Đóng popup
              FirebaseAuth.instance.signOut(); // Đăng xuất
            },
            child: const Text("Đăng xuất"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách các màn hình
    final List<Widget> widgetOptions = <Widget>[
      CalendarTab(key: _calendarTabKey, userId: userId), // Tab 0
      ReportTab(userId: userId), // Tab 1
      UtilitiesTab(
        key: _utilitiesTabKey,
        userId: userId,
      ), // Tab 2: Gắn key vào đây
      const SettingsTab(), // Tab 3
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(_selectedIndex),
        ), // Tiêu đề thay đổi theo Tab
        actions: [
          // Nếu đang ở Tab Lịch, hiện nút chọn tháng/năm trên thanh tiêu đề
          if (_selectedIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: 'Chọn tháng/năm',
              onPressed: () =>
                  _calendarTabKey.currentState?.showMonthYearPicker(context),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Đăng xuất",
          ),
        ],
      ),
      body: widgetOptions.elementAt(_selectedIndex),

      // Xử lý Nút (+) cho cả Tab 0 (Lịch) và Tab 2 (Tiện ích)
      floatingActionButton: _selectedIndex == 0
          ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('categories')
                  .snapshots(),
              builder: (context, snapshot) {
                return FloatingActionButton(
                  tooltip: 'Thêm thu chi mới',
                  child: const Icon(Icons.add),
                  onPressed: () {
                    if (snapshot.hasData) {
                      final categories = snapshot.data!.docs
                          .map(
                            (doc) => CategoryItem.fromMap(
                              doc.data() as Map<String, dynamic>,
                              doc.id,
                            ),
                          )
                          .toList();
                      _calendarTabKey.currentState?.showTransactionForm(
                        context,
                        categories,
                      );
                    }
                  },
                );
              },
            )
          : (_selectedIndex == 2
                ? FloatingActionButton(
                    tooltip: 'Thêm danh mục mới',
                    child: const Icon(Icons.add),
                    onPressed: () {
                      // Mở Menu chọn Thêm Chi Tiêu hay Thu Nhập
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.money_off,
                                color: Colors.red,
                              ),
                              title: const Text('Thêm Danh mục Chi tiêu'),
                              onTap: () {
                                Navigator.pop(context);
                                _utilitiesTabKey.currentState
                                    ?.addOrEditCategory(
                                      isExpense: true,
                                    ); // Gọi sang Tab Tiện ích
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.attach_money,
                                color: Colors.green,
                              ),
                              title: const Text('Thêm Danh mục Thu nhập'),
                              onTap: () {
                                Navigator.pop(context);
                                _utilitiesTabKey.currentState
                                    ?.addOrEditCategory(
                                      isExpense: false,
                                    ); // Gọi sang Tab Tiện ích
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : null), // Các tab khác không hiện nút +

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Lịch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Báo cáo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tiện ích'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
