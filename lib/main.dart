import 'package:flutter/material.dart';

void main() => runApp(CalorieApp());

class CalorieApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> _meals = [];
  int _totalCalories = 0;

  void _addMeal(String name, int calories) {
    setState(() {
      _meals.add({'name': name, 'calories': calories});
      _totalCalories += calories;
    });
  }

  void _reset() {
    setState(() {
      _meals.clear();
      _totalCalories = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Счетчик калорий 🍏'),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _reset)],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            child: Text(
              'Всего сегодня: $_totalCalories ккал',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _meals.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_meals[index]['name']),
                  trailing: Text('${_meals[index]['calories']} ккал'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    String name = '';
    int calories = 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить еду'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(hintText: 'Что съел?'),
              onChanged: (value) => name = value,
            ),
            TextField(
              decoration: InputDecoration(hintText: 'Сколько ккал?'),
              keyboardType: TextInputType.number,
              onChanged: (value) => calories = int.tryParse(value) ?? 0,
            ),
          ],
        ),
        actions: [
          TextButton(
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
