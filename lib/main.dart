import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
// [MỚI] Import thư viện để khởi tạo dữ liệu ngày tháng
import 'package:intl/date_symbol_data_local.dart'; 
// [MỚI] Import thư viện hỗ trợ đa ngôn ngữ của Flutter
import 'package:flutter_localizations/flutter_localizations.dart'; 

void main() {
  // [MỚI] Khởi tạo dữ liệu định dạng cho Tiếng Việt ('vi_VN') trước khi chạy App
  // Phải dùng .then() vì đây là hàm bất đồng bộ (cần thời gian để tải)
  initializeDateFormatting('vi_VN', null).then((_) {
    runApp(const MyApp());
  });
}

// 1. ĐỊNH NGHĨA CÁC LOẠI CHI TIÊU
enum CategoryType { food, health, electricity, shopping, transport, other } //Dùng enum để quy định cố định các loại chi tiêu

String getCategoryName(CategoryType type) {
  switch (type) {
    case CategoryType.food: return 'Ăn uống';
    case CategoryType.health: return 'Y tế';
    case CategoryType.electricity: return 'Điện nước';
    case CategoryType.shopping: return 'Mua sắm';
    case CategoryType.transport: return 'Di chuyển';
    case CategoryType.other: return 'Khác';
  }
}

IconData getCategoryIcon(CategoryType type) {
  switch (type) {//switch dùng để tìm type khớp | case là đầu ra
    case CategoryType.food: return Icons.fastfood;
    case CategoryType.health: return Icons.medical_services;
    case CategoryType.electricity: return Icons.lightbulb;
    case CategoryType.shopping: return Icons.shopping_bag;
    case CategoryType.transport: return Icons.directions_bus;
    case CategoryType.other: return Icons.category;
  }
}

Color getCategoryColor(CategoryType type) {
  switch (type) {
    case CategoryType.food: return Colors.orange;
    case CategoryType.health: return Colors.red;
    case CategoryType.electricity: return Colors.yellow.shade700;
    case CategoryType.shopping: return Colors.purple;
    case CategoryType.transport: return Colors.blue;
    case CategoryType.other: return Colors.grey;
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
      // Khai báo các "đại sứ" (delegates) chịu trách nhiệm dịch thuật cho Material, Widget, v.v.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Khai báo các ngôn ngữ mà App hỗ trợ (Ở đây chỉ hỗ trợ Tiếng Việt)
      supportedLocales: const [
        Locale('vi', 'VN'), 
      ],
      // -----------------------------------------------------

      home: const MyHomePage(),
    );
  }
}

class Transaction { //lày là khuôn khoản chi
  final String id; //final thông tin cố định không bị thay đổi
  final double amount;
  final DateTime date;
  final CategoryType category;
  final String note;

  Transaction({ //thằng này là constructor (hàm khởi tạo)
    required this.id,
    required this.amount,
    required this.date,
    required this.category,
    this.note = '',
  });
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Dữ liệu mẫu
  final List<Transaction> _userTransactions = [ //lày là cái list chứa input, nó nằm trong statefulWidget nên add input mới nó tự setState hiển thị lun.
    Transaction(
      id: 'a1',
      amount: 1500000,
      date: DateTime.now(),
      category: CategoryType.shopping,
      note: 'Mua giày thể thao',
    ),
    Transaction(
      id: 'a2',
      amount: 50000,
      date: DateTime.now(),
      category: CategoryType.food,
      note: 'Trà đá vỉa hè',
    ),
    Transaction(
      id: 'a3',
      amount: 500000,
      date: DateTime.now().subtract(const Duration(days:2)),
      category: CategoryType.health,
      note: 'thuốc ho',
    ),
    Transaction(
      id: 'a4',
      amount: 100000,
      date: DateTime.now().subtract(const Duration(days:2)),
      category: CategoryType.food,
      note: 'phở thìn',
    ),
    Transaction(
      id: 'a5',
      amount: 50000,
      date: DateTime.now().subtract(const Duration(days:2)),
      category: CategoryType.transport,
      note: '',
    ),
  ];

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<Transaction> _getTransactionsForDay(DateTime day) { //con vợ này để lấy ra những khoản chi tiêu trong ngày
    return _userTransactions.where((tx) {//where để lọc dữ liệu
      return isSameDay(tx.date, day);
    }).toList();//gom dữ liệu thành 1 list lưu vào _selectedTransactions
  }

  void _addNewTransaction(double amount, DateTime chosenDate, CategoryType category, String note) {
    final newTx = Transaction(
      id: DateTime.now().toString(),
      amount: amount,
      date: chosenDate,
      category: category,
      note: note,
    );

    setState(() {
      _userTransactions.add(newTx);
      _selectedDay = chosenDate;
      _focusedDay = chosenDate;
    });
  }

