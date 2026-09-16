import 'package:flutter/material.dart';
import 'Student.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {



    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  bool showStudent = false;
  Student test = Student();
  void testStudent() {
    print(test.getName());
    print(test.getStudentId());
    print(test.getMajor());
    print(test.getAge().toString);
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
  child: GestureDetector(
    onTap: () {
      setState(() {
        showStudent = true;
      });
    },
    child: Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(15),
      ),
      child: showStudent
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Thông tin sinh viên",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                Text("Họ tên: ${test.getName()}"),
                Text("MSSV: ${test.getStudentId()}"),
                Text("Ngành: ${test.getMajor()}"),
                Text("Tuổi: ${test.getAge()}"),
              ],
            )
          : const Text(
              "Đại học Phenikaa",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
    ),
  ),
),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}




