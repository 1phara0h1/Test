import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(CalorieApp());

class CalorieApp extends StatefulWidget {
  @override
  State<CalorieApp> createState() => _CalorieAppState();
}

class _CalorieAppState extends State<CalorieApp> {
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDark = prefs.getBool('isDark') ?? false);
  }

  void _toggleTheme(bool value) async {
    setState(() => _isDark = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        brightness: _isDark ? Brightness.dark : Brightness.light,
      ),
      home: HomePage(onThemeChanged: _toggleTheme, isDark: _isDark),
    );
  }
}

class HomePage extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDark;
  HomePage({required this.onThemeChanged, required this.isDark});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _meals = [];
  int _totalCalories = 0;
  int _goal = 2000;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _goal = prefs.getInt('goal') ?? 2000;
      final String? mealsString = prefs.getString('meals');
      if (mealsString != null) {
        _meals = List<Map<String, dynamic>>.from(json.decode(mealsString));
        _totalCalories = _meals.fold(0, (sum, item) => sum + (item['calories'] as int));
      }
    });
  }

  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('meals', json.encode(_meals));
    await prefs.setInt('goal', _goal);
  }

  void _addMeal(String name, int calories) {
    setState(() {
      _meals.insert(0, {'name': name, 'calories': calories});
      _totalCalories += calories;
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Дневник питания'),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.onThemeChanged(!widget.isDark),
          ),
          IconButton(icon: Icon(Icons.settings), onPressed: _changeGoal),
        ],
      ),
      body: Column(
        children: [
          _buildStatusHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _meals.length,
              itemBuilder: (context, index) => Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(_meals[index]['name']),
                  trailing: Text("${_meals[index]['calories']} ккал"),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusHeader() {
    double progress = (_totalCalories / _goal).clamp(0.0, 1.0);
    return Container(
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text("Съедено: $_totalCalories / $_goal ккал", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(10)),
        ],
      ),
    );
  }

  void _changeGoal() {
    TextEditingController ctrl = TextEditingController(text: _goal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Изменить цель'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
          ElevatedButton(onPressed: () {
            setState(() => _goal = int.tryParse(ctrl.text) ?? 2000);
            _saveData();
            Navigator.pop(context);
          }, child: Text('Сохранить')),
        ],
      ),
    );
  }

  void _showAddDialog() {
    String name = '';
    int cals = 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Добавить еду"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(decoration: InputDecoration(hintText: "Что съели?"), onChanged: (v) => name = v),
          TextField(decoration: InputDecoration(hintText: "Калории"), keyboardType: TextInputType.number, onChanged: (v) => cals = int.tryParse(v) ?? 0),
        ]),
        actions: [
          ElevatedButton(onPressed: () { _addMeal(name, cals); Navigator.pop(context); }, child: Text("Добавить"))
        ],
      ),
    );
  }
}
