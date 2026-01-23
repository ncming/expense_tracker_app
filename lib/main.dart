import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// [MỚI] Import thư viện Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// [MỚI] Import thư viện này để xử lý việc định dạng số (dấu phẩy) trong ô nhập liệu
import 'package:flutter/services.dart';

void main() async {
  //Đảm bảo Flutter Binding được khởi tạo trước khi gọi code bất đồng bộ
  WidgetsFlutterBinding.ensureInitialized();

  //Khởi động Firebase
  await Firebase.initializeApp();

  // Phải dùng .then() vì đây là hàm bất đồng bộ (cần thời gian để tải)
  initializeDateFormatting('vi_VN', null).then((_) {
    runApp(const MyApp());
  });
}

// ---------------------------------------------------------
// [MỚI] CLASS XỬ LÝ DẤU PHẨY (FORMATTER)
// Class này giúp tự động thêm dấu phẩy ngăn cách hàng nghìn khi nhập số tiền
// Ví dụ: Nhập 10000 -> Hiển thị 10,000
// ---------------------------------------------------------
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Nếu ô nhập trống thì trả về trống
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 1. Xóa tất cả các ký tự không phải là số (ví dụ dấu phẩy cũ) để lấy số thô
    String valueStr = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Nếu xóa xong mà rỗng (vd người dùng nhập toàn chữ) thì trả về rỗng
    if (valueStr.isEmpty) return newValue.copyWith(text: '');

    // 2. Chuyển thành số
    double value = double.parse(valueStr);

    // 3. Định dạng lại thành chuỗi có dấu phẩy (theo chuẩn Mỹ en_US)
    final formatter = NumberFormat("#,###", "en_US");
    String newText = formatter.format(value);

    // 4. Trả về chuỗi mới và đặt con trỏ chuột ở cuối dòng
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

// 1. ĐỊNH NGHĨA DATA MODEL MỚI (DYNAMIC CATEGORY)

//Class đại diện cho Danh mục (Lưu trên Firebase thay vì Enum)
class CategoryItem {
  final String id;
  final String name;
  final int iconCode;   // Lưu mã số của Icon
  final int colorValue; // Lưu mã số của Màu
  final bool isExpense; // True: Chi, False: Thu

  CategoryItem({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.isExpense,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconCode': iconCode,
      'colorValue': colorValue,
      'isExpense': isExpense,
    };
  }

  factory CategoryItem.fromMap(Map<String, dynamic> map, String id) {
    return CategoryItem(
      id: id,
      name: map['name'] ?? 'Không tên',
      // Mặc định icon dấu hỏi nếu lỗi
      iconCode: map['iconCode'] ?? Icons.help_outline.codePoint,
      // Mặc định màu xám nếu lỗi
      colorValue: map['colorValue'] ?? Colors.grey.value,
      isExpense: map['isExpense'] ?? true,
    );
  }
}

