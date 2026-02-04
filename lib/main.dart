import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(CalorieApp());

class CalorieApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        brightness: Brightness.light,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _meals = [];
  int _totalCalories = 0;
  final int _goal = 2000; // Твоя цель на день

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? mealsString = prefs.getString('meals');
    if (mealsString != null) {
      setState(() {
        _meals = List<Map<String, dynamic>>.from(json.decode(mealsString));
        _totalCalories = _meals.fold(0, (sum, item) => sum + (item['calories'] as int));
      });
    }
  }

  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('meals', json.encode(_meals));
  }

  void _addMeal(String name, int calories) {
    setState(() {
      _meals.insert(0, {'name': name, 'calories': calories});
      _totalCalories += calories;
    });
    _saveData();
  }

  void _deleteMeal(int index) {
    setState(() {
      _totalCalories -= _meals[index]['calories'] as int;
      _meals.removeAt(index);
    });
    _saveData();
  }

  void _reset() async {
    setState(() {
      _meals.clear();
      _totalCalories = 0;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('meals');
  }

  @override
  Widget build(BuildContext context) {
    double progress = _totalCalories / _goal;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Мои Калории 🍏', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _reset)],
      ),
      body: Column(
        children: [
          // Блок с прогрессом
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey[200],
                        color: _totalCalories > _goal ? Colors.red : Colors.green,
                      ),
                    ),
                    Text('${(progress * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(width: 25),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Осталось:', style: TextStyle(color: Colors.grey)),
                    Text('${_goal - _totalCalories} ккал', 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, 
                      color: _totalCalories > _goal ? Colors.red : Colors.black)),
                    Text('из $_goal ккал', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          
          // Список еды
          Expanded(
            child: ListView.builder(
              itemCount: _meals.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[50],
                      child: Icon(Icons.fastfood, color: Colors.green),
                    ),
                    title: Text(_meals[index]['name'], style: TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_meals[index]['calories']} ккал', style: TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[300]),
                          onPressed: () => _deleteMeal(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        label: Text('Добавить еду'),
        icon: Icon(Icons.add),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    String name = '';
    int calories = 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Что съели?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Название (напр. Банан)'),
              onChanged: (value) => name = value,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Калории'),
              keyboardType: TextInputType.number,
              onChanged: (value) => calories = int.tryParse(value) ?? 0,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty && calories > 0) _addMeal(name, calories);
              Navigator.pop(context);
            },
            child: Text('Добавить'),
          ),
        ],
      ),
    );
  }
}
