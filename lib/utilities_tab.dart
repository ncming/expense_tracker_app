import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'models.dart'; // Import file models của bạn

class UtilitiesTab extends StatefulWidget {
  final String userId;
  const UtilitiesTab({super.key, required this.userId});

  @override
  // [SỬA] Bỏ dấu gạch dưới để public State
  State<UtilitiesTab> createState() => UtilitiesTabState(); 
}

// [SỬA] Bỏ dấu gạch dưới
class UtilitiesTabState extends State<UtilitiesTab> {
  final List<IconData> _availableIcons = [
    Icons.fastfood, Icons.shopping_bag, Icons.home, Icons.directions_bus,
    Icons.medical_services, Icons.school, Icons.sports_esports, Icons.pets,
    Icons.card_giftcard, Icons.attach_money, Icons.work, Icons.savings,
    Icons.build, Icons.local_cafe, Icons.flight, Icons.phone_android,
    Icons.shopping_cart, Icons.fitness_center, Icons.local_hospital, Icons.movie,
    Icons.checkroom, Icons.face, Icons.local_bar, Icons.lightbulb, Icons.water_drop
  ];

  final List<Color> _availableColors = [
    Colors.red, Colors.orange, Colors.amber, Colors.green, Colors.teal,
    Colors.blue, Colors.indigo, Colors.purple, Colors.pink, Colors.brown, Colors.grey, Colors.black,
    Colors.cyan, Colors.lime, Colors.deepPurple, Colors.blueGrey
  ];

  // [SỬA] Bỏ dấu gạch dưới để hàm này thành public
  void addOrEditCategory({CategoryItem? item, required bool isExpense}) {
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
                      onTap: () => setStateDialog(() => selectedIcon = icon),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: selectedIcon == icon ? Colors.blueGrey.withOpacity(0.2) : null, shape: BoxShape.circle, border: selectedIcon == icon ? Border.all(color: Colors.blueGrey, width: 2) : null),
                        child: Icon(icon, color: Colors.black87),
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 20),
                  const Text('Chọn Màu sắc:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 15, runSpacing: 10, children: _availableColors.map((color) {
                    return GestureDetector(
                      onTap: () => setStateDialog(() => selectedColor = color),
                      child: Container(width: 32, height: 32, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: selectedColor == color ? Border.all(width: 3, color: Colors.black45) : null)),
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
                  final data = CategoryItem(id: '', name: nameController.text, iconCode: selectedIcon.codePoint, colorValue: selectedColor.value, isExpense: isExpense).toMap();
                  final colRef = FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('categories');
                  if (item == null) { colRef.add(data); } else { colRef.doc(item.id).update(data); }
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
    FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('categories').doc(id).delete();
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final categories = snapshot.data!.docs.map((doc) => CategoryItem.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(labelColor: Colors.blueGrey, indicatorColor: Colors.blueGrey, tabs: [Tab(text: "Chi tiêu"), Tab(text: "Thu nhập")]),
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
      },
    );
  }

  Widget _buildCategoryList(List<CategoryItem> items, bool isExpense) {
    if (items.isEmpty) return const Center(child: Text("Chưa có danh mục nào"));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Color(item.colorValue).withOpacity(0.2), child: Icon(IconData(item.iconCode, fontFamily: 'MaterialIcons'), color: Color(item.colorValue))),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // [SỬA] Gọi hàm addOrEditCategory mới (không có dấu _)
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => addOrEditCategory(item: item, isExpense: item.isExpense)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteConfirm(item.id)),
              ],
            ),
          ),
        );
      },
    );
  }
}