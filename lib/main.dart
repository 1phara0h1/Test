import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart'; // Импорт графиков

void main() => runApp(CalorieApp());

class CalorieApp extends StatefulWidget {
  @override
  State<CalorieApp> createState() => _CalorieAppState();
}

class _CalorieAppState extends State<CalorieApp> {
  bool _isDark = false;

  void _toggleTheme(bool value) {
    setState(() => _isDark = value);
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

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.dark_mode),
            title: Text("Темная тема"),
            trailing: Switch(value: widget.isDark, onChanged: (v) {
              widget.onThemeChanged(v);
              Navigator.pop(context);
            }),
          ),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text("Изменить цель (ккал)"),
            onTap: () {
              Navigator.pop(context);
              _changeGoal();
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  void _changeGoal() {
    TextEditingController _controller = TextEditingController(text: _goal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Дневная цель'),
        content: TextField(controller: _controller, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('ОК')),
          ElevatedButton(onPressed: () {
            setState(() => _goal = int.tryParse(_controller.text) ?? 2000);
            _saveData();
            Navigator.pop(context);
          }, child: Text('Сохранить')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Трекер калорий'),
        actions: [IconButton(icon: Icon(Icons.settings), onPressed: _showSettings)],
      ),
      body: Column(
        children: [
          _buildChartCard(),
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

  Widget _buildChartCard() {
    return Container(
      height: 200,
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: _totalCalories.toDouble(),
                    color: Colors.blueAccent,
                    title: '',
                    radius: 20,
                  ),
                  PieChartSectionData(
                    value: (_goal - _totalCalories).clamp(0, _goal).toDouble(),
                    color: Colors.grey[300],
                    title: '',
                    radius: 15,
                  ),
                ],
                centerSpaceRadius: 40,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _indicator(Colors.blueAccent, "Съедено"),
              _indicator(Colors.grey[300]!, "Осталось"),
              SizedBox(height: 10),
              Text("$_totalCalories / $_goal", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _indicator(Color color, String text) {
    return Row(children: [
      Container(width: 12, height: 12, color: color),
      SizedBox(width: 8),
      Text(text, style: TextStyle(fontSize: 12)),
    ]);
  }

  void _showAddDialog() {
    String name = '';
    int cals = 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Добавить"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(decoration: InputDecoration(hintText: "Продукт"), onChanged: (v) => name = v),
          TextField(decoration: InputDecoration(hintText: "Ккал"), keyboardType: TextInputType.number, onChanged: (v) => cals = int.tryParse(v) ?? 0),
        ]),
        actions: [ElevatedButton(onPressed: () { _addMeal(name, cals); Navigator.pop(context); }, child: Text("Добавить"))],
      ),
    );
  }
}
