import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction; //Tránh trùng với Transaction trên firebase
import 'package:firebase_auth/firebase_auth.dart';

import 'models.dart';
import 'transaction_form.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _selectedIndex = 0; //Để quản lý Tabbar

  //Lấy ID thật của người dùng đang đăng nhập (với null safety)
  late final String userId;

  // Danh sách Icon có sẵn để chọn khi tạo danh mục
  final List<IconData> _availableIcons = [
    Icons.fastfood, Icons.shopping_bag, Icons.home, Icons.directions_bus,
    Icons.medical_services, Icons.school, Icons.sports_esports, Icons.pets,
    Icons.card_giftcard, Icons.attach_money, Icons.work, Icons.savings,
    Icons.build, Icons.local_cafe, Icons.flight, Icons.phone_android,
    Icons.shopping_cart, Icons.fitness_center, Icons.local_hospital, Icons.movie,
    Icons.checkroom, Icons.face, Icons.local_bar, Icons.lightbulb, Icons.water_drop
  ];

  // Danh sách Màu có sẵn
  final List<Color> _availableColors = [
    Colors.red, Colors.orange, Colors.amber, Colors.green, Colors.teal,
    Colors.blue, Colors.indigo, Colors.purple, Colors.pink, Colors.brown, Colors.grey, Colors.black,
    Colors.cyan, Colors.lime, Colors.deepPurple, Colors.blueGrey
  ];

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      // Nếu không có currentUser, đăng xuất và quay lại Auth Screen
      Future.microtask(() {
        FirebaseAuth.instance.signOut();
      });
      return;
    }
    _checkAndCreateDefaultCategories();
  }

  //Tự động tạo danh mục mẫu nếu database trống
  void _checkAndCreateDefaultCategories() async {
    try {
      debugPrint('[HomeScreen] Kiểm tra danh mục mặc định...');
      final catRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('categories');
      final snapshot = await catRef.get();

      if (snapshot.docs.isEmpty) {
        debugPrint('[HomeScreen] Database trống, tạo danh mục mặc định...');
        // 1. Nhóm chi tiêu (chi)
        await catRef.add(CategoryItem(id: '', name: 'Ăn uống', iconCode: Icons.fastfood.codePoint, colorValue: Colors.orange.value, isExpense: true).toMap());
        await catRef.add(CategoryItem(id: '', name: 'Chi tiêu hàng ngày', iconCode: Icons.shopping_cart.codePoint, colorValue: Colors.cyan.value, isExpense: true).toMap());
        await catRef.add(CategoryItem(id: '', name: 'Quần áo', iconCode: Icons.checkroom.codePoint, colorValue: Colors.pink.value, isExpense: true).toMap());
        await catRef.add(CategoryItem(id: '', name: 'Mỹ phẩm', iconCode: Icons.face.codePoint, colorValue: Colors.purpleAccent.value, isExpense: true).toMap());
        await catRef.add(CategoryItem(id: '', name: 'Phí giao lưu', iconCode: Icons.local_bar.codePoint, colorValue: Colors.lime.shade800.value, isExpense: true).toMap());
        await catRef.add(CategoryItem(id: '', name: 'Y tế', iconCode: Icons.medical_services.codePoint, colorValue: Colors.red.value, isExpense: true).toMap());
        await catRef.add(CategoryItem(id: '', name: 'Giáo dục', iconCode: Icons.school.codePoint, colorValue: Colors.blue.shade900.value, isExpense: true).toMap());
        await catRef.add(CategoryItem(id: '', name: 'Tiền điện nước', iconCode: Icons.lightbulb.codePoint, colorValue: Colors.amber.shade800.value, isExpense: true).toMap());
        await catRef.add(CategoryItem(id: '', name: 'Phí liên lạc', iconCode: Icons.phone_android.codePoint, colorValue: Colors.indigo.value, isExpense: true).toMap());
        await catRef.add(CategoryItem(id: '', name: 'Tiền nhà', iconCode: Icons.home.codePoint, colorValue: Colors.brown.value, isExpense: true).toMap());
        await catRef.add(CategoryItem(id: '', name: 'Di chuyển', iconCode: Icons.directions_bus.codePoint, colorValue: Colors.blue.value, isExpense: true).toMap());

        // 2. Nhóm thu nhập (thu)
        await catRef.add(CategoryItem(id: '', name: 'Tiền lương', iconCode: Icons.attach_money.codePoint, colorValue: Colors.green.shade800.value, isExpense: false).toMap());
        await catRef.add(CategoryItem(id: '', name: 'Tiền phụ cấp', iconCode: Icons.account_balance_wallet.codePoint, colorValue: Colors.lightGreen.value, isExpense: false).toMap());
        await catRef.add(CategoryItem(id: '', name: 'Tiền thưởng', iconCode: Icons.card_giftcard.codePoint, colorValue: Colors.amber.value, isExpense: false).toMap());
        await catRef.add(CategoryItem(id: '', name: 'Đầu tư', iconCode: Icons.trending_up.codePoint, colorValue: Colors.deepPurple.value, isExpense: false).toMap());
        await catRef.add(CategoryItem(id: '', name: 'Thu nhập phụ', iconCode: Icons.monetization_on.codePoint, colorValue: Colors.teal.value, isExpense: false).toMap());
        await catRef.add(CategoryItem(id: '', name: 'Thu nhập tạm thời', iconCode: Icons.hourglass_bottom.codePoint, colorValue: Colors.blueGrey.value, isExpense: false).toMap());
        debugPrint('[HomeScreen] Đã tạo xong danh mục mặc định');
      } else {
        debugPrint('[HomeScreen] Danh mục đã tồn tại: ${snapshot.docs.length} items');
      }
    } catch (e) {
      debugPrint('[HomeScreen] Lỗi tạo danh mục mặc định: $e');
    }
  }

  //Cập nhật hàm thêm: Gửi dữ liệu lên Firebase
  void _addNewTransaction(double amount, DateTime chosenDate, String categoryId, String note, bool isExpense) {
    try {
      debugPrint('[HomeScreen] Thêm giao dịch: amount=$amount, date=$chosenDate, category=$categoryId, isExpense=$isExpense');
      final newTx = Transaction(
        id: '',
        amount: amount,
        date: chosenDate,
        categoryId: categoryId, // Lưu ID chuỗi
        note: note,
        isExpense: isExpense,
      );

      // Gửi lên Cloud Firestore
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .add(newTx.toMap());

      // Cập nhật giao diện lịch
      setState(() {
        _selectedDay = chosenDate;
        _focusedDay = chosenDate;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm giao dịch!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
      debugPrint('[HomeScreen] Lỗi thêm giao dịch: $e');
    }
  }

  //Hàm cập nhật giao dịch 
  void _updateTransaction(String txId, double amount, DateTime chosenDate, String categoryId, String note, bool isExpense) {
    try {
      debugPrint('[HomeScreen] Cập nhật giao dịch: txId=$txId, amount=$amount, date=$chosenDate');
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(txId)
          .update({
            'amount': amount,
            'date': chosenDate.toIso8601String(),
            'categoryId': categoryId,
            'note': note,
            'isExpense': isExpense,
          });

      setState(() {
        _selectedDay = chosenDate; // Nhảy lịch tới ngày vừa sửa
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật giao dịch!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: Colors.red));
      }
      debugPrint('[HomeScreen] Lỗi cập nhật giao dịch: $e');
    }
  }

  //Hiển thị form thêm/sửa giao dịch
  void _showTransactionForm(BuildContext ctx, List<CategoryItem> categories, {Transaction? existingTx}) {
    debugPrint('[HomeScreen] Mở form giao dịch: isEdit=${existingTx != null}');
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          // Nếu existingTx != null -> Chế độ Sửa, ngược lại là Thêm
          child: TransactionForm(
            categories: categories,
            existingTx: existingTx,
            onSubmit: (amount, date, catId, note, isExpense) {
              if (existingTx == null) {
                _addNewTransaction(amount, date, catId, note, isExpense);
              } else {
                _updateTransaction(existingTx.id, amount, date, catId, note, isExpense);
              }
            },
          ),
        );
      },
    );
  }

  //Hàm xóa chi thu trên Firebase
  void _deleteTransaction(String id) {
    try {
      debugPrint('[HomeScreen] Xóa giao dịch: $id');
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa giao dịch!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa: $e'), backgroundColor: Colors.red));
      }
      debugPrint('[HomeScreen] Lỗi xóa giao dịch: $e');
    }
  }

  // --- LOGIC QUẢN LÝ DANH MỤC ---

  // Hàm thêm hoặc sửa danh mục
  void _addOrEditCategory({CategoryItem? item, required bool isExpense}) {
    debugPrint('[HomeScreen] Mở form danh mục: isEdit=${item != null}, isExpense=$isExpense');
    final nameController = TextEditingController(text: item?.name ?? '');
    IconData selectedIcon = item != null ? IconData(item.iconCode, fontFamily: 'MaterialIcons') : (isExpense ? Icons.fastfood : Icons.attach_money);
    Color selectedColor = item != null ? Color(item.colorValue) : (isExpense ? Colors.red : Colors.green);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(item == null ? 'Thêm Danh Mục' : 'Sửa Danh Mục'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên danh mục')),
                  // Note: nameController will be disposed when the dialog is closed
                  const SizedBox(height: 20),
                  const Text('Chọn Biểu tượng:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 15, runSpacing: 10, children: _availableIcons.map((icon) {
                    return InkWell(
                      onTap: () { setStateDialog(() { selectedIcon = icon; }); },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selectedIcon == icon ? Colors.blueGrey.withOpacity(0.2) : null,
                          shape: BoxShape.circle,
                          border: selectedIcon == icon ? Border.all(color: Colors.blueGrey, width: 2) : null,
                        ),
                        child: Icon(icon, color: Colors.black87),
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 20),
                  const Text('Chọn Màu sắc:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 15, runSpacing: 10, children: _availableColors.map((color) {
                    return GestureDetector(
                      onTap: () { setStateDialog(() { selectedColor = color; }); },
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selectedColor == color ? Border.all(width: 3, color: Colors.black45) : null
                        ),
                      ),
                    );
                  }).toList()),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  nameController.dispose();
                  Navigator.pop(ctx);
                },
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  try {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên danh mục'), backgroundColor: Colors.red));
                      return;
                    }
                    final data = CategoryItem(
                      id: '',
                      name: nameController.text,
                      iconCode: selectedIcon.codePoint,
                      colorValue: selectedColor.value,
                      isExpense: isExpense,
                    ).toMap();

                    final colRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('categories');
                    if (item == null) {
                      colRef.add(data);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm danh mục!')));
                      }
                    } else {
                      colRef.doc(item.id).update(data);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật danh mục!')));
                      }
                    }
                    nameController.dispose();
                    Navigator.pop(ctx);
                  } catch (e) {
                    nameController.dispose();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                    }
                    debugPrint('Error saving category: $e');
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteCategory(String id) {
    try {
      debugPrint('[HomeScreen] Xóa danh mục: $id');
      FirebaseFirestore.instance.collection('users').doc(userId).collection('categories').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa danh mục!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xóa danh mục: $e'), backgroundColor: Colors.red));
      }
      debugPrint('[HomeScreen] Lỗi xóa danh mục: $e');
    }
  }

  //Hàm mở Popup chọn Tháng/Năm cho Lịch chính
  void _showMonthYearPicker() {
    showDatePicker(
      context: context,
      initialDate: _focusedDay, // Bắt đầu từ tháng đang xem
      firstDate: DateTime(2020), //Từ năm 2020
      lastDate: DateTime.now(),  //Tới hiện tại
      locale: const Locale('vi', 'VN'),

      //Giúp chọn năm nhanh hơn nếu muốn
      initialDatePickerMode: DatePickerMode.year,
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        // Cập nhật lịch chính để nhảy tới ngày đã chọn
        _focusedDay = pickedDate;
        _selectedDay = pickedDate;
      });
    });
  }

  //Hàm chuyển tab
  void _onItemTapped(int index) {
    debugPrint('[HomeScreen] Tab được chọn: $index');
    setState(() {
      _selectedIndex = index;
    });
  }
  
  // Hàm đăng xuất
  void _logout() {
    debugPrint('[HomeScreen] Hiển thị dialog đăng xuất');
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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // [QUAN TRỌNG] Lồng StreamBuilder: Lấy Danh mục trước -> Rồi lấy Giao dịch
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('categories').snapshots(),
      builder: (context, catSnapshot) {

        // Nếu chưa tải xong danh mục, hiện loading
        if (!catSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        // Chuyển đổi dữ liệu Categories thành List
        final categories = catSnapshot.data!.docs.map((doc) => CategoryItem.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

        // Map để tra cứu nhanh: ID -> CategoryItem (Để hiển thị icon/tên trong lịch sử)
        final categoryMap = {for (var item in categories) item.id: item};

        // --- XÂY DỰNG TAB TIỆN ÍCH ---
        final utilitiesTab = DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                labelColor: Colors.blueGrey,
                indicatorColor: Colors.blueGrey,
                tabs: [Tab(text: "Chi tiêu"), Tab(text: "Thu nhập")],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildCategoryList(categories.where((c) => c.isExpense).toList(), true),
                    _buildCategoryList(categories.where((c) => !c.isExpense).toList(), false),
                  ],
                ),
              ),
            ],
          ),
        );

        // Xây dựng tab lịch
        // StreamBuilder thứ 2: Lấy dữ liệu giao dịch
        final calendarTab = StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('transactions')
              .snapshots(),
          builder: (context, txSnapshot) {

            if (txSnapshot.connectionState == ConnectionState.waiting) {
              debugPrint('[HomeScreen] Đang tải giao dịch...');
              return const Center(child: CircularProgressIndicator());
            }
            if (txSnapshot.hasError) {
              debugPrint('[HomeScreen] Lỗi tải giao dịch: ${txSnapshot.error}');
              return Center(child: Text("Lỗi: ${txSnapshot.error}"));
            }

            // Chuyển đổi dữ liệu từ Firebase thành List<Transaction>
            final allTransactions = txSnapshot.data!.docs.map((doc) {
              return Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            }).toList();
            debugPrint('[HomeScreen] Tổng giao dịch: ${allTransactions.length}');

            // Lọc dữ liệu theo ngày đang chọn
            final selectedTransactions = allTransactions.where((tx) {
              return isSameDay(tx.date, _selectedDay);
            }).toList();
            debugPrint('[HomeScreen] Giao dịch ngày ${_selectedDay.toIso8601String()}: ${selectedTransactions.length}');

            //Tính toán tổng thu - chi trong ngày
            double dailyIncome = 0;
            double dailyExpense = 0;

            for (var tx in selectedTransactions) {
              if (tx.isExpense) {
                dailyExpense += tx.amount;
              } else {
                dailyIncome += tx.amount;
              }
            }
            double dailyTotal = dailyIncome - dailyExpense; // Số dư

            // --- NỘI DUNG VIEW ---
            return Column(
              children: [
                TableCalendar(//Lịch
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030),
                  focusedDay: _focusedDay,
                  currentDay: DateTime.now(),
                  locale: 'vi_VN',
                  calendarFormat: isLandscape ? CalendarFormat.twoWeeks : CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  onHeaderTapped: (_) => _showMonthYearPicker(),

                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(color: Colors.blueGrey, shape: BoxShape.circle),
                    todayDecoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.5), shape: BoxShape.circle),
                    markerDecoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                  ),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  //Event loader lấy từ list firebase
                  eventLoader: (day) {
                    return allTransactions.where((tx) => isSameDay(tx.date, day)).toList();
                  },
                ),

                // WIDGET HIỂN THỊ TỔNG KẾT NGÀY
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(children: [
                        const Text('Thu nhập', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        Text(NumberFormat.compact(locale: 'vi').format(dailyIncome), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ]),
                      Column(children: [
                        const Text('Chi tiêu', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        Text(NumberFormat.compact(locale: 'vi').format(dailyExpense), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ]),
                      Column(children: [
                        const Text('Tổng kết', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                        Text(
                          NumberFormat.compact(locale: 'vi').format(dailyTotal),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: dailyTotal >= 0 ? Colors.blue : Colors.red),
                        ),
                      ]),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // DANH SÁCH THU CHI
                Expanded(
                  child: selectedTransactions.isEmpty
                      ? Center(
                          child: Text(
                            'Không có chi thu nào\nvào ngày ${DateFormat('dd/MM').format(_selectedDay)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: selectedTransactions.length,
                          itemBuilder: (ctx, index) {
                            final tx = selectedTransactions[index];
                            // Tra cứu Category từ Map
                            final cat = categoryMap[tx.categoryId];

                            //Bọc Dismissible để vuốt xóa
                            return Dismissible(
                              key: ValueKey(tx.id),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Xóa giao dịch?'),
                                    content: const Text('Bạn chắc chắn muốn xóa giao dịch này không?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                ) ?? false;
                              },
                              onDismissed: (direction) {
                                _deleteTransaction(tx.id);
                              },
                              child: Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 25,
                                    backgroundColor: (cat != null ? Color(cat.colorValue) : Colors.grey).withOpacity(0.2),
                                    child: Icon(
                                      cat != null ? IconData(cat.iconCode, fontFamily: 'MaterialIcons') : Icons.help,
                                      color: cat != null ? Color(cat.colorValue) : Colors.grey,
                                    ),
                                  ),
                                  title: Text(
                                    cat?.name ?? 'Không xác định',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: tx.note.isNotEmpty ? Text(tx.note) : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${tx.isExpense ? '-' : '+'}${NumberFormat.currency(locale: 'vi', symbol: 'đ', decimalDigits: 0).format(tx.amount)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: tx.isExpense ? Colors.red : Colors.green,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        color: Colors.grey,
                                        iconSize: 20,
                                        //Mở form sửa
                                        onPressed: () => _showTransactionForm(context, categories, existingTx: tx),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }
        );

        // Danh sách màn hình cho thanh điều hướng dưới cùng
        final List<Widget> widgetOptions = <Widget>[
          calendarTab,
          const Center(child: Text('Màn hình Báo cáo')),
          utilitiesTab, //Đã gán giao diện Tiện ích vào đây
          const Center(child: Text('Màn hình Cài đặt')),
        ];
        debugPrint('[HomeScreen] Widget options initialized: ${widgetOptions.length} tabs');

        return Scaffold(
          appBar: AppBar(
            title: Text(_selectedIndex == 2 ? 'Quản lý Danh mục' : 'Sổ Thu Chi'),
            actions: [
              if (_selectedIndex == 0) ...[  // Tab lịch
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  tooltip: 'Chọn tháng/năm',
                  onPressed: _showMonthYearPicker,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Thêm thu chi mới',
                  onPressed: () => _showTransactionForm(context, categories),
                ),
              ],
              // Nút Đăng xuất
              IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: "Đăng xuất")
            ],
          ),
          body: widgetOptions.elementAt(_selectedIndex),

          floatingActionButton: _selectedIndex == 2
            // Nút thêm danh mục ở tab tiện ích
            ? FloatingActionButton(
                child: const Icon(Icons.add),
                onPressed: () {
                   showModalBottomSheet(context: context, builder: (_) => Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       ListTile(leading: const Icon(Icons.money_off, color: Colors.red), title: const Text('Thêm Danh mục Chi tiêu'), onTap: () { Navigator.pop(context); _addOrEditCategory(isExpense: true); }),
                       ListTile(leading: const Icon(Icons.attach_money, color: Colors.green), title: const Text('Thêm Danh mục Thu nhập'), onTap: () { Navigator.pop(context); _addOrEditCategory(isExpense: false); }),
                     ],
                   ));
                },
              )
            // Nút thêm giao dịch ở tab lịch
            : (_selectedIndex == 0 ? FloatingActionButton(
                tooltip: 'Thêm thu chi mới',
                child: const Icon(Icons.add),
                onPressed: () => _showTransactionForm(context, categories),
              ) : null),

          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              debugPrint('[HomeScreen] Chuyển tab: $index');
              _onItemTapped(index);
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Lịch'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Báo cáo'),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tiện ích'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
            ],
            currentIndex: _selectedIndex,
          ),
        );
      },
    );
  }

  // Widget hiển thị danh sách danh mục
  Widget _buildCategoryList(List<CategoryItem> items, bool isExpense) {
    if (items.isEmpty) return const Center(child: Text("Chưa có danh mục nào"));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(item.colorValue).withOpacity(0.2),
              child: Icon(IconData(item.iconCode, fontFamily: 'MaterialIcons'), color: Color(item.colorValue)),
            ),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _addOrEditCategory(item: item, isExpense: item.isExpense)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteConfirm(item.id)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteConfirm(String id) {
    debugPrint('[HomeScreen] Hiển thị dialog xác nhận xóa danh mục');
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Xóa danh mục?"),
      content: const Text("Bạn có chắc chắn muốn xóa không?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
        TextButton(onPressed: () { _deleteCategory(id); Navigator.pop(ctx); }, child: const Text("Xóa", style: TextStyle(color: Colors.red))),
      ],
    ));
  }
}