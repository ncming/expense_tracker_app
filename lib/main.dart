import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
// [MỚI] Import thư viện để khởi tạo dữ liệu ngày tháng
import 'package:intl/date_symbol_data_local.dart'; 
// [MỚI] Import thư viện hỗ trợ đa ngôn ngữ của Flutter
import 'package:flutter_localizations/flutter_localizations.dart'; 

void main() {
  // Phải dùng .then() vì đây là hàm bất đồng bộ (cần thời gian để tải)
  initializeDateFormatting('vi_VN', null).then((_) {
    runApp(const MyApp());
  });
}

// 1. ĐỊNH NGHĨA DATA MODEL và ENUM
enum CategoryType { 
  food, health, electricity, shopping, transport, other, // Nhóm Chi tiêu
  income // [MỚI] Nhóm Thu nhập (Gộp chung 1 loại duy nhất)
} 

String getCategoryName(CategoryType type) {
  switch (type) {
    case CategoryType.food: return 'Ăn uống';
    case CategoryType.health: return 'Y tế';
    case CategoryType.electricity: return 'Điện nước';
    case CategoryType.shopping: return 'Mua sắm';
    case CategoryType.transport: return 'Di chuyển';
    case CategoryType.other: return 'Chi khác';
    case CategoryType.income: return 'Thu nhập'; 
  }
}

IconData getCategoryIcon(CategoryType type) {
  switch (type) {//switch dùng để tìm type khớp | case là đầu ra
    case CategoryType.food: return Icons.fastfood;
    case CategoryType.health: return Icons.medical_services;
    case CategoryType.electricity: return Icons.lightbulb;
    case CategoryType.shopping: return Icons.shopping_bag;
    case CategoryType.transport: return Icons.directions_bus;
    case CategoryType.other: return Icons.help_outline;
    case CategoryType.income: return Icons.attach_money;
  }
}

Color getCategoryColor(CategoryType type) {
  switch (type) {
    case CategoryType.food: return Colors.orange;
    case CategoryType.health: return Colors.red;
    case CategoryType.electricity: return Colors.yellow.shade800;
    case CategoryType.shopping: return Colors.purple;
    case CategoryType.transport: return Colors.blue;
    case CategoryType.other: return Colors.grey;
    case CategoryType.income: return Colors.green; // Màu xanh cho thu nhập
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

class Transaction { //lày là khuôn khoản chi
  final String id; //final thông tin cố định không bị thay đổi
  final double amount;
  final DateTime date;
  final CategoryType category;
  final String note;
  final bool isExpense; // [MỚI] True = Chi tiêu, False = Thu nhập

  Transaction({ //thằng này là constructor (hàm khởi tạo)
    required this.id,
    required this.amount,
    required this.date,
    required this.category,
    this.note = '',
    required this.isExpense, // [MỚI] Bắt buộc khai báo loại
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
      isExpense: true, // [MỚI]
    ),
    Transaction(
      id: 'a2',
      amount: 50000,
      date: DateTime.now(),
      category: CategoryType.food,
      note: 'Trà đá vỉa hè',
      isExpense: true, // [MỚI]
    ),
    // [MỚI] Thêm mẫu thu nhập
    Transaction(
      id: 'a3',
      amount: 5000000,
      date: DateTime.now(),
      category: CategoryType.income,
      note: 'Lương thưởng',
      isExpense: false, // [MỚI] False là thu nhập
    ),
  ];

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _selectedIndex = 0; // [MỚI] Để quản lý Tabbar

  List<Transaction> _getTransactionsForDay(DateTime day) { //con vợ này để lấy ra những khoản chi tiêu trong ngày
    return _userTransactions.where((tx) {//where để lọc dữ liệu
      return isSameDay(tx.date, day);
    }).toList();//gom dữ liệu thành 1 list lưu vào _selectedTransactions
  }

  // [MỚI] Cập nhật hàm thêm để nhận diện Thu/Chi
  void _addNewTransaction(double amount, DateTime chosenDate, CategoryType category, String note, bool isExpense) {
    final newTx = Transaction(
      id: DateTime.now().toString(),
      amount: amount,
      date: chosenDate,
      category: category,
      note: note,
      isExpense: isExpense,
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
    final selectedTransactions = _getTransactionsForDay(_selectedDay);

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
    // ------------------------------------------

    // Nội dung tab Lịch
    final calendarTabContent = Column(
        children: [
          TableCalendar(//Lịch
            firstDay: DateTime(2020),
            lastDay: DateTime(2030), // [MỚI] Mở rộng đến 2030
            focusedDay: _focusedDay,
            currentDay: DateTime.now(),
            
            // [MỚI] Cài đặt ngôn ngữ hiển thị cho Lịch chính
            locale: 'vi_VN', 
            
            calendarFormat: isLandscape ? CalendarFormat.twoWeeks : CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            //Tùy chỉnh phần Header để thay thế nút "2 weeks"
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, // 1. Ẩn nút "2 weeks" (format button) đi
              titleCentered: true,        // 2. Căn giữa tiêu đề (Tháng/Năm)
            ),
            
            //Khi bấm vào tiêu đề (Tháng/Năm) -> Mở bảng chọn ngày
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
          
          // [MỚI] WIDGET HIỂN THỊ TỔNG KẾT NGÀY
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
          // ------------------------------------------

          const Divider(height: 1, thickness: 1),
          Expanded(
            child: selectedTransactions.isEmpty
                ? Center(
                    child: Text(
                      'Không có giao dịch nào\nvào ngày ${DateFormat('dd/MM').format(_selectedDay)}',
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min, // Quan trọng để Row không chiếm hết chỗ
                            children: [
                              // 1. Số tiền [MỚI] Hiển thị màu xanh/đỏ
                              Text(
                                '${tx.isExpense ? '-' : '+'}${NumberFormat.currency(locale: 'vi', symbol: 'đ', decimalDigits: 0).format(tx.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: tx.isExpense ? Colors.red : Colors.green,
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
                        ),
                      );
                    },
                  ),
          ),
        ],
      );

    // [MỚI] Danh sách màn hình cho BottomBar
    final List<Widget> widgetOptions = <Widget>[
      calendarTabContent,
      const Center(child: Text('Màn hình Báo cáo')),
      const Center(child: Text('Màn hình Tiện ích')),
      const Center(child: Text('Màn hình Cài đặt')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch'),
        // [MỚI] Thêm nút chọn ngày trên AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Chọn tháng/năm', // [MỚI] Tooltip chọn ngày
            onPressed: _showMonthYearPicker,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nhập khoản chi thu', // [MỚI] Tooltip thêm mới
            onPressed: () => _startAddNewTransaction(context),
          ),
        ],
      ),
      body: widgetOptions.elementAt(_selectedIndex), // [MỚI] Hiển thị theo Tab
      
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nhập khoản chi thu', // [MỚI] Tooltip cho nút nổi
        child: const Icon(Icons.add),
        onPressed: () => _startAddNewTransaction(context),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,//shifting->fixed
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
            icon: Icon(Icons.calendar_view_day),
            label: 'Tiện ích',
          ), 
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
        currentIndex: _selectedIndex, // [MỚI]
        onTap: _onItemTapped, // [MỚI]
      ),
    );
  }
}

