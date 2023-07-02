from collections import defaultdict
from tqdm import tqdm
import numpy as np


class BasicAGAgent:
    def __init__(self, learn_rate, discount_factor, env) -> None:
        self.q_values = defaultdict(lambda: np.zeros(env.action_space.n + 1))
        self.l_r = learn_rate
        self.d_f = discount_factor
        self.error = []
        self.action_space = env.action_space

    def get_action(self, obs: tuple):
        return np.argmax(self.q_values[obs])

    def random_action(self):
        return self.action_space.sample()

    def update(self, obs, action, reward, next_obs):
        new_q = np.max(self.q_values[next_obs])
        temp_diff = reward + self.d_f * new_q - self.q_values[obs][action]

        self.q_values[obs][action] += self.l_r * temp_diff

        self.error.append(temp_diff)

    def train(
        self,
        env,
        iterations=1000000,
        reset_env=True,
    ):
        obs = (13, 13)
        if reset_env:
            obs, _ = env.reset()
        for _ in tqdm(range(iterations)):
            action = self.random_action()
            new_obs, reward, _, _, _ = env.step(action)
            self.update(obs, action, reward, new_obs)
            obs = new_obs
        train_error = self.error.copy()
        self.error = []
        return train_error

    def step_and_update(self,env,obs,answer=None,retrain_iterations=2000,learning_rate=0.1):
        old_lr=self.l_r
        self.l_r=learning_rate
        action=self.get_action(obs)
        env.set_user_answer(answer)
        new_obs,reward,_,_,info=env.step(action)
        self.update(obs,action,reward,new_obs)
        obs=new_obs
        old_state=obs
        for _ in (range(retrain_iterations)):
            action=self.get_action(obs)
            new_obs,reward,_,_,info=env.step(action)
            self.update(obs,action,reward,new_obs)
            obs=new_obs
        env.set_history(old_state)
        obs=old_state
        self.l_r=old_lr
        return action,reward,obs,info


class EpsilonAGAgent:
    def __init__(
        self, learn_rate, discount_factor, env, epsilon, epsilon_decay, epsilon_min
    ) -> None:
        self.q_values = defaultdict(lambda: np.zeros(env.action_space.n + 1))
        self.l_r = learn_rate
        self.d_f = discount_factor
        self.action_space = env.action_space

        self.epsilon = epsilon
        self.e_min = epsilon_min
        self.e_d = epsilon_decay

        self.error = []

    def decay_epsilon(self):
        self.epsilon = max(self.e_min, self.epsilon - self.e_d)

    def get_action(self, obs: tuple, avoid_reps=False):
        if np.random.random() < self.epsilon:
            action = self.action_space.sample()
            while action in obs and avoid_reps:
                action = self.action_space.sample()
            return action
        return int(np.argmax(self.q_values[obs]))

    def random_action(self):
        return self.action_space.sample()

    def update(self, obs, action, reward, next_obs):
        new_q = np.max(self.q_values[next_obs])
        temp_diff = reward + self.d_f * new_q - self.q_values[obs][action]

        self.q_values[obs][action] += self.l_r * temp_diff

        self.error.append(temp_diff)
