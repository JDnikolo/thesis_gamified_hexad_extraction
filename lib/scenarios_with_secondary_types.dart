import 'scenarios.dart';

double sfv = 0.5;
final List<Scenario> allScenarios = [
  //
  //Player-Achiever
  //
  Scenario(
    [
      "Moving on, here's what's happening:",
      "Looks like there's a gem at the top of that challenging wall!",
      "Will you climb it once and get the gem?",
      "Or would you rather stay here for a while and master climbing this difficult wall?",
      "What will you do?",
    ],
    [
      Option(
          "Get the gem for a reward",
          [
            "No need to tire yourself out here, getting the gem is quite enough.",
            "It should fetch quite the reward at one of the camps!",
          ],
          player,
          1.0,
          {}),
      Option(
          "Master climbing the slope",
          [
            "(...after a little while...)",
            "Looks like you have the hang of it now!",
            "Your climbing skills are getting better by the minute.",
          ],
          achiever,
          1.0,
          {})
    ],
  ),
  //
  //Player-Philanthropist
  //
  Scenario([
    "Ok, let's continue.",
    "You've almost made it to the next camp.",
    "But what's this on the ground?",
    "You see a high-quality tool left behind, one you already have.",
    "Would you like to give it away to someone at the camp?",
    "You could also trade it for something valuable.",
    "What will it be?"
  ], [
    Option(
      "Give the tool away.",
      [
        "Looks like they were looking for it.",
        "They look very grateful that you returned their tool!",
        "You've certainly made their climb easier."
      ],
      philanthropist,
      1.0,
      {}, //socializer?
    ),
    Option(
        "Trade it for a reward.",
        [
          "You have to haggle a bit for it, but you get your reward!",
          "Thankfully good gear is always in demand up here."
        ],
        player,
        1.0,
        {
          disruptor: sfv,
        })
  ]),
  //
  //Player-Socializer
  //
  Scenario([
    "Moving on, what's this?",
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
      ],
      player,
      1.0,
      {
        achiever: sfv,
      },
    ),
    Option(
      "Socialize with the other climbers",
      [
        "Might as well chat a bit before moving on, right?",
        "The other climbers have some good tips for the road ahead.",
        "You'll be breezing through the next part of the mountain!"
      ],
      socializer,
      1.0,
      {},
    )
  ]),
  //
  //Player-Disruptor
  //
  Scenario([
    "Ok, on to the next one.",
    "Look, you're approaching a camp site.",
    "Gotta decide what to do with that gem you found on the way!",
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
      {
        achiever: sfv,
      },
    ),
    Option(
      "Trade it for a reward",
      [
        "Might as well stock up while you can.",
        "Showboating will have to wait!",
      ],
      player,
      1.0,
      {
        socializer: sfv,
      },
    )
  ]),
  //
  //Player-FreeSpirit
  //
  Scenario(
    [
      "Let's see what's up next.",
      "Hey, look, there's a berry bush between those trees.",
      "It's loaded with berries!",
      "You could probably go on and explore a couple extra days with those without resupplying.",
      "Trading them at the camp might fetch something good as well!",
      "What do you say?"
    ],
    [
      Option(
        "Trade the berries for a reward",
        [
          "The other climbers will probably enjoy those.",
          "Much like you will enjoy the extra goods you'll get for them!"
        ],
        player,
        1.0,
        {
          socializer: sfv,
        },
      ),
      Option(
        "Use them to explore independently for longer",
        [
          "Nice, let's see how far these will get you.",
          "Now, off the beaten path!"
        ],
        freeSpirit,
        1.0,
        {
          achiever: sfv,
        },
      )
    ],
  ),
  //
  //Philanthropist-Socializer
  //
  Scenario(
    [
      "Moving right along!",
      "You've reached another campsite.",
      "Looks like people are resting, talking around the campfires.",
      "A few groups are repairing others' broken equipment before they keep climbing.",
      "Who would you rather join?"
    ],
    [
      Option(
        "Socialize around a fire",
        [
          "Nothing helps you rest quite like company around the fire!",
          "Let's see if the others have any good advice to share."
        ],
        socializer,
        1.0,
        {}, //
      ),
      Option(
        "Help repair the climbers' gear",
        [
          "Can't have people relying on faulty gear, right?",
          "Let's see what you can help repair before resting."
        ],
        philanthropist,
        1.0,
        {}, //player?free spirit?
      ),
    ],
  ),
  //
  //Philanthropist-Disruptor
  //
  Scenario(
    [
      "Let's see what's next, shall we?",
      "You're moving on up the trail along with a group.",
      "You join a few climbers discussing techniques they've used so far.",
      "You're quite skilled in climbing yourself, what would you rather do?",
    ],
    [
      Option(
        "Share some tips of your own",
        [
          "They appreciate your input!",
          "Hopefully they will remember it when they need it."
        ],
        philanthropist,
        1.0,
        {
          player: sfv,
        }, //consider: player?
      ),
      Option(
        "Boast about your skills",
        [
          "Your taunts have riled them up!",
          "\"You sure talk big, let's see if you can climb the climb!\"",
          "Looks like you'll have to prove yourself up ahead!"
        ],
        disruptor,
        1.0,
        {
          achiever: sfv,
        }, //consider: achiever
      ),
    ],
  ),
  //
  //Philanthropist-Free Spirit
  //
  Scenario(
    [
      "Alright, let's see what's next.",
      "A group you're travelling along is planning their route in advance.",
      "You could join them and help them plan, I'm sure you have a couple of points?",
      "You can also keep going independently and make it on your own.",
      "What do you prefer?"
    ],
    [
      Option(
        "Help them plan a route",
        [
          "Time to put your heads together.",
          "Let's see if there's a good route for a group!"
        ],
        philanthropist,
        1.0,
        {
          socializer: sfv,
        }, //consider: socializer
      ),
      Option(
        "Follow your own path",
        [
          "Might as well leave them behind for now.",
          "You'll be a lot more flexible on your own!",
          "Let's see where your road takes you.",
        ],
        freeSpirit,
        1.0,
        {
          achiever: sfv,
        }, //consider: achiever
      ),
    ],
  ),
  //
  //Philanthropist-Achiever
  //
  Scenario(
    [
      "Let's see what else is waiting for you.",
      "You see a cloud of dust further up the trail.",
      "A group is carving a path through a challenging part of the trail.",
      "Wanna join and help them out?",
      "Or do you wanna brave the challenging part before it is made easier?",
      "What will it be?",
    ],
    [
      Option(
        "Help them make the path",
        [
          "This path won't make itself!",
          "This will be hard, but it will make things easier for everyone else!"
        ],
        philanthropist,
        1.0,
        {
          socializer: sfv,
          player: sfv / 2,
        }, //consider:socializer, player
      ),
      Option(
        "Take on the challenging trail",
        [
          "Can't miss out on this chance!",
          "The climb will be hard, no doubt about it.",
          "But you can boast about how you made it later!",
        ],
        achiever,
        1.0,
        {
          freeSpirit: sfv,
        }, //consider: achiever, free spirit
      ),
    ],
  ),
  //
  //Socializer-Disruptor
  //
  Scenario(
    [
      "Up next, on the next scenario:",
      "You see a sign ahead, with rules on how to proceed on the trail.",
      "Looks like people are following the instructions, forming groups further up.",
      "It's just a sign though, it can't tell you what to do.",
      "So, uh, what will you do?"
    ],
    [
      Option(
        "Join the groups",
        [
          "I guess the sign is probably there for a reason.",
          "Even if that reason is just to make some new friends!",
        ],
        socializer,
        1.0,
        {}, //philanthropist?//player?
      ),
      Option(
        "Don't follow the sign's rules",
        [
          "Who cares about the sign anyway?",
          "Not you!",
          "Let's see if there are any more rebels out there.",
        ],
        disruptor,
        1.0,
        {}, //consider: free spirit, achiever?
      ),
    ],
  ),
  //
  //Socializer-Free Spirit
  //
  Scenario(
    [
      "On to the next question!",
      "There's a team of climbers forming up ahead.",
      "Wanna join them, have some company for a while?",
      "You can also just slip past them and go solo.",
      "What do you say?"
    ],
    [
      Option(
        "Join the team",
        [
          "Many heads are better than one, right?",
          "Either way, let's see what they have to say."
        ],
        socializer,
        1.0,
        {
          player: sfv,
        },
      ),
      Option(
        "Go solo",
        [
          "You ain't slowing down for anyone.",
          "Who knows, you might even find something interesting while going around them.",
          "Just make sure they don't hear you!"
        ],
        freeSpirit,
        1.0,
        {
          disruptor: sfv,
        }, //consider: disruptor?
      ),
    ],
  ),
  //
  //Socializer-Achiever
  //
  Scenario(
    [
      "Onwards then, to the next scenario.",
      "A few climbers are practicing their wall climbing nearby.",
      "You could master a few moves here!",
      "Or just lounge around, see how everyone here is doing.",
      "What will it be?",
    ],
    [
      Option(
        "Rest and socialize",
        [
          "Might as well have a chat,",
          "Gotta save some energy for the actual climb!",
        ],
        socializer,
        1.0,
        {}, //consider: free spirit?
      ),
      Option(
        "Master wall climbing",
        [
          "The climb can wait, mastering this wall comes first!",
          "And you get to boast straight away, with all the people around!"
        ],
        achiever,
        1.0,
        {
          player: sfv,
        }, //player?
      ),
    ],
  ),
  //
  //Disruptor-Free Spirit
  //
  Scenario(
    [
      "Let's see what's next.",
      "A heated disagreement has started in your group regarding wall climbing techniques.",
      "You can break off and follow a different path if you don't want to deal with it.",
      "But they seem to be in just the right mood for some provoking!",
      "What will you do?"
    ],
    [
      Option(
        "Provoke them",
        [
          "Might as well pour gas in the fire right?",
          "Just don't do that in an actual fire, ok?",
          "Forest fires are no joke!"
        ],
        disruptor,
        1.0,
        {
          achiever: sfv,
          socializer: sfv,
        }, //achiever?socializer?
      ),
      Option(
        "Go around them",
        [
          "You all already have the mountain to deal with.",
          "Can't be dealing with fights as well.",
        ],
        freeSpirit,
        1.0,
        {},
      ),
    ],
  ),
  //
  //Disruptor-Achiever
  //
  Scenario(
    [
      "Pay attention, there's another question coming!",
      "A group of climbers is challenging others to climb a certain wall.",
      "They are not letting people go on if they don't.",
      "You can probably complete their challenge, no sweat.",
      "But who are they to not let people pass?",
      "What will you do?"
    ],
    [
      Option(
        "Overcome their challenge",
        [
          "Well, there's probably a reason they're doing this.",
          "Show them this isn't enough to stop you!"
        ],
        achiever,
        1.0,
        {
          player: sfv,
        }, //player?
      ),
      Option(
        "Disregard their rules,\npass anyway",
        [
          "Yeah, they can't hold you here like this!",
          "Why are they stopping people here anyway?"
        ],
        disruptor,
        1.0,
        {
          freeSpirit: sfv,
        }, //free spirit?
      ),
    ],
  ),
  //
  //Free Spirit-Achiever
  //
  Scenario(
    [
      "Ok, there should be another question here somewhere...There it is!",
      "Looks like this path ends with a very hard wall climb.",
      "No wonder you didn't see many people along it.",
      "Do you think you're up for it?",
      "You can always look for another way, off the beaten path.",
      "What's it gonna be?"
    ],
    [
      Option(
        "Explore for another way up",
        [
          "There's gotta be another way around.",
          "Who knows what you'll find out there!",
        ],
        freeSpirit,
        1.0,
        {}, //player?
      ),
      Option(
        "Overcome this difficult obstacle",
        [
          "Yeah, might as well have a story to tell when you reach the next camp!",
          "Good luck!"
        ],
        achiever,
        1.0,
        {}, //player?
      ),
    ],
  ),
];