// [MỚI] Cập nhật Class Transaction để liên kết với CategoryItem qua ID
class Transaction {
  final String id;
  final double amount;
  final DateTime date;
  final String categoryId; // [QUAN TRỌNG] Lưu ID danh mục (String) thay vì Enum
  final String note;
  final bool isExpense;

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.note = '',
    required this.isExpense,
  });

  // Hàm đóng gói dữ liệu thành Map để gửi lên Firebase
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date.toIso8601String(), // Firebase lưu ngày dạng chuỗi
      'categoryId': categoryId,       // Lưu ID chuỗi
      'note': note,
      'isExpense': isExpense,
    };
  }

  // Hàm mở gói dữ liệu an toàn hơn (Chống lỗi Null)
  factory Transaction.fromMap(Map<String, dynamic> map, String id) {
    return Transaction(
      id: id,
      // dấu ? và ?? 0 (Nếu không có tiền thì coi là 0 đồng)
      amount: (map['amount'] as num? ?? 0).toDouble(),
      
      // Nếu không có ngày thì lấy ngày hiện tại
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      
      // Nếu không có categoryId thì để rỗng
      categoryId: map['categoryId'] ?? '',
      
      note: map['note'] ?? '',
      isExpense: map['isExpense'] ?? true,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sổ Thu Chi',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.blueGrey.shade50,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
      ),
      
      // [MỚI] CẤU HÌNH NGÔN NGỮ CHO TOÀN BỘ APP
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
      ],

      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _selectedIndex = 0; // [MỚI] Để quản lý Tabbar

  // [MỚI] Giả lập ID người dùng (Sau này thay bằng ID thật khi làm đăng nhập)
  final String userId = "user_test_1";

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
    _checkAndCreateDefaultCategories();
  }

  //Tự động tạo danh mục mẫu nếu database trống
  void _checkAndCreateDefaultCategories() async {
    final catRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('categories');
    final snapshot = await catRef.get();
    
    if (snapshot.docs.isEmpty) {
      // --- 1. NHÓM CHI TIÊU (EXPENSE) ---
      // Ăn uống: Màu Cam
      await catRef.add(CategoryItem(id: '', name: 'Ăn uống', iconCode: Icons.fastfood.codePoint, colorValue: Colors.orange.value, isExpense: true).toMap());
      // Chi tiêu hàng ngày: Màu Xanh lơ
      await catRef.add(CategoryItem(id: '', name: 'Chi tiêu hàng ngày', iconCode: Icons.shopping_cart.codePoint, colorValue: Colors.cyan.value, isExpense: true).toMap());
      // Quần áo: Màu Hồng
      await catRef.add(CategoryItem(id: '', name: 'Quần áo', iconCode: Icons.checkroom.codePoint, colorValue: Colors.pink.value, isExpense: true).toMap());
      // Mỹ phẩm: Màu Tím nhạt
      await catRef.add(CategoryItem(id: '', name: 'Mỹ phẩm', iconCode: Icons.face.codePoint, colorValue: Colors.purpleAccent.value, isExpense: true).toMap());
      // Phí giao lưu: Màu Vàng chanh
      await catRef.add(CategoryItem(id: '', name: 'Phí giao lưu', iconCode: Icons.local_bar.codePoint, colorValue: Colors.lime.shade800.value, isExpense: true).toMap());
      // Y tế: Màu Đỏ
      await catRef.add(CategoryItem(id: '', name: 'Y tế', iconCode: Icons.medical_services.codePoint, colorValue: Colors.red.value, isExpense: true).toMap());
      // Giáo dục: Màu Xanh dương đậm
      await catRef.add(CategoryItem(id: '', name: 'Giáo dục', iconCode: Icons.school.codePoint, colorValue: Colors.blue.shade900.value, isExpense: true).toMap());
      // Điện nước: Màu Vàng đậm
      await catRef.add(CategoryItem(id: '', name: 'Tiền điện nước', iconCode: Icons.lightbulb.codePoint, colorValue: Colors.amber.shade800.value, isExpense: true).toMap());
      // Phí liên lạc: Màu Chàm
      await catRef.add(CategoryItem(id: '', name: 'Phí liên lạc', iconCode: Icons.phone_android.codePoint, colorValue: Colors.indigo.value, isExpense: true).toMap());
      // Tiền nhà: Màu Nâu
      await catRef.add(CategoryItem(id: '', name: 'Tiền nhà', iconCode: Icons.home.codePoint, colorValue: Colors.brown.value, isExpense: true).toMap());
      // Di chuyển: Màu Xanh dương
      await catRef.add(CategoryItem(id: '', name: 'Di chuyển', iconCode: Icons.directions_bus.codePoint, colorValue: Colors.blue.value, isExpense: true).toMap());

      // --- 2. NHÓM THU NHẬP (INCOME) ---
      // Tiền lương: Màu Xanh lá đậm
      await catRef.add(CategoryItem(id: '', name: 'Tiền lương', iconCode: Icons.attach_money.codePoint, colorValue: Colors.green.shade800.value, isExpense: false).toMap());
      // Phụ cấp: Màu Xanh lá nhạt
      await catRef.add(CategoryItem(id: '', name: 'Tiền phụ cấp', iconCode: Icons.account_balance_wallet.codePoint, colorValue: Colors.lightGreen.value, isExpense: false).toMap());
      // Tiền thưởng: Màu Vàng kim
      await catRef.add(CategoryItem(id: '', name: 'Tiền thưởng', iconCode: Icons.card_giftcard.codePoint, colorValue: Colors.amber.value, isExpense: false).toMap());
      // Đầu tư: Màu Tím than
      await catRef.add(CategoryItem(id: '', name: 'Đầu tư', iconCode: Icons.trending_up.codePoint, colorValue: Colors.deepPurple.value, isExpense: false).toMap());
      // Thu nhập phụ: Màu Xanh Teal
      await catRef.add(CategoryItem(id: '', name: 'Thu nhập phụ', iconCode: Icons.monetization_on.codePoint, colorValue: Colors.teal.value, isExpense: false).toMap());
      // Thu nhập tạm thời: Màu Xám xanh
      await catRef.add(CategoryItem(id: '', name: 'Thu nhập tạm thời', iconCode: Icons.hourglass_bottom.codePoint, colorValue: Colors.blueGrey.value, isExpense: false).toMap());
    }
  }

  //Cập nhật hàm thêm: Gửi dữ liệu lên Firebase
  void _addNewTransaction(double amount, DateTime chosenDate, String categoryId, String note, bool isExpense) {
    final newTx = Transaction(
      id: '', 
      amount: amount,
      date: chosenDate,
      categoryId: categoryId, // Lưu ID string
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
  }

  //Hàm cập nhật giao dịch (SỬA)
  void _updateTransaction(String txId, double amount, DateTime chosenDate, String categoryId, String note, bool isExpense) {
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

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật giao dịch!')));
  }

  // [MỚI] Hiển thị Form Thêm/Sửa Giao dịch
  void _showTransactionForm(BuildContext ctx, List<CategoryItem> categories, {Transaction? existingTx}) {
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
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(id)
        .delete();
        
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa!')),
    );
  }

  // --- LOGIC QUẢN LÝ DANH MỤC (Tab Tiện ích) ---
  
  // Hàm Thêm hoặc Sửa danh mục
  void _addOrEditCategory({CategoryItem? item, required bool isExpense}) {
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isEmpty) return;
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
                  } else {
                    colRef.doc(item.id).update(data);
                  }
                  Navigator.pop(ctx);
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
    FirebaseFirestore.instance.collection('users').doc(userId).collection('categories').doc(id).delete();
  }

  // [MỚI] Hàm mở Popup chọn Tháng/Năm cho Lịch chính
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

  // [MỚI] Hàm chuyển tab
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

        // --- XÂY DỰNG TAB TIỆN ÍCH (QUẢN LÝ DANH MỤC) ---
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

        // --- XÂY DỰNG TAB LỊCH (TRANG CHỦ) ---
        // STREAM BUILDER THỨ 2: Lấy dữ liệu Giao dịch
        final calendarTab = StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('transactions')
              .snapshots(),
          builder: (context, txSnapshot) {
            
            if (txSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (txSnapshot.hasError) {
              return Center(child: Text("Lỗi: ${txSnapshot.error}"));
            }

            // Chuyển đổi dữ liệu từ Firebase thành List<Transaction>
            final allTransactions = txSnapshot.data!.docs.map((doc) {
              return Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            }).toList();

            // Lọc dữ liệu theo ngày đang chọn
            final selectedTransactions = allTransactions.where((tx) {
              return isSameDay(tx.date, _selectedDay);
            }).toList();

            // [MỚI] TÍNH TOÁN TỔNG THU - CHI TRONG NGÀY
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
                  // [MỚI] Event loader lấy từ list firebase
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
                            // [QUAN TRỌNG] Tra cứu Category từ Map
                            final cat = categoryMap[tx.categoryId];

                            // [MỚI] Bọc Dismissible để vuốt xóa
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
                                        // [MỚI] Mở form sửa
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

        // Danh sách màn hình cho BottomBar
        final List<Widget> widgetOptions = <Widget>[
          calendarTab,
          const Center(child: Text('Màn hình Báo cáo')),
          utilitiesTab, //Đã gán giao diện Tiện ích vào đây
          const Center(child: Text('Màn hình Cài đặt')),
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(_selectedIndex == 2 ? 'Quản lý Danh mục' : 'Lịch'),
            actions: _selectedIndex == 0 ? [
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
            ] : null,
          ),
          body: widgetOptions.elementAt(_selectedIndex),
          
          floatingActionButton: _selectedIndex == 2
            // Nút thêm danh mục ở Tab Tiện ích
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
            // Nút thêm thu chi ở Tab Lịch
            : (_selectedIndex == 0 ? FloatingActionButton(
                tooltip: 'Thêm thu chi mới',
                child: const Icon(Icons.add),
                onPressed: () => _showTransactionForm(context, categories),
              ) : null),
              
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Lịch'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Báo cáo'),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tiện ích'), 
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }

  // Widget hiển thị danh sách trong Tab Tiện ích
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