class NewTransaction extends StatefulWidget {
  final Function(double, DateTime, CategoryType, String, bool) addTx; // [MỚI] thêm bool

  const NewTransaction(this.addTx, {super.key});

  @override
  State<NewTransaction> createState() => _NewTransactionState();
}

class _NewTransactionState extends State<NewTransaction> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _selectedDate;
  CategoryType _selectedCategory = CategoryType.food;
  bool _isExpense = true; // [MỚI] Mặc định là Chi tiêu

  @override
  void initState() {
    super.initState();
    _selectedCategory = CategoryType.food;
  }

  void _submitData() {
    if (_amountController.text.isEmpty) return;
    final enteredAmount = double.tryParse(_amountController.text) ?? 0;

    if (enteredAmount <= 0 || _selectedDate == null) {
      return;
    }

    // [MỚI] Nếu là Thu nhập, tự động gán loại là 'income'
    final finalCategory = _isExpense ? _selectedCategory : CategoryType.income;

    widget.addTx(
      enteredAmount,
      _selectedDate!,
      finalCategory,
      _noteController.text,
      _isExpense, // [MỚI]
    );

    Navigator.of(context).pop();
  }

  void _presentDatePicker() {
    showDatePicker(//hiện date chọn
      context: context,//đè lên "chưa chọn ngày!"
      initialDate: DateTime.now(),//mặc định
      firstDate: DateTime(2020),// giới hạn quá khứ
      lastDate: DateTime.now(),// không cho chọn ngày mai
      
      //Cài đặt ngôn ngữ cho Popup chọn ngày
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
    // [MỚI] Lọc danh sách chỉ lấy các loại Chi tiêu (bỏ income)
    final List<CategoryType> expenseCategories = CategoryType.values.where((cat) {
      return cat != CategoryType.income;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // [MỚI] THANH CHUYỂN ĐỔI THU / CHI
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Loại giao dịch:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              ToggleButtons(
                isSelected: [_isExpense, !_isExpense],
                onPressed: (int index) {
                  setState(() {
                    _isExpense = index == 0;
                    // Reset lại category mặc định khi chuyển qua Chi tiêu
                    if (_isExpense) {
                       _selectedCategory = CategoryType.food;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white,
                fillColor: _isExpense ? Colors.redAccent : Colors.green,
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Chi tiêu')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Thu nhập')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),

          TextField(
            decoration: const InputDecoration(labelText: 'Số tiền'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          const SizedBox(height: 15),
          
          // [MỚI] LOGIC ẨN/HIỆN DROPDOWN
          // Nếu là Chi tiêu -> Hiện Dropdown
          // Nếu là Thu nhập -> Ẩn Dropdown, hiện chữ "Thu nhập tổng hợp"
          if (_isExpense)
            Row(
              children: [
                const Text('Loại chi tiêu: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<CategoryType>(
                    isExpanded: true,
                    value: _selectedCategory,
                    items: expenseCategories.map((CategoryType type) {
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
                ),
              ],
            )
          else
             // [MỚI] Giao diện khi chọn Thu nhập
            Row(
              children: [
                 const Text('Danh mục: ', style: TextStyle(fontSize: 16)),
                 const SizedBox(width: 10),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                   decoration: BoxDecoration(
                     color: Colors.green.withOpacity(0.1),
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: Colors.green),
                   ),
                   child: const Row(
                     children: [
                       Icon(Icons.attach_money, color: Colors.green, size: 20),
                       SizedBox(width: 8),
                       Text('Thu nhập tổng hợp', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                     ],
                   ),
                 )
              ],
            ),

          const SizedBox(height: 15),
          
          TextField(
            decoration: const InputDecoration(
              labelText: 'Ghi chú (Tùy chọn)',
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
              // [MỚI] Đổi màu nút theo loại
              backgroundColor: _isExpense ? Theme.of(context).colorScheme.primary : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(_isExpense ? 'Thêm Khoản Chi' : 'Thêm Thu Nhập'),
          ),
        ],
      ),
    );
  }
}