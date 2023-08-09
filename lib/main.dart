import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'scenarios.dart';
import 'result_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';

enum QuestionStatus { intro, answering, outro }

List<Offset> climbPointOffsets = [];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Hexad Mountain'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class PathPainter extends CustomPainter {
  int lastLength = climbPointOffsets.length;
  @override
  void paint(Canvas canvas, Size size) {
    if (climbPointOffsets.isEmpty || climbPointOffsets.length == 1) return;
    lastLength = climbPointOffsets.length;
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2;
    Offset p1 = climbPointOffsets.first;
    Offset p2;
    for (int i = 1; i < climbPointOffsets.length; i++) {
      p2 = climbPointOffsets[i];
      canvas.drawLine(p1, p2, paint);
      p1 = p2;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return climbPointOffsets.length == lastLength;
  }
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  //scenario handling and text related variables
  List<Scenario> scenarios = allScenarios;
  Scenario currentScenario = introScenario;
  List<String> textList = introScenario.introDialog;
  String currentText = "Hello!";
  QuestionStatus currentStatus = QuestionStatus.intro;
  Option leftOption = introScenario.options[0];
  Option rightOption = introScenario.options[0];

  //timer and animation related variables
  Timer? answerTime;
  int secondsLeft = 0;
  bool textAnimationCompleted = true;
  bool flipAnimationCompleted = true;
  final FlipCardController flipController = FlipCardController();
  double climberIconOrientation = 1.0;
  List<Point<double>> climbPoints = [];
  double distanceFromBottom = 0, distanceFromLeft = 32;

  //point and power-up related variables
  int points = 0;
  bool retryActive = true;
  bool timeExtended = false;
  bool skipped = false;

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
        skipped = true;
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
        answerTime?.cancel();
        handleTimeout();
      });
    } else {
      setState(() {
        secondsLeft--;
      });
    }
  }

  void _optionSelected(String selection) async {
    assert(selection == "left" || selection == "right");
    if (answerTime!.tick < 2) {
      return;
    } //cancel button press if 1 second hasn't elapsed yet.
    answerTime?.cancel();
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
    for (var typeLoad in selectedOption.secondaryTypeLoads.entries) {
      temp = hexadResults[typeLoad.key] ?? 0.0;
      temp += typeLoad.value;
      hexadResults[typeLoad.key] = temp;
    }

    debugPrint(hexadResults.entries.toString());
    setState(() {
      currentStatus = QuestionStatus.outro;
      textList = selectedOption.optionSelectDialog;
      currentText = textList.first;
      textList.removeAt(0);
    });
  }

  void _nextDialog() async {
    if (currentStatus == QuestionStatus.answering ||
        !textAnimationCompleted ||
        !flipAnimationCompleted) return;
    textAnimationCompleted = false;
    if (currentStatus == QuestionStatus.intro) {
      if (textList.length > 1) {
        debugPrint("Advancing Dialog.");
        setState(() {
          currentText = textList.first;
        });
        textList.removeAt(0);
      } else {
        debugPrint("Advancing Dialog and moving to answering mode.");
        setState(() {
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
        });
      }
    }
    if (currentStatus == QuestionStatus.outro) {
      if (textList.isNotEmpty) {
        debugPrint("Advancing Dialog.");
        setState(() {
          currentText = textList.first;
        });
        textList.removeAt(0);
      } else {
        flipAnimationCompleted = false;
        debugPrint("Moving to intro mode of next question.");
        setState(() {
          currentText = "";
        });
        flipController.flipcard();
        await Future.delayed(const Duration(seconds: 1));
        if (!skipped) moveClimberIcon();
        skipped = false;
        await Future.delayed(const Duration(milliseconds: 1500));
        scenarios.shuffle();
        if (scenarios.isNotEmpty) {
          setState(() {
            currentScenario = scenarios.first;
            textList = List.from(currentScenario.introDialog);
            scenarios.removeAt(0);
            currentText = textList.first;
            textList.removeAt(0);
            currentStatus = QuestionStatus.intro;
          });
        } else {
          //TODO: add outro scenario
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => ResultScreen(results: hexadResults)),
              (route) => false);
        }
        flipController.flipcard();
        await Future.delayed(const Duration(seconds: 1));
        flipAnimationCompleted = true;
      }
    }
  }

  void moveClimberIcon() async {
    double newLeft;
    int rand;
    if (scenarios.isNotEmpty) {
      distanceFromBottom += 13;
      rand = Random().nextInt(200) - 100;
      if (rand <= 0 && rand > -50) rand = -50;
      if (rand > 0 && rand < 50) rand = 50;
      newLeft = distanceFromLeft + rand;
      if (newLeft < (distanceFromBottom + 50) / 1.6) {
        newLeft = (distanceFromBottom + 50) / 1.6;
      }
      if (newLeft > (distanceFromBottom - 492) / -1.6) {
        newLeft = (distanceFromBottom - 492) / -1.6;
      }
      if (distanceFromLeft > newLeft) {
        climberIconOrientation = -1.0;
      } else {
        climberIconOrientation = 1.0;
      }
      distanceFromLeft = newLeft;
      climbPoints.add(Point<double>(distanceFromLeft, distanceFromBottom));
      climbPointOffsets.add(Offset(distanceFromLeft + 10,
          (MediaQuery.of(context).size.height - 510) - distanceFromBottom + 5));
    } else {
      distanceFromBottom = 220;
      distanceFromLeft = 170;
      climbPointOffsets.add(Offset(distanceFromLeft,
          (MediaQuery.of(context).size.height - 510) - distanceFromBottom));
    }

    setState(() {});
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
      points -= 100;
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),
      ),
      drawer: Drawer(
        backgroundColor: Color.fromARGB(185, 255, 255, 255),
        width: 100,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
        child: Column(
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
                      opacity:
                          answerTime != null && answerTime!.isActive ? 1 : 0,
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
                                  scale:
                                      answerTime != null && answerTime!.tick < 1
                                          ? 2
                                          : answerTime != null &&
                                                  answerTime!.tick < 5
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
                FlipCard(
                  rotateSide: RotateSide.left,
                  onTapFlipping: false,
                  axis: FlipAxis.vertical,
                  controller: flipController,
                  backWidget: SizedBox(
                    height: MediaQuery.of(context).size.height - 330,
                    child: Center(
                      child: Stack(children: [
                        Image.asset(
                          "images/mountain.png",
                        ),
                        const Positioned(
                          bottom: 225,
                          left: 180,
                          child:
                              Icon(Icons.flag, color: Colors.orange, size: 30),
                        ),
                        CustomPaint(
                          painter: PathPainter(),
                        ),
                        for (Point<double> point in climbPoints)
                          Positioned(
                            left: point.x + 5,
                            bottom: point.y - 5,
                            child: const Icon(
                              Icons.circle,
                              color: Colors.red,
                              size: 10,
                            ),
                          ),
                        AnimatedPositioned(
                          bottom: distanceFromBottom,
                          left: distanceFromLeft,
                          duration: const Duration(milliseconds: 500),
                          child: Transform.scale(
                            scaleX: climberIconOrientation,
                            child: const Icon(
                              Icons.hiking_rounded,
                              size: 30,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  frontWidget: SizedBox(
                    height: MediaQuery.of(context).size.height - 330,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              fit: BoxFit.fill,
                              image: AssetImage(
                                  "images/scenario/${currentScenario.imageName}"))),
                    ),
                  ),
                ),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                style: const TextStyle(fontSize: 18),
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
                                  style: const TextStyle(fontSize: 18),
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
                            child: AnimatedTextKit(
                          key: ValueKey(currentText),
                          animatedTexts: [
                            TyperAnimatedText(
                              currentText,
                              textAlign: TextAlign.center,
                              textStyle: const TextStyle(fontSize: 23),
                              speed: const Duration(milliseconds: 25),
                            )
                          ],
                          onFinished: () {
                            textAnimationCompleted = true;
                          },
                          onTap: _nextDialog,
                          isRepeatingAnimation: false,
                          displayFullTextOnTap: true,
                        ))),
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