// FORM NHẬP LIỆU THU CHI (Đã nâng cấp Dropdown động & Chế độ Sửa)
class TransactionForm extends StatefulWidget {
  final List<CategoryItem> categories;
  // Callback trả về dữ liệu khi bấm Lưu
  final Function(double, DateTime, String, String, bool) onSubmit;
  final Transaction? existingTx; // Nếu có dữ liệu này -> Chế độ Sửa

  const TransactionForm({super.key, required this.categories, required this.onSubmit, this.existingTx});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedCategoryId; // Lưu ID thay vì Enum
  bool _isExpense = true;

  @override
  void initState() {
    super.initState();
    // Nếu là chế độ Sửa, điền sẵn dữ liệu cũ
    if (widget.existingTx != null) {
      final tx = widget.existingTx!;
      // [UPDATE] Định dạng lại số tiền cũ có dấu phẩy khi mở lên sửa
      final formatter = NumberFormat("#,###", "en_US");
      _amountController.text = formatter.format(tx.amount);
      
      _noteController.text = tx.note;
      _selectedDate = tx.date;
      _selectedCategoryId = tx.categoryId;
      _isExpense = tx.isExpense;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lọc danh mục theo loại đang chọn (Chỉ hiện Chi tiêu hoặc Thu nhập)
    final currentCategories = widget.categories.where((c) => c.isExpense == _isExpense).toList();

    // Reset lựa chọn nếu danh mục cũ không còn khớp với loại (trừ khi đang mở form sửa)
    if (_selectedCategoryId != null && currentCategories.every((c) => c.id != _selectedCategoryId)) {
      // Nếu đang trong chế độ sửa và danh mục vẫn hợp lệ với loại, giữ nguyên.
      // Nếu user chuyển tab Thu/Chi, mới reset.
      // (Logic đơn giản: nếu ID không nằm trong list hiện tại -> reset)
      _selectedCategoryId = null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
           Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Loại:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              ToggleButtons(
                isSelected: [_isExpense, !_isExpense],
                onPressed: (int index) { 
                  setState(() { 
                    _isExpense = index == 0; 
                    _selectedCategoryId = null; 
                  }); 
                },
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white,
                fillColor: _isExpense ? Colors.redAccent : Colors.green,
                children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Chi tiêu')), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Thu nhập'))],
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // [UPDATE] Thêm inputFormatters để tự động thêm dấu phẩy
          TextField(
            controller: _amountController, 
            decoration: const InputDecoration(labelText: 'Số tiền'), 
            keyboardType: TextInputType.number, 
            autofocus: true,
            inputFormatters: [
               FilteringTextInputFormatter.digitsOnly, // Chỉ cho nhập số
               ThousandsSeparatorInputFormatter(),     // Tự động thêm dấu phẩy
            ],
          ),
          
          const SizedBox(height: 10),
          
          // [QUAN TRỌNG] Dropdown hiển thị danh mục lấy từ Firebase
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            hint: const Text("Chọn danh mục"),
            items: currentCategories.map((cat) {
              return DropdownMenuItem(
                value: cat.id,
                child: Row(children: [Icon(IconData(cat.iconCode, fontFamily: 'MaterialIcons'), color: Color(cat.colorValue), size: 20), const SizedBox(width: 10), Text(cat.name)]),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedCategoryId = val),
          ),
          
          TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Ghi chú'), textCapitalization: TextCapitalization.sentences),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Text(_selectedDate == null ? 'Chưa chọn ngày' : 'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}')),
            TextButton(onPressed: () {
              showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now(), locale: const Locale('vi', 'VN'))
              .then((d) { if (d != null) setState(() => _selectedDate = d); });
            }, child: const Text('Chọn ngày'))
          ]),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (_amountController.text.isEmpty || _selectedCategoryId == null || _selectedDate == null) return;
              
              // [QUAN TRỌNG] Phải xóa hết dấu phẩy trước khi đổi sang số (1,000,000 -> 1000000)
              String cleanAmount = _amountController.text.replaceAll(',', '');
              double finalAmount = double.tryParse(cleanAmount) ?? 0;

              // Gọi hàm submit (Thêm hoặc Sửa)
              widget.onSubmit(finalAmount, _selectedDate!, _selectedCategoryId!, _noteController.text, _isExpense);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _isExpense ? Colors.redAccent : Colors.green, foregroundColor: Colors.white),
            child: Text(widget.existingTx == null ? 'Lưu' : 'Cập nhật'),
          )
        ],
      ),
    );
  }
}