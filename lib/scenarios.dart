enum HexadType implements Type {
  socializer(name: "Socializer"),
  philanthropist(name: "Philanthropist"),
  freeSpirit(name: "Free Spirit"),
  achiever(name: "Achiever"),
  player(name: "Player"),
  disruptor(name: "Disruptor");

  const HexadType({required this.name});

  final String name;

  @override
  String toString() => name;
}

HexadType socializer = HexadType.socializer;
HexadType philanthropist = HexadType.philanthropist;
HexadType freeSpirit = HexadType.freeSpirit;
HexadType achiever = HexadType.achiever;
HexadType player = HexadType.player;
HexadType disruptor = HexadType.disruptor;

class Option {
  final String optionText;
  final List<String> optionSelectDialog;
  final HexadType primaryType;
  final double primaryTypeLoad;
  final HexadType secondaryType;
  final double secondaryTypeLoad;

  Option(this.optionText, this.optionSelectDialog, this.primaryType,
      this.primaryTypeLoad, this.secondaryType, this.secondaryTypeLoad) {
    assert(optionSelectDialog.isNotEmpty);
    assert(!primaryTypeLoad.isNegative && !secondaryTypeLoad.isNegative);
  }
}

class Scenario {
  final List<String> introDialog;
  final List<Option> options;

  Scenario(this.introDialog, this.options) {
    assert(options.length == 2);
  }
}

final Scenario introScenario = Scenario(
  ["Welcome to Hexad Mountain!", "Are you ready to find out your Hexad type?"],
  [
    Option(
        "Yes!",
        [
          "Ok!",
          "Let's Continue...",
        ],
        HexadType.achiever,
        0.0,
        HexadType.player,
        0.0),
    Option(
        "Sure, ok...",
        [
          "Hey, come on, this will be fun!",
          "Let's continue.",
        ],
        HexadType.disruptor,
        0.0,
        HexadType.freeSpirit,
        0.0)
  ],
);

final List<Scenario> allScenarios = [
  //Player-Achiever
  Scenario(
    [
      "Hey, looks like there's a gem at the top of that slope.",
      "The climb up to it looks really challenging!",
      "Will you just climb it once and get the gem?",
      "Or would you rather stay here for a while and master the climb?",
      "What would you do?",
    ],
    [
      Option(
          "Get the gem for a reward",
          [
            "Nice, you made it.",
            "The gem shines brilliantly!",
            "It should fetch quite the reward at one of the camps.",
          ],
          player,
          1.0,
          player,
          0.0),
      Option(
          "Master climbing the slope",
          [
            "(...after a little while...)",
            "Looks like you have the hang of it now!",
            "Your climbing skills are getting better by the minute.",
            "Keep it up!",
          ],
          achiever,
          1.0,
          achiever,
          0.0)
    ],
  ),
  //Player-Philanthropist
  Scenario([
    "Alright, you've almost made it to the next camp.",
    "But what's this on the ground?",
    "Looks like someone dropped one of their tools.",
    "It seems pretty high-grade!",
    "Will you look around for the owner and return it?",
    "You could also trade it for something valuable.",
    "What will it be?"
  ], [
    Option(
        "Help someone by returning the tool.",
        [
          "Looks like they were looking for it.",
          "They look very grateful that you returned their tool!",
          "You've certainly made their climb easier."
        ],
        philanthropist,
        1.0,
        socializer,
        0.0),
    Option(
        "Trade it for a reward.",
        [
          "You have to haggle a bit for it, but you get your reward!",
          "Thankfully good gear is always in demand up here."
        ],
        player,
        1.0,
        disruptor,
        0.0)
  ]),
  //Player-Socializer
  Scenario([
    "What's this?",
    "A few people have set up camp outside this little cave.",
    "Looks like they're mining for gems while they're here.",
    "Wanna join in the hunt for a gem of your own?",
    "You can also just chill with the others around the campfire.",
    "What do you think?"
  ], [
    Option(
        "Mine for gems",
        [
          "Well then, pick up your pick and wish for luck!",
          "...",
          "Over there, you can see something shiny!",
          "Looks like you've found your gem!",
          "Way to go!"
        ],
        player,
        1.0,
        achiever,
        0.0),
    Option(
        "Socialize with the other climbers",
        [
          "Might as well chat a bit before moving on, right?",
          "The other climbers have some good tips for the road ahead.",
          "You'll be breezing through the next part of the mountain!"
        ],
        socializer,
        1.0,
        socializer,
        0.0)
  ]),
  //Player-Disruptor
  Scenario([
    "Look, you're approaching a camp site.",
    "Gotta decide what to do with that gem you found!",
    "Are you gonna trade it for something else straight away?",
    "Or will you keep it and boast with it to the other climbers for a while?",
    "What will you do?"
  ], [
    Option(
        "Boast about it to the others",
        [
          "Time to showboat a bit!",
          "Oh man, I can't wait to see their faces.",
        ],
        disruptor,
        1.0,
        disruptor,
        0.0),
    Option(
        "Trade it for a reward",
        [
          "Might as well stock up while you can.",
          "Showboating will have to wait!",
        ],
        player,
        1.0,
        player,
        0.0)
  ]),
  //Player-FreeSpirit
  Scenario([
    "Hey, look, there's a berry bush between those trees.",
    "It's loaded with berries!",
    "You could probably go on and explore a couple extra days with those without resupplying.",
    "Trading them at the camp might fetch something good as well!",
    "What do you say?"
  ], [
    Option(
        "Trade the berries for valuables",
        [
          "The other climbers will probably enjoy those.",
          "Much like you will enjoy the extra goods you'll get for them!"
        ],
        player,
        1.0,
        player,
        0.0),
    Option(
        "Use them to explore independently for longer",
        [
          "Nice, let's see how far these will get you.",
          "Now, off the beaten path!"
        ],
        freeSpirit,
        1.0,
        freeSpirit,
        0.0)
  ]),
  //Philanthropist-Socializer
  Scenario([
    "",
    "",
    "",
  ], [
    Option("", [""], philanthropist, 1.0, philanthropist, 0.0),
    Option("", [""], socializer, 1.0, socializer, 0.0)
  ])
];
