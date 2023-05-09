import 'package:flutter/material.dart';
import 'scenarios.dart';
import 'result_screen.dart';
import 'dart:async';

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
  //scenario handling and text related variables
  List<Scenario> scenarios = allScenarios;
  Scenario currentScenario = introScenario;
  List<String> textList = introScenario.introDialog;
  String currentText = "Hello!";
  QuestionStatus currentStatus = QuestionStatus.intro;
  Option leftOption = introScenario.options[0];
  Option rightOption = introScenario.options[0];

  //timer and animation related variables
  Timer answerTime = Timer(const Duration(microseconds: 1), () => {});
  int secondsLeft = 0;
  //point and power-up related variables
  int points = 100;
  bool retryActive = false;
  bool timeExtended = false;

  //hexad results
  final Map<HexadType, double> hexadResults = {
    for (var type in HexadType.values) type: 0.0
  };

  void handleTimeout() {
    if (!retryActive) {
      List<String> selection = ["left", "right"];
      selection.shuffle();
      _optionSelected(selection.first);
    } else {
      retryActive = false;
      allScenarios.add(currentScenario);
      currentStatus = QuestionStatus.outro;
      setState(() {
        currentText = "Oops!";
        textList = [
          "Looks like you ran out of time, but you had a Retry ready.",
          "We'll return to this question later.",
          "Let's move on to the next one."
        ];
      });
    }
  }

  void timerTick(Timer timer) {
    if (timer.tick < 4) return;
    if (secondsLeft == 0) {
      setState(() {
        answerTime.cancel();
        handleTimeout();
      });
    } else {
      setState(() {
        secondsLeft--;
      });
    }
  }

  void _optionSelected(String selection) {
    assert(selection == "left" || selection == "right");
    if (answerTime.tick < 2) {
      return;
    } //cancel button press if 1 second hasn't elapsed yet.
    answerTime.cancel();
    if (secondsLeft >= 5) {
      points += 10;
    } else if (secondsLeft > 0) {
      points += 5;
    }
    timeExtended = false;
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
    if (currentStatus == QuestionStatus.answering) return;
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
          if (timeExtended) {
            secondsLeft = 20;
          } else {
            secondsLeft = 10;
          }
          answerTime = Timer.periodic(const Duration(seconds: 1), timerTick);
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

  void _timeplus() {
    setState(() {
      points -= 20;
      secondsLeft += 10;
      timeExtended = true;
    });
  }

  void _retry() {
    setState(() {
      retryActive = true;
      points -= 50;
    });
  }

  void _flex() {
    setState(() {
      //points-=100;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Center(child: Text("Weird flex, but ok😎"))));
  }

  void _switch() {
    setState(() {
      points -= 5;
      Option temp = rightOption;
      rightOption = leftOption;
      leftOption = temp;
    });
  }

  void _sendhelp() {
    setState(() {
      points -= 75;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Center(
            child: Text(
      "Nice, we'll send your help to another player (or later, if you're currently offline)!",
      textAlign: TextAlign.center,
    ))));
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
      drawer: Drawer(
        backgroundColor: const Color.fromRGBO(255, 255, 255, 0.1),
        width: 100,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Points:\n$points",
                textScaleFactor: 1.7,
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: points >= 20 && !timeExtended ? _timeplus : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [Text("+"), Icon(Icons.hourglass_bottom)],
                ),
              ),
              const Text(
                "Time+:\n20p",
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: points > 50 && !retryActive ? _retry : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [Text('+'), Icon(Icons.replay_outlined)],
                ),
              ),
              const Text(
                "Retry:\n50p",
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: points >= 100 ? _flex : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [Icon(Icons.surfing)],
                ),
              ),
              const Text(
                "Flex:\n100p",
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed:
                    points >= 5 && currentStatus == QuestionStatus.answering
                        ? _switch
                        : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [Icon(Icons.swap_horiz)],
                ),
              ),
              const Text(
                "Switch:\n5p",
                textAlign: TextAlign.center,
              ),
              ElevatedButton(
                onPressed: points >= 75 ? _sendhelp : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [Icon(Icons.local_hospital)],
                ),
              ),
              const Text(
                "Send Help:\n75p",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
                Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.timer,
                        color: Colors.black.withAlpha(40),
                        size: 50,
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: answerTime.isActive ? 1 : 0,
                      duration: const Duration(seconds: 1),
                      child: SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.inversePrimary),
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(seconds: 1),
                                  height: 10,
                                  color: secondsLeft > 6
                                      ? Colors.green
                                      : secondsLeft > 3
                                          ? Colors.orange
                                          : Colors.red,
                                  width: timeExtended
                                      ? MediaQuery.of(context).size.width *
                                          (secondsLeft / 20)
                                      : MediaQuery.of(context).size.width *
                                          (secondsLeft / 10),
                                ),
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 1000),
                                  scale: answerTime.tick < 1
                                      ? 2
                                      : answerTime.tick < 5
                                          ? 0.75
                                          : 1,
                                  child: Icon(
                                    Icons.timer,
                                    color: Colors.black.withAlpha(40),
                                    size: 50,
                                  ),
                                ),
                                Text(
                                  secondsLeft.toString(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                    height: MediaQuery.of(context).size.height - 330,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.tertiaryContainer),
                      child: Center(
                        child: Text("Graphic Area",
                            style:
                                TextStyle(color: Colors.black.withAlpha(100))),
                      ),
                    )),
              ],
            ),
            Column(
              children: [
                Visibility(
                    visible: false,
                    child: SizedBox(
                        height: 100,
                        width: double.infinity,
                        child: DecoratedBox(
                            decoration: const BoxDecoration(),
                            child: Text(
                              "Option Area",
                              style:
                                  TextStyle(color: Colors.black.withAlpha(50)),
                            )))),
                AnimatedOpacity(
                  opacity: currentStatus == QuestionStatus.answering ? 1.0 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  currentStatus == QuestionStatus.answering
                                      ? () => _optionSelected("left")
                                      : null,
                              child: Text(
                                leftOption.optionText,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton(
                                onPressed:
                                    currentStatus == QuestionStatus.answering
                                        ? () => _optionSelected("right")
                                        : null,
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
