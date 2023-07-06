"""

"""
import copy
import numpy as np


class DominantSwapBot:
    """
    Generates random answers to gamification element suggestions based on a Hexad profile.
    Impelents Hexad user profile change over time by swapping scores between dominant types. 
    """

    def __init__(
        self,
        hexad_types: dict = None,
        uncertainty: float = 0.0,
        divisor=6,
        starting_swap_threshold=0.0,
        swap_gain_modifier=0.01,
        seed=None,
    ):
        """
        TODO: description

        Args:
            hexad_type: the hexad profile to base answers on
            uncertainty: the probability of random answers being generated
            divisor: used to calculate the chance of a positive answer: hexad_score/divisor
            starting_swap_threshold: TODO
            swap_gain_modifier: TODO
            seed: seed used in random number generation used in choices.
        """
        if hexad_types is None:
            hexad_types = {
                "pl": 5.0,
                "ach": 4.0,
                "ph": 3.0,
                "dis": 2.0,
                "s": 1.0,
                "fs": 0.5,
            }
        assert 0 <= starting_swap_threshold <= 1.0
        self.threshold = starting_swap_threshold
        self.init_threshold = starting_swap_threshold
        assert 0.0 <= swap_gain_modifier < 1.0
        self.gain = swap_gain_modifier

        assert 0 <= uncertainty <= 1.0
        self.uncertainty = uncertainty
        self.hexad_profile = hexad_types
        hex_p = copy.deepcopy(hexad_types)
        self.dominants = []
        k = max(hex_p, key=hex_p.get)
        while hex_p[k] >= 3.0:
            self.dominants.append(k)
            hex_p.pop(k)
            k = max(hex_p, key=hex_p.get)
        assert divisor > 0
        self.div = divisor
        self.rng = np.random.default_rng(seed=seed)

    def get_rand_answer(self):
        """
        Returns a random answer ('accept', 'decline' or None).
        """
        return self.rng.choice(["accept", "decline", None])

    def change_dominants(self):
        """ """
        type1, type2 = self.rng.choice(self.dominants, size=2)
        tries=0
        while self.hexad_profile[type1] == self.hexad_profile[type2] and tries<5:
            type1, type2 = self.rng.choice(self.dominants, size=2)
            tries+=1
        self.hexad_profile[type1], self.hexad_profile[type2] = (
            self.hexad_profile[type2],
            self.hexad_profile[type1],
        )

    def get_answer(self, hexad_type):
        """
        Returns a random answer to a gamification element of type `hexad_type` based
        on the bot's Hexad profile with probability (1-`self.uncertainty`), or a completely random
        answer otherwise. Also returns boolean value tuple signifying whether the answer was due to uncertainty and whether a change in
        dominant types occured.
        """
        if hexad_type is None:
            return None,(False,False)
        changed = False
        if self.rng.random() < self.threshold:
            self.change_dominants()
            self.threshold = self.init_threshold
            changed = True
        else:
            self.threshold += self.rng.random() * self.gain
        if self.rng.random() <= self.uncertainty:
            return self.get_rand_answer(), (True, changed)
        if self.rng.random() <= self.hexad_profile[hexad_type] / self.div:
            return "accept", (False, changed)
        return "decline", (False, changed)

class ScoreChangeBot:
    """
    Generates random answers to gamification element suggestions based on a Hexad profile.
    Impelents Hexad user profile change over time by increasing or reducing dominant type scores.
    """

    def __init__(
        self,
        hexad_types: dict = None,
        uncertainty: float = 0.0,
        divisor=6,
        starting_change_threshold=0.0,
        change_gain_modifier=0.01,
        change_amount=1.0,
        seed=None,
    ):
        """
        TODO: description

        Args:
            hexad_type: the hexad profile to base answers on
            uncertainty: the probability of random answers being generated
            divisor: used to calculate the chance of a positive answer: hexad_score/divisor
            starting_change_threshold: TODO
            change_gain_modifier: TODO
            change_amount: TODO
            seed: seed used in random number generation used in choices.
        """
        if hexad_types is None:
            hexad_types = {
                "pl": 5.0,
                "ach": 4.0,
                "ph": 3.0,
                "dis": 2.0,
                "s": 1.0,
                "fs": 0.5,
            }
        assert 0 <= starting_change_threshold <= 1.0
        self.threshold = starting_change_threshold
        self.init_threshold = starting_change_threshold
        assert 0.0 <= change_gain_modifier < 1.0
        self.gain = change_gain_modifier
        assert .0<change_amount<=2.0
        self.amount=change_amount

        assert 0 <= uncertainty <= 1.0
        self.uncertainty = uncertainty
        self.hexad_profile = hexad_types
        hex_p = copy.deepcopy(hexad_types)
        self.dominants = []
        k = max(hex_p, key=hex_p.get)
        while hex_p[k] >= 3.0:
            self.dominants.append(k)
            hex_p.pop(k)
            k = max(hex_p, key=hex_p.get)
        assert divisor > 0
        self.div = divisor
        self.rng = np.random.default_rng(seed=seed)

    def get_rand_answer(self):
        """
        Returns a random answer ('accept', 'decline' or None).
        """
        return self.rng.choice(["accept", "decline", None])

    def change_score(self):
        """ """
        typ=self.rng.choice(self.dominants)
        score = self.hexad_profile[typ]
        while score == self.hexad_profile[typ]:
            score += self.amount * 1 if self.rng.random()<0.5 else -1
            score = min(score,5.0)
            score = max(score,3.0)
        self.hexad_profile[typ] = score

    def get_answer(self, hexad_type):
        """
        Returns a random answer to a gamification element of type `hexad_type` based
        on the bot's Hexad profile with probability (1-`self.uncertainty`), or a completely random
        answer otherwise. Also returns boolean value tuple signifying whether the answer was due to uncertainty and whether a change in
        dominant types occured.
        """
        if hexad_type is None:
            return None,(False,False)
        changed = False
        if self.rng.random() < self.threshold:
            self.change_score()
            self.threshold = self.init_threshold
            changed = True
        else:
            self.threshold += self.rng.random() * self.gain
        if self.rng.random() <= self.uncertainty:
            return self.get_rand_answer(), (True, changed)
        if self.rng.random() <= self.hexad_profile[hexad_type] / self.div:
            return "accept", (False, changed)
        return "decline", (False, changed)
