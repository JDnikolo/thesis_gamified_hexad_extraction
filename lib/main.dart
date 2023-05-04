import 'package:flutter/material.dart';
import 'scenarios.dart';
import 'resultScreen.dart';

enum QuestionStatus { intro, answering, outro }

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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Scenario> scenarios = allScenarios;
  Scenario currentScenario = introScenario;
  List<String> textList = introScenario.introDialog;
  String currentText = "Hello!";
  QuestionStatus currentStatus = QuestionStatus.intro;
  Option leftOption = introScenario.options[0];
  Option rightOption = introScenario.options[0];

  final Map<HexadType, double> hexadResults = {
    for (var type in HexadType.values) type: 0.0
  };


  void _optionSelected(String selection) {

    Option selectedOption = introScenario.options[1];
    if (selection == "left") {
      selectedOption = leftOption;
    }
    if (selection == "right") {
      selectedOption = rightOption;
    }
    double temp = hexadResults[selectedOption.primaryType] ?? 0.0;
    temp += selectedOption.primaryTypeLoad;
    hexadResults[selectedOption.primaryType] = temp;

    temp = hexadResults[selectedOption.secondaryType] ?? 0.0;
    temp += selectedOption.secondaryTypeLoad;
    hexadResults[selectedOption.secondaryType] = temp;
    debugPrint(hexadResults.entries.toString());
    setState(() {
      currentStatus = QuestionStatus.outro;
      textList = selectedOption.optionSelectDialog;
      currentText = textList.first;
      textList.removeAt(0);
    });
  }

  void _nextDialog() {
    debugPrint("Dialog Area Pressed.");
    setState(() {
      if (currentStatus == QuestionStatus.intro) {
        if (textList.length > 1) {
          debugPrint("Advancing Dialog.");
          currentText = textList.first;
          textList.removeAt(0);
        } else {
          debugPrint("Advancing Dialog and moving to answering mode.");
          currentText = textList.first;
          textList.removeAt(0);
          currentScenario.options.shuffle();
          leftOption = currentScenario.options[0];
          rightOption = currentScenario.options[1];
          currentStatus = QuestionStatus.answering;
          //TODO: change to answer mode
        }
      }
      if (currentStatus == QuestionStatus.outro) {
        if (textList.isNotEmpty) {
          debugPrint("Advancing Dialog.");
          currentText = textList.first;
          textList.removeAt(0);
        } else {
          debugPrint("Moving to intro mode of next question.");
          if (scenarios.isNotEmpty) {
            scenarios.shuffle();
            currentScenario = scenarios.first;
            textList = currentScenario.introDialog;
            scenarios.removeAt(0);
            currentText = textList.first;
            textList.removeAt(0);
            currentStatus = QuestionStatus.intro;
          } else {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => ResultScreen(results: hexadResults)),
                (route) => false);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.primary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 50,
                  child:DecoratedBox(
                    decoration:BoxDecoration(
                        color: Theme.of(context).colorScheme.inversePrimary),
                        child:Text("Timer Area",style: TextStyle(color: Colors.black.withAlpha(100))),)
                ),
                SizedBox(
                    height: MediaQuery. of(context). size. height-330,
                    child:DecoratedBox(
                      decoration:BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiaryContainer),
                      child:Text("Graphic Area",style: TextStyle(color: Colors.black.withAlpha(100))),)
                ),
              ],
            ),
            Column(
              children: [
                Visibility(
                    visible: currentStatus != QuestionStatus.answering,
                    child:  SizedBox(height: 100,width: double.infinity,child:DecoratedBox(
                      decoration: BoxDecoration(),
                    child: Text("Option Area",style: TextStyle(color: Colors.black.withAlpha(50)),)))),
                Visibility(
                  visible: currentStatus == QuestionStatus.answering,
                  child: SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                                onPressed: () => _optionSelected("left"),
                                child: Text(
                                  leftOption.optionText,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.visible,
                                ),),),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _optionSelected("right"),
                                  child: Text(
                                rightOption.optionText,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.visible,
                              )),
                            ),
                        ],
                      )),
                ),
                GestureDetector(
                  onTap: _nextDialog,
                  child: SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.inversePrimary),
                        child: Center(
                          child: Text(
                            currentText,
                            textAlign: TextAlign.center,
                          ),
                        )),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
