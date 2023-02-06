import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/percent_indicator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prodigy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xffFF725E),
          secondary: const Color(0xff1A2E35),
        ),
        fontFamily: 'Poppins',
      ),
      home: const WrapperClass(),
    );
  }
}

class WrapperClass extends StatefulWidget {
  const WrapperClass({Key? key}) : super(key: key);
  @override
  State<WrapperClass> createState() => _WrapperClassState();
}

class _WrapperClassState extends State<WrapperClass> {
  bool isOldUser = false;

  void _checkIfOldUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    if (name != null) {
      setState(() {
        isOldUser = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkIfOldUser();
  }

  @override
  Widget build(BuildContext context) {
    return isOldUser ? const MyHomePage() : const UserDetails();
  }
}

class UserDetails extends StatefulWidget {
  const UserDetails({Key? key}) : super(key: key);

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void _dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void onSubmit(String value) async {
    var trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      setState(() {
        _nameController.text = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid name'),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }
    setState(() {
      _nameController.text = trimmedValue;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', trimmedValue);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Welcome to Prodigy $trimmedValue!'),
        backgroundColor: const Color(0xffFF725E),
      ),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MyHomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 200,
              width: 200,
              child: Lottie.asset('assets/lottie/welcome.json'),
            ),
            const SizedBox(height: 20),
            const Text(
              'May I have your name?',
              style: TextStyle(fontSize: 20.0),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Name', border: OutlineInputBorder()),
              onSubmitted: onSubmit,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onSubmit(_nameController.text),
        tooltip: 'Submit',
        child: const Icon(Icons.arrow_forward_ios),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TextEditingController _taskController;
  var _selectedDate;
  var _selectedTime;

  var user_name = '';
  var user_points = 0;
  var taskList = [];
  var totalTask = 0, completedTask = 0;

  void initDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      var userName = prefs.getString('user_name') ?? '';
      user_name = userName.split(' ')[0];
      user_points = prefs.getInt('user_points') ?? 0;
      var jsonString = prefs.getString('task_list') ?? '[]';
      taskList = jsonDecode(jsonString);
      totalTask = taskList.length;
      completedTask =
          taskList.where((element) => element['isDone'] == true).length;
    });
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const WrapperClass(),
      ),
    );
  }

