import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(CalorieApp());

class CalorieApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueAccent),
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
      _meals.insert(0, {'name': name, 'calories': calories, 'time': DateTime.now().toString()});
      _totalCalories += calories;
    });
    _saveData();
  }

  void _changeGoal() {
    TextEditingController _controller = TextEditingController(text: _goal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Изменить цель'),
        content: TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffixText: 'ккал'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              setState(() => _goal = int.tryParse(_controller.text) ?? 2000);
              _saveData();
              Navigator.pop(context);
            },
            child: Text('ОК'),
          ),
        ],
      ),
    );
  }

  String _getMotivationText() {
    double p = _totalCalories / _goal;
    if (p == 0) return "Начнем день с завтрака? 🍳";
    if (p < 0.5) return "Отличное начало! Продолжай в том же духе. 👍";
    if (p < 0.8) return "Уже неплохо поели, место еще есть. 🍎";
    if (p <= 1.0) return "Почти норма! Выбирай перекусы мудро. 🥗";
    return "Лимит превышен! Пора на прогулку. 🏃‍♂️";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Дневник питания', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [IconButton(icon: Icon(Icons.settings), onPressed: _changeGoal)],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildStatusCard(),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Text("История сегодня", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Spacer(),
                      TextButton(onPressed: () => setState(() { _meals.clear(); _totalCalories = 0; _saveData(); }), child: Text("Очистить")),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildMealCard(index),
              childCount: _meals.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        label: Text("Добавить еду"),
        icon: Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blueAccent, Colors.lightBlue]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Text(_getMotivationText(), style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 15),
          LinearProgressIndicator(
            value: (_totalCalories / _goal).clamp(0.0, 1.0),
            backgroundColor: Colors.white24,
            color: Colors.white,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statColumn("Съедено", _totalCalories.toString()),
              _statColumn("Цель", _goal.toString()),
              _statColumn("Осталось", (_goal - _totalCalories).toString()),
            ],
          )
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildMealCard(int index) {
    final meal = _meals[index];
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: Icon(Icons.fastfood, color: meal['calories'] > 500 ? Colors.orange : Colors.blue),
        title: Text(meal['name']),
        subtitle: Text("Сегодня"),
        trailing: Text("${meal['calories']} ккал", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddDialog() {
    String name = '';
    int cals = 0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(hintText: "Название"), onChanged: (v) => name = v),
            TextField(decoration: InputDecoration(hintText: "Калории"), keyboardType: TextInputType.number, onChanged: (v) => cals = int.tryParse(v) ?? 0),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () { if(name.isNotEmpty) _addMeal(name, cals); Navigator.pop(context); }, child: Text("Сохранить")),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
