import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('shopping_box');
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  final _shoppingBox = Hive.box('shopping_box');
  bool _errorFlag = false;

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  Future<void> _createItem(Map<String, dynamic> newItem) async {
    await _shoppingBox.add(newItem);
    _refreshItems();
  }

  void _refreshItems() {
    final data = _shoppingBox.keys.map((key) {
      final item = _shoppingBox.get(key);
      return {
        "key": key,
        "name": item["name"],
        "quantity": item["quantity"],
        "imgUrl": item["imgUrl"]
      };
    }).toList();

    setState(() {
      _items = data.reversed.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hive-App'),
      ),
      body: ListView.builder(
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final currentItem = _items[index];

            return Card(
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        currentItem['name'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    subtitle: CachedNetworkImage(
                      imageUrl: currentItem['imgUrl'],
                      errorWidget: (context, url, error) {
                        return Container(
                          padding: EdgeInsets.all(20),
                          color: Colors.white,
                          width: 400,
                          child: Image.asset(
                            'assets/store.png',
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            showForm(context, currentItem['key']);
                          },
                          label: const Text("Edit"),
                          icon: const Icon(Icons.edit),
                        ),
                        const SizedBox(
                          width: 30,
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _deleteItem(
                                currentItem['key'], currentItem['name']);
                          },
                          label: const Text("Delete"),
                          icon: const Icon(Icons.delete),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.black,
                          child: Text(
                            currentItem['quantity'].toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showForm(context, null);
        },
        label: const Icon(Icons.add),
      ),
    );
  }

  void showForm(BuildContext ctx, int? itemKey) async {
    if (itemKey != null) {
      
      final existingItem =
          _items.firstWhere((element) => element['key'] == itemKey);
      _nameController.text = existingItem['name'];
      _quantityController.text = existingItem['quantity'];
      _urlController.text = existingItem['imgUrl'];
    } else {
      
      _nameController.clear();
      _quantityController.clear();
      _urlController.clear();
    }

    
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 15,
            left: 15,
            right: 15,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(hintText: 'Name'),
                onChanged: (_) => _resetErrorFlag(),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Quantity'),
                onChanged: (_) => _resetErrorFlag(),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(hintText: 'URL'),
                onChanged: (_) => _resetErrorFlag(),
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (_nameController.text.isNotEmpty &&
                          _quantityController.text.isNotEmpty &&
                          _urlController.text.isNotEmpty) {
                        if (itemKey == null) {
                          // Creating a new item
                          await _createItem({
                            "name": _nameController.text.trim(),
                            "quantity": _quantityController.text.trim(),
                            "imgUrl": _urlController.text,
                          });
                        } else {
                          // Updating an existing item
                          await _updateItem(itemKey, {
                            'name': _nameController.text.trim(),
                            'quantity': _quantityController.text.trim(),
                            'imgUrl': _urlController.text
                          });
                        }
                        Navigator.of(ctx).pop();
                      } else {
                        setState(() {
                          _errorFlag = true;
                        });
                      }
                    },
                    label: (itemKey != null)
                        ? Text(
                            _errorFlag ? "Enter All Fields" : "Update Item",
                            style: const TextStyle(color: Colors.white),
                          )
                        : const Text(
                            "Create Item",
                            style: TextStyle(color: Colors.white),
                          ),
                    icon: const Icon(
                      Icons.save,
                      color: Colors.white,
                    ),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        _errorFlag ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateItem(int itemKey, Map<String, dynamic> item) async {
    await _shoppingBox.put(itemKey, item);
    _refreshItems();
  }

  Future<void> _deleteItem(int itemKey, String name) async {
    await _shoppingBox.delete(itemKey);
    _refreshItems();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("$name Has been Deleted")));
  }

  void _resetErrorFlag() {
    if (_errorFlag) {
      setState(() {
        _errorFlag = false;
      });
    }
  }
}