  Future<void> _selectDate(onCompletion) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate == null ? DateTime.now() : _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2101));
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      onCompletion();
    }
  }

  Future<void> _selectTime(onCompletion) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime == null ? TimeOfDay.now() : _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      onCompletion();
    }
  }

  void addTask() async {
    var trimmedTask = _taskController.text.trim();
    if (trimmedTask.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        taskList.add({
          'task': trimmedTask,
          'date': _selectedDate == null ? null : _selectedDate.toString(),
          'time': _selectedTime == null ? null : _selectedTime.toString(),
          'isDone': false
        });
        totalTask = taskList.length;
        _taskController.text = '';
        _selectedDate = null;
        _selectedTime = null;
      });
      await prefs.setString('task_list', jsonEncode(taskList));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $trimmedTask to your list'),
          backgroundColor: const Color(0xffFF725E),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid task'),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  void cancelTask() {
    setState(() {
      _taskController.text = '';
      _selectedDate = null;
      _selectedTime = null;
    });
    Navigator.of(context).pop();
  }

  void _showModal(double height, double width) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        builder: (BuildContext context) {
          bool isDateSelected = _selectedDate != null;
          bool isTimeSelected = _selectedTime != null;
          
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Padding(
                padding: MediaQuery.of(context).viewInsets,
                child: Container(
                  height: height * 0.45,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Add a new task',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextField(
                        controller: _taskController,
                        decoration: const InputDecoration(
                            labelText: 'Task', border: OutlineInputBorder()),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => {
                              _selectDate(() => {
                                    setState(() {
                                      isDateSelected = true;
                                    })
                                  }),
                            },
                            style: ElevatedButton.styleFrom(
                              shape: const StadiumBorder(),
                              minimumSize: Size(width * 0.40, 0),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(5.0),
                              child: isDateSelected
                                  ? Text(DateFormat('dd MMM yyyy')
                                      .format(_selectedDate))
                                  : const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xff1A2E35),
                                    ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => {
                              _selectTime(() => {
                                    setState(() {
                                      isTimeSelected = true;
                                    })
                                  }),
                            },
                            style: ElevatedButton.styleFrom(
                              shape: const StadiumBorder(),
                              minimumSize: Size(width * 0.40, 0),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(5.0),
                              child: isTimeSelected
                                  ? Text(
                                      _selectedTime.toString().substring(10, 15))
                                  : const Icon(
                                      Icons.punch_clock,
                                      color: Color(0xff1A2E35),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: cancelTask,
                            icon: Icon(Icons.close),
                            color: Colors.red,
                          ),
                          IconButton(
                            onPressed: addTask,
                            icon: Icon(Icons.check),
                            color: Colors.green,
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        });
  }

  void deleteTask(int index) async {
    final prefs = await SharedPreferences.getInstance();
    var isCompleted = taskList[index]["isDone"];
    if (isCompleted) {
      user_points -= 10;
      completedTask -= 1;
    }
    setState(() {
      taskList.removeAt(index);
      totalTask = taskList.length;
      completedTask = completedTask;
      user_points = user_points;
    });
    await prefs.setString('task_list', jsonEncode(taskList));
  }

  void updateTask(int index) async {
    final prefs = await SharedPreferences.getInstance();
    taskList[index]["isDone"] = !taskList[index]["isDone"];
    bool isCompleted = taskList[index]["isDone"];
    if (isCompleted) {
      user_points += 10;
      completedTask += 1;
    } else {
      user_points -= 10;
      completedTask -= 1;
    }
    setState(() {
      user_points = user_points;
      taskList = taskList;
      totalTask = taskList.length;
      completedTask = completedTask;
    });
    await prefs.setInt('user_points', user_points);
    await prefs.setString('task_list', jsonEncode(taskList));
  }

  Widget TaskCard(task, index, deleteTask, updateTask) {
    String subtitle = '';
    bool isCompleted = task['isDone'];
    if (task['date'] != null && task['time'] != null) {
      subtitle =
          'Due on ${DateFormat('dd MMM yyyy').format(DateTime.parse(task['date']))} at ${task['time'].toString().substring(10, 15)}';
    } else if (task['date'] != null) {
      subtitle =
          'Due on ${DateFormat('dd MMM yyyy').format(DateTime.parse(task['date']))}';
    } else if (task['time'] != null) {
      subtitle = 'Due at ${task['time'].toString().substring(10, 15)}';
    }
    return Card(
      elevation: 5.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        leading: Checkbox(
          value: task['isDone'],
          fillColor: MaterialStateProperty.all(Color(0xffFF725E)),
          onChanged: (value) {
            updateTask(index);
          },
        ),
        title: Text(
          task['task'],
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: isCompleted ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
        trailing: IconButton(
          onPressed: () {
            deleteTask(index);
          },
          icon: Icon(Icons.delete),
          color: Colors.red,
        ),
      ),
    );
  }

  Widget EmptyList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.list_alt,
            size: 100.0,
            color: Color(0xffFF725E),
          ),
          const SizedBox(
            height: 10.0,
          ),
          const Text(
            'No tasks added yet',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController();
    initDetails();
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(height * 0.0),
        child: AppBar(
          backgroundColor: const Color(0xffFF725E),
          elevation: 0.0,
        ),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Container(
              height: height * 0.1,
              color: const Color(0xffFF725E),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        '👋 $user_name',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                        padding: const EdgeInsets.only(
                            left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: const Color(0xff1A2E35),
                        ),
                        child: Text(
                          '🔥 $user_points',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: IconButton(
                            onPressed: logout,
                            icon: const Icon(Icons.logout),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              height: 0.15 * height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    child: CircularPercentIndicator(
                      radius: 40.0,
                      lineWidth: 10.0,
                      percent: totalTask == 0 ? 0 : completedTask / totalTask,
                      progressColor: const Color(0xffFF725E),
                      backgroundColor: const Color(0xff1A2E35),
                      center: Text(
                        totalTask == 0
                            ? '0%'
                            : '${(completedTask / totalTask * 100).round()}%',
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50.0),
                          color: const Color(0xff1A2E35),
                        ),
                        child: Text(
                          'Completed : $completedTask',
                          style: const TextStyle(
                              color: Color(0xffFF725E),
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50.0),
                          color: const Color(0xff1A2E35),
                        ),
                        child: Text(
                          'Pending : ${totalTask - completedTask}',
                          style: const TextStyle(
                              color: Color(0xffFF725E),
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              height: 0.65 * height,
              child: taskList.length == 0
                  ? EmptyList()
                  : ListView.builder(
                      itemCount: taskList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return TaskCard(
                            taskList[index], index, deleteTask, updateTask);
                      },
                      physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      scrollDirection: Axis.vertical,
                    ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {_showModal(height, width)},
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
