from collections import defaultdict
import numpy as np


class AdaptiveGamificationAgent:
    def __init__(self, learn_rate, epsilon, discount_factor, env) -> None:
        self.q_values = defaultdict(lambda: np.zeros(env.action_space.n + 1))
        self.l_r = learn_rate
        self.eps = epsilon
        self.d_f = discount_factor
        self.error = []

    def get_action(self, obs: tuple):
        return np.argmax(self.q_values[obs])

    def random_action(self, env):
        return env.action_space.sample()

    def update(self, obs, action, reward, next_obs):
        new_q = np.max(self.q_values[next_obs])
        temp_diff = reward + self.d_f * new_q - self.q_values[obs][action]

        self.q_values[obs][action] += self.l_r * temp_diff

        self.error.append(temp_diff)
