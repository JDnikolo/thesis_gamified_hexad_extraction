import 'package:flutter/material.dart';
import 'scenarios.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.results});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final Map<HexadType, double> results;
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var type in widget.results.entries)
            Column(
              children: [
                Center(
                  child: Text(
                    type.key.toString(),
                  ),
                ),
                Center(
                  child: Text(
                    type.value.toString(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
