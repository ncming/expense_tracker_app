import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';

import 'models.dart';
// Import các tab 
import 'calendar_tab.dart';
import 'utilities_tab.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // Quản lý Tabbar
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // GlobalKey giúp HomeScreen liên kết được với các hàm bên trong CalendarTab và UtilitiesTab
  final GlobalKey<CalendarTabState> _calendarTabKey = GlobalKey<CalendarTabState>();
  final GlobalKey<UtilitiesTabState> _utilitiesTabKey = GlobalKey<UtilitiesTabState>(); // [MỚI] Key cho tiện ích

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc muốn đăng xuất không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Đóng popup
              FirebaseAuth.instance.signOut(); // Đăng xuất
            },
            child: const Text("Đăng xuất"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách các màn hình
    final List<Widget> widgetOptions = <Widget>[
      CalendarTab(key: _calendarTabKey, userId: userId), // Tab 0
      const Center(child: Text('Màn hình Báo cáo')),     // Tab 1
      UtilitiesTab(key: _utilitiesTabKey, userId: userId), // Tab 2: Gắn key vào đây
      const Center(child: Text('Màn hình Cài đặt')),     // Tab 3
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 2 ? 'Quản lý Danh mục' : 'Sổ Thu Chi'),
        actions: [
          // Nếu đang ở Tab Lịch, hiện nút chọn tháng/năm trên thanh tiêu đề
          if (_selectedIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: 'Chọn tháng/năm',
              onPressed: () => _calendarTabKey.currentState?.showMonthYearPicker(context),
            ),
          ],
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: "Đăng xuất")
        ],
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      
      // Xử lý Nút (+) cho cả Tab 0 (Lịch) và Tab 2 (Tiện ích)
      floatingActionButton: _selectedIndex == 0
        ? StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('categories').snapshots(),
            builder: (context, snapshot) {
              return FloatingActionButton(
                tooltip: 'Thêm thu chi mới',
                child: const Icon(Icons.add),
                onPressed: () {
                  if(snapshot.hasData) {
                    final categories = snapshot.data!.docs.map((doc) => CategoryItem.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
                    _calendarTabKey.currentState?.showTransactionForm(context, categories);
                  }
                },
              );
            }
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
                          leading: const Icon(Icons.money_off, color: Colors.red), 
                          title: const Text('Thêm Danh mục Chi tiêu'), 
                          onTap: () { 
                            Navigator.pop(context); 
                            _utilitiesTabKey.currentState?.addOrEditCategory(isExpense: true); // Gọi sang Tab Tiện ích
                          }
                        ),
                        ListTile(
                          leading: const Icon(Icons.attach_money, color: Colors.green), 
                          title: const Text('Thêm Danh mục Thu nhập'), 
                          onTap: () { 
                            Navigator.pop(context); 
                            _utilitiesTabKey.currentState?.addOrEditCategory(isExpense: false); // Gọi sang Tab Tiện ích
                          }
                        ),
                      ],
                    )
                  );
                },
              )
            : null), // Các tab khác không hiện nút +

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Lịch'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Báo cáo'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tiện ích'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}