  void _startAddNewTransaction(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: NewTransaction(_addNewTransaction),
        );
      },
    );
  }

  // Hàm xử lý khi bấm nút sửa (Tạm thời chỉ in ra Console)
  void _editTransaction(Transaction tx) {
    // Sau này sẽ code logic mở form sửa ở đây
    print('Bạn vừa bấm sửa khoản: ${tx.note} - ${tx.amount}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đang chọn sửa: ${tx.note}')),
    );
  }

  // [MỚI] Hàm mở Popup chọn Tháng/Năm cho Lịch chính
  void _showMonthYearPicker() {
    showDatePicker(
      context: context,
      initialDate: _focusedDay, // Bắt đầu từ tháng đang xem
      firstDate: DateTime(2020), // [Yêu cầu] Từ năm 2020
      lastDate: DateTime.now(),  // [Yêu cầu] Tới hiện tại
      locale: const Locale('vi', 'VN'),
      
      // Mẹo nhỏ: Giúp chọn năm nhanh hơn nếu muốn
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

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final selectedTransactions = _getTransactionsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch'),
      ),
      body: Column(
        children: [
          TableCalendar(//Lịch
            firstDay: DateTime(2020),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            currentDay: DateTime.now(),
            
            // [MỚI] Cài đặt ngôn ngữ hiển thị cho Lịch chính
            locale: 'vi_VN', 
            
            calendarFormat: isLandscape ? CalendarFormat.twoWeeks : CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            
            // [MỚI] Tùy chỉnh phần đầu lịch (Header) để thay thế nút "2 weeks"
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, // 1. Ẩn nút "2 weeks" (format button) đi
              titleCentered: true,        // 2. Căn giữa tiêu đề (Tháng/Năm)
            ),
            
            // [MỚI] Khi bấm vào tiêu đề (Tháng/Năm) -> Mở bảng chọn ngày
            onHeaderTapped: (_) => _showMonthYearPicker(),

            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: Colors.blueGrey,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;//xác định ngày
                _focusedDay = focusedDay;//xác định tháng
              });
            },
            eventLoader: _getTransactionsForDay,//Như tên, con vợ để lấy ra mấy cái input theo ngày mình chọn
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: selectedTransactions.isEmpty
                ? Center(
                    child: Text(
                      'Không có khoản chi nào\nvào ngày ${DateFormat('dd/MM').format(_selectedDay)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: selectedTransactions.length,
                    itemBuilder: (ctx, index) {
                      final tx = selectedTransactions[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: getCategoryColor(tx.category).withOpacity(0.2),
                            child: Icon(
                              getCategoryIcon(tx.category),
                              color: getCategoryColor(tx.category),
                            ),
                          ),
                          title: Text(
                            getCategoryName(tx.category),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: tx.note.isNotEmpty ? Text(tx.note) : null,
                          
                          // --- SỬA PHẦN NÀY ---
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min, // Quan trọng để Row không chiếm hết chỗ
                            children: [
                              // 1. Số tiền
                              Text(
                                NumberFormat.currency(locale: 'vi', symbol: 'đ').format(tx.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              // 2. Nút chỉnh sửa (IconButton)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: Colors.grey, 
                                iconSize: 20,
                                onPressed: () => _editTransaction(tx), // Gọi hàm sửa
                              ),
                            ],
                          ),
                          // --------------------
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _startAddNewTransaction(context),
      ),

      //thêm thanh công cụ
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Lịch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Báo cáo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

class NewTransaction extends StatefulWidget {
  final Function(double, DateTime, CategoryType, String) addTx;

  const NewTransaction(this.addTx, {super.key});

  @override
  State<NewTransaction> createState() => _NewTransactionState();
}

class _NewTransactionState extends State<NewTransaction> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _selectedDate;
  CategoryType _selectedCategory = CategoryType.food;

  void _submitData() {
    if (_amountController.text.isEmpty) return;
    final enteredAmount = double.tryParse(_amountController.text) ?? 0;

    if (enteredAmount <= 0 || _selectedDate == null) {
      return;
    }

    widget.addTx(
      enteredAmount,
      _selectedDate!,
      _selectedCategory,
      _noteController.text,
    );

    Navigator.of(context).pop();
  }

  void _presentDatePicker() {
    showDatePicker(//hiện date chọn
      context: context,//đè lên "chưa chọn ngày!"
      initialDate: DateTime.now(),//mặc định
      firstDate: DateTime(2020),// giới hạn quá khứ
      lastDate: DateTime.now(),// không cho chọn ngày mai
      
      // [MỚI] Cài đặt ngôn ngữ cho Popup chọn ngày
      locale: const Locale('vi', 'VN'),
      
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Số tiền'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Text('Loại chi tiêu: ', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              DropdownButton<CategoryType>(
                value: _selectedCategory,
                items: CategoryType.values.map((CategoryType type) {
                  return DropdownMenuItem<CategoryType>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(getCategoryIcon(type), color: getCategoryColor(type), size: 20),
                        const SizedBox(width: 10),
                        Text(getCategoryName(type)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (CategoryType? newValue) {
                  setState(() {
                    if (newValue != null) _selectedCategory = newValue;
                  });
                },
              ),
            ],
          ),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Ghi chú (Tùy chọn)',
              hintText: 'VD: Mua giày nike...',
            ),
            controller: _noteController,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedDate == null
                      ? 'Chưa chọn ngày!'
                      : 'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: const Text('Chọn ngày'),
                onPressed: _presentDatePicker,
              ),
            ],
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _submitData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thêm Khoản Chi'),
          ),
        ],
      ),
    );
  }
}