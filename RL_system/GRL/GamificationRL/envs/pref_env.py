import gymnasium as gym
from gymnasium import spaces
from GamificationRL.envs.gamification_elements import (
    nothing,
    gamification_element,
)


class GamificationPreferenceEnv(gym.Env):
    metadata = {"render_modes": ["ansi"]}
    pref_history = {}
    user_answer = None
    hexad_adjusted = {}

    def __init__(
        self,
        hexad_load: dict,
        render_mode=None,
        gamification_elements=None,
        individual_modifications: dict = None,
        repetition_penalty: tuple = (100, 50),
        use_fatigue=False,
        nothing_reward=75,
        fatigue_reduction=0.05,
        fatigue_replenish=0.0125,
        seed=None,
    ):
        self.seed = seed
        self.ge = dict([(elem.name, elem) for elem in gamification_elements])
        self.ge["Nothing"] = nothing
        self.nothing_reward = nothing_reward

        self.penalty = repetition_penalty

        self.hexad_type = hexad_load
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

        assert render_mode is None or render_mode in self.metadata["render_mode"]
        self.render_mode = render_mode

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
        return self._history

    def _get_info(self):
        return {
            "fatigue": self.fatigue,
            "preference": self.hexad_preference,
        }

    def reset(self, seed=None, options=None):
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

    def step(self, action):
        assert self.user_answer in ("accept", "decline", None)
        ge_name = self.action_to_ge[action]
        ge = self.ge[ge_name]
        hex_load = self.ge[ge_name].loads
        reward = 0

        if ge_name == "Nothing":
            reward = self.nothing_reward
        else:
            for hex_type, value in hex_load.items():
                reward += self.hexad_adjusted[hex_type] * value

        if action == self._history[0]:
            reward -= self.penalty[0]
        if action == self._history[1] and action != self.ge_to_action["Nothing"]:
            reward -= self.penalty[1]

        if ge_name in self.ge_mods:
            reward += self.ge_mods[ge_name]
        if ge.type is not None and ge.type in self.hexad_mods:
            reward = reward * self.hexad_mods[ge.type]

        if self.fatigue_enabled:
            reward = reward * self.fatigue[ge_name]

        if self.user_answer == "accept" and self.pref_enabled[ge.type]:
            pref = self.hexad_preference[ge.type]
            pref += 0.2 if pref < 1.0 else 0.1 if pref < 1.3 else 0.05
            pref=min(pref,1.7)
            self.hexad_preference[ge.type] = pref

        if self.user_answer == "decline" and self.pref_enabled[ge.type]:
            pref = self.hexad_preference[ge.type]
            pref -= 0.1 if pref < 1.0 else 0.1 if pref < 1.3 else 0.2
            pref=max(pref,0.1)
            self.hexad_preference[ge.type] = pref

        if self.user_answer is not None and self.fatigue_enabled:
            for elem, fatigue in self.fatigue.items():
                new_fatigue = fatigue
                new_fatigue += (
                    self.f_rp
                    if (elem != ge_name or elem == "Nothing")
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
        for hex_type in self.hexad_type:
            self.hexad_adjusted[hex_type] = (
                self.hexad_type[hex_type] * self.hexad_preference[hex_type]
            )

    def set_history(self, new_history: tuple):
        self._history = new_history

    def disable_pref(self, pref):
        assert pref in self.pref_enabled
        if self.pref_enabled[pref]:
            self.pref_history[pref] = self.hexad_preference[pref]
            self.pref_enabled[pref] = False
            self.hexad_preference[pref] = 0.0

    def enable_pref(self, pref):
        assert pref in self.pref_enabled
        if not self.pref_enabled[pref]:
            self.pref_enabled[pref] = True
            self.hexad_preference[pref] = self.pref_history[pref]
            self.pref_history.pop(pref)

    def set_user_answer(self, new_answer):
        assert new_answer in ("accept", "decline", None)
        self.user_answer = new_answer

    def get_action_mapping(self):
        return self.action_to_ge

    def close(self):
        pass

    def render(self):
        pass
