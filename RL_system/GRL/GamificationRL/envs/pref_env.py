"""
"""
import copy
import gymnasium as gym
import numpy as np
from gymnasium import spaces
from GamificationRL.envs.gamification_elements import (
    nothing,
    gamification_element,
)


class GamificationPreferenceEnv(gym.Env):
    """
    Environment simulating a user's preference for gamification elements according
    to their Hexad profile. Continuous and deterministic.
    """

    metadata = {"render_modes": []}
    pref_history = {}
    user_answer = None
    hexad_adjusted = {}

    def __init__(
        self,
        hexad_load: dict,
        gamification_elements: list[gamification_element] | None = None,
        individual_modifications: dict[str:float] = None,
        repetition_penalty: tuple = (500, 1000),
        use_fatigue=False,
        fatigue_reduction=0.05,
        fatigue_replenish=0.0125,
        nothing_reward=75,
        pref_ranges=(1.0, 1.3, 1.7),
        pref_increase=(0.2, 0.1, 0.05),
        pref_decrease=(0.05, 0.1, 0.1),
        pref_min=0.1,
        seed=None,
    ):
        """
        Creates a new environment using the specified parameters.

        Parameters:
        hexad_load: dictionary containing the hexad values of the user.
        gamification_elements: a gamification_element list describing the gamification elements present in the system,
        individual_modifications: dictionary with gamification elements or hexad types as keys. Values are added to(for elements) or multiply(for elements with that primary type) the base reward.
        repetition_penalty: tuple containing the penalties applied on repeated use of an element.
        use_fatigue: whether the environment simulates long-term percentile reduction of element rewards,
        fatigue_reduction: the reduction applied to an element's reward after it is used,
        fatigue_replenish: the increase of an elements' reward each step it is not used,
        nothing_reward: the reward for showing no gamification element,
        seed: seed passed to space random sampling,
        """
        self.seed = seed
        self.ge = dict([(elem.name, elem) for elem in gamification_elements])
        self.ge["Nothing"] = nothing
        self.nothing_reward = nothing_reward

        self.penalty = repetition_penalty

        self.hexad_type = hexad_load
        assert len(pref_ranges) == len(pref_decrease) == len(pref_increase)
        self.p_range = np.array(pref_ranges)
        self.p_max = pref_ranges[-1]
        self.p_min = pref_min
        self.p_inc = pref_increase
        self.p_dec = pref_decrease
        self.hexad_preference = {
            "pl": 1.0,
            "ach": 1.0,
            "ph": 1.0,
            "dis": 1.0,
            "s": 1.0,
            "fs": 1.0,
        }

        self.pref_enabled = {
            "pl": True,
            "ach": True,
            "ph": True,
            "dis": True,
            "s": True,
            "fs": True,
            None: False,
        }
        for hex_type in self.hexad_type:
            self.hexad_adjusted[hex_type] = (
                self.hexad_type[hex_type] * self.hexad_preference[hex_type]
            )

        self.action_space = spaces.Discrete(len(self.ge), start=1, seed=seed)
        self.action_to_ge = {}
        self.ge_to_action = {}
        self.fatigue_enabled = use_fatigue
        self.f_rd = fatigue_reduction
        self.f_rp = fatigue_replenish
        self.fatigue = {}
        i = 1
        for name, element in self.ge.items():
            assert isinstance(element, gamification_element)
            self.action_to_ge[i] = name
            self.ge_to_action[name] = i
            self.fatigue[name] = 1.0
            i += 1

        self.observation_space = spaces.Tuple(
            [
                spaces.Discrete(len(self.ge), start=1, seed=seed),
                spaces.Discrete(len(self.ge), start=1, seed=seed),
            ]
        )

        self.ge_mods = {}
        self.hexad_mods = {}
        if individual_modifications is not None:
            for req, mod in individual_modifications.items():
                if req in list(self.ge_to_action):
                    self.ge_mods[req] = mod
                if req in list(self.hexad_type.keys()):
                    self.hexad_mods[req] = mod

        self._history = (len(self.ge), len(self.ge))
        super().__init__()

    def _get_obs(self):
        """
        Returns the current observable state of the environment.
        """
        return self._history

    def _get_info(self):
        """
        Returns additional information about the state of the environment.
        """
        return {
            "fatigue": self.fatigue,
            "preference": self.hexad_preference,
        }

    def reset(self, seed=None, options=None):
        """
        Resets the environment's variables (fatigue and hexad preference) to their default values.
        """
        super().reset(seed=seed)

        self.hexad_preference = {
            "pl": 1.0,
            "ach": 1.0,
            "ph": 1.0,
            "dis": 1.0,
            "s": 1.0,
            "fs": 1.0,
        }

        if self.fatigue_enabled:
            for key in self.fatigue:
                self.fatigue[key] = 1.0

        self._history = (len(self.ge), len(self.ge))

        return self._get_obs(), self._get_info()

    def calculate_reward(self, action, profile=None):
        """
        Calculates and returns the reward of using `action` on the current state.
        """
        ge_name = self.action_to_ge[action]
        ge = self.ge[ge_name]
        hex_load = self.ge[ge_name].loads
        reward = 0
        if profile is None:
            hex_adjs = self.hexad_adjusted
        else:
            hex_adjs = copy.deepcopy(profile)
            for hex_type in self.hexad_type:
                hex_adjs[hex_type] = (
                    hex_adjs[hex_type] * self.hexad_preference[hex_type]
                )

        if ge_name == "Nothing":
            reward = self.nothing_reward
        else:
            for hex_type, value in hex_load.items():
                reward += hex_adjs[hex_type] * value

        if ge_name in self.ge_mods:
            reward += self.ge_mods[ge_name]
        if ge.type is not None and ge.type in self.hexad_mods:
            reward = reward * self.hexad_mods[ge.type]

        if self.fatigue_enabled:
            reward = reward * self.fatigue[ge_name]

        if action == self._history[0]:
            reward -= self.penalty[0]
        if action == self._history[1]:
            reward -= self.penalty[1]

        return reward

    def get_best_action(self,profile=None):
        """
        Calculates rewards for all actions and returns the best available action and its reward.
        """
        rewards = []
        for action in range(1, self.action_space.n + 1):
            rewards.append(self.calculate_reward(action=action,profile=profile))
        arg = np.argmax(rewards)
        return arg + 1, rewards[arg]

    def step(self, action):
        """
        Calculates the reward of `action` and changes the state of the environment.
        Updates Hexad preferences and fatigue if an answer was provided.
        Returns the reward and new observable state and information.
        """
        assert self.user_answer in ("accept", "decline", None)
        ge_name = self.action_to_ge[action]
        ge = self.ge[ge_name]

        reward = self.calculate_reward(action=action)

        if (
            self.user_answer == "accept"
            and self.pref_enabled[ge.type]
            and self.hexad_adjusted[ge.type] != max(self.hexad_adjusted.values())
        ):
            pref = self.hexad_preference[ge.type]
            index = np.searchsorted(self.p_range, pref)
            pref += self.p_inc[index]
            pref = min(pref, self.p_max)
            self.hexad_preference[ge.type] = pref

        if (self.user_answer == "decline" and self.pref_enabled[ge.type]
            and self.hexad_adjusted[ge.type] != min(self.hexad_adjusted.values())):
            pref = self.hexad_preference[ge.type]
            index = np.searchsorted(self.p_range, pref)
            pref -= self.p_dec[index]
            pref = max(pref, self.p_min)
            self.hexad_preference[ge.type] = pref

        if self.user_answer is not None and self.fatigue_enabled:
            for elem, fatigue in self.fatigue.items():
                new_fatigue = fatigue
                new_fatigue += (
                    self.f_rp
                    if ((elem != ge_name) or elem == "Nothing")
                    else -1 * self.f_rd
                )
                new_fatigue = min(new_fatigue, 1)
                new_fatigue = max(new_fatigue, 0.1)
                self.fatigue[elem] = new_fatigue
            self.user_answer = None

        self._calc_adjusted()
        self._history = (self._history[1], action)
        obs = self._get_obs()
        info = self._get_info()
        return obs, reward, False, False, info

    def _calc_adjusted(self):
        """
        Updates the adjusted Hexad values of the user, based on current preference.
        """
        for hex_type in self.hexad_type:
            self.hexad_adjusted[hex_type] = (
                self.hexad_type[hex_type] * self.hexad_preference[hex_type]
            )

    def set_history(self, new_history: tuple[int, int]):
        """
        Sets the state of the environment to `new_history`
        """
        self._history = new_history

    def disable_pref(self, pref):
        """
        Sets the user's preference of type `pref` to 0, effectively disabling them.
        """
        assert pref in self.pref_enabled
        if self.pref_enabled[pref]:
            self.pref_history[pref] = self.hexad_preference[pref]
            self.pref_enabled[pref] = False
            self.hexad_preference[pref] = 0.0

    def enable_pref(self, pref):
        """
        Resets the user's preference for type `pref` to its previous value
        if it was disabled.
        """
        assert pref in self.pref_enabled
        if not self.pref_enabled[pref]:
            self.pref_enabled[pref] = True
            self.hexad_preference[pref] = self.pref_history[pref]
            self.pref_history.pop(pref)

    def set_user_answer(self, new_answer):
        """
        Sets the user's answer.
        """
        assert new_answer in ("accept", "decline", None)
        self.user_answer = new_answer

    def get_action_mapping(self):
        return self.action_to_ge

    def close(self):
        pass

    def render(self):
        pass
