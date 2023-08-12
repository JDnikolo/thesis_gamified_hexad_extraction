"""
"""
import copy
from collections import defaultdict
from tqdm import tqdm
import numpy as np


class BasicAGAgent:
    def __init__(self, learn_rate, discount_factor, env) -> None:
        self.q_values = defaultdict(lambda: np.zeros(env.action_space.n))
        self.l_r = learn_rate
        self.d_f = discount_factor
        self.error = []
        self.action_space = env.action_space
    
    def reset(self):
        self.q_values = defaultdict(lambda: np.zeros(self.action_space.n))
        self.error = []

    def get_action(self, obs: tuple, avoid_reps=None):
        return np.argmax(self.q_values[obs])+1

    def random_action(self):
        return self.action_space.sample()

    def update(self, obs, action, reward, next_obs):
        new_q = np.max(self.q_values[next_obs])
        temp_diff = reward + self.d_f * new_q - self.q_values[obs][action-1]

        self.q_values[obs][action-1] += self.l_r * temp_diff

        self.error.append(temp_diff)

    def train(self, env, iterations=1000000, reset_env=True, trunc_error=False):
        obs = (13, 13)
        if reset_env:
            obs, _ = env.reset()
        for _ in tqdm(range(iterations)):
            action = self.random_action()
            new_obs, reward, _, _, _ = env.step(action)
            self.update(obs, action, reward, new_obs)
            obs = new_obs
        if trunc_error:
            train_error = copy.deepcopy(self.error)
            self.error = []
        return train_error

    def step_and_update(
        self,
        env,
        obs,
        answer=None,
        retrain_iterations=2000,
        learning_rate=0.1,
        random_retrain=False,
        act=None,
    ):
        old_lr = self.l_r
        self.l_r = learning_rate
        if act is None:
            action = self.get_action(obs, avoid_reps=True)
        else:
            action = act
        env.set_user_answer(answer)
        new_obs, reward, _, _, info = env.step(action)
        self.update(obs, action, reward, new_obs)
        error = self.error[-1]
        obs = new_obs
        old_state = obs
        for _ in range(retrain_iterations):
            if random_retrain:
                a = self.random_action()
            else:
                a = self.get_action(obs)
            new_obs, rr, _, _, _ = env.step(a)
            self.update(obs, a, rr, new_obs)
            obs = new_obs
        env.set_history(old_state)
        obs = old_state
        self.l_r = old_lr
        return action, reward, obs, info, error


class EpsilonAGAgent:
    """ """

    def __init__(
        self, learn_rate, discount_factor, env, epsilon, epsilon_decay, epsilon_min
    ) -> None:
        self.q_values = defaultdict(lambda: np.zeros(env.action_space.n))
        self.l_r = learn_rate
        self.d_f = discount_factor
        self.action_space = env.action_space

        self.epsilon = epsilon
        self.e_min = epsilon_min
        self.e_d = epsilon_decay

        self.error = []


    def reset(self):
        self.q_values = defaultdict(lambda: np.zeros(self.action_space.n))
        self.error = []

    def decay_epsilon(self):
        self.epsilon = max(self.e_min, self.epsilon - self.e_d)

    def get_action(self, obs: tuple, avoid_reps=False):
        if np.random.random() < self.epsilon:
            action = self.action_space.sample()
            while action in obs and avoid_reps:
                action = self.action_space.sample()
            return action
        return int(np.argmax(self.q_values[obs]) + 1)

    def random_action(self):
        return self.action_space.sample()

    def update(self, obs, action, reward, next_obs):
        new_q = np.max(self.q_values[next_obs])
        temp_diff = reward + self.d_f * new_q - self.q_values[obs][action - 1]

        self.q_values[obs][action - 1] += self.l_r * temp_diff

        self.error.append(temp_diff)

    def train(self, env, iterations=1000000, reset_env=True, trunc_error=False):
        obs = (13, 13)
        if reset_env:
            obs, _ = env.reset()
        for _ in tqdm(range(iterations // 1000)):
            for _ in range(1000):
                action = self.get_action(
                    obs,
                )
                new_obs, reward, _, _, _ = env.step(action)
                self.update(obs, action, reward, new_obs)
                obs = new_obs
            self.decay_epsilon()
        if trunc_error:
            train_error = copy.deepcopy(self.error)
            self.error = []
        return train_error

    def step_and_update(
        self,
        env,
        obs,
        answer=None,
        retrain_iterations=2000,
        learning_rate=0.1,
        random_retrain=False,
        act=None,
    ):
        old_lr = self.l_r
        self.l_r = learning_rate
        if act is None:
            action = self.get_action(obs, avoid_reps=True)
        else:
            action = act
        env.set_user_answer(answer)
        new_obs, reward, _, _, info = env.step(action)
        self.update(obs, action, reward, new_obs)
        error = self.error[-1]
        obs = new_obs
        old_state = obs
        self.epsilon+=self.e_d*retrain_iterations
        for _ in range(retrain_iterations):
            if random_retrain:
                a = self.random_action()
            else:
                a = self.get_action(obs, avoid_reps=True)
            new_obs, rr, _, _, _ = env.step(a)
            self.update(obs, a, rr, new_obs)
            obs = new_obs
            self.decay_epsilon()
        env.set_history(old_state)
        obs = old_state
        self.l_r = old_lr
        return action, reward, obs, info, error


class RandomBestOfX:
    """
    Reinforcement Learning agent for the Gamification Preference Environment.
    Implements an `epsilon` probability of randomly picking an action from the top X available.
    """

    def __init__(
        self,
        learn_rate,
        discount_factor,
        env,
        epsilon,
        epsilon_decay,
        epsilon_min,
        X,
    ) -> None:
        """
        Creates a RandomBestOfX agent using the following parameters.
        """
        self.q_values = defaultdict(lambda: np.zeros(env.action_space.n))
        self.l_r = learn_rate
        self.d_f = discount_factor
        self.action_space = env.action_space

        self.epsilon = epsilon
        self.e_min = epsilon_min
        self.e_d = epsilon_decay

        assert 2 < X < self.action_space.n
        self.choices = X

        self.error = []

    def reset(self):
        self.q_values = defaultdict(lambda: np.zeros(self.action_space.n))        
        self.error = []

    def decay_epsilon(self):
        self.epsilon = max(self.e_min, self.epsilon - self.e_d)

    def get_action(self, obs: tuple, avoid_reps=False):
        if np.random.random() < self.epsilon:
            actions = np.argpartition(self.q_values[obs], kth=-1 * self.choices)[
                -1 * self.choices :
            ]
            action = np.random.choice(actions) + 1
            while action in obs and avoid_reps:
                action = np.random.choice(actions) + 1
            return action
        return int(np.argmax(self.q_values[obs]) + 1)

    def random_action(self):
        return self.action_space.sample()

    def update(self, obs, action, reward, next_obs):
        new_q = np.max(self.q_values[next_obs])
        temp_diff = reward + self.d_f * new_q - self.q_values[obs][action - 1]

        self.q_values[obs][action - 1] += self.l_r * temp_diff

        self.error.append(temp_diff)

    def train(
        self,
        env,
        iterations=1000000,
        reset_env=True,
        trunc_error=False,
    ):
        obs = (13, 13)
        if reset_env:
            obs, _ = env.reset()
        for _ in tqdm(range(iterations // 1000)):
            for _ in range(1000):
                action = self.random_action()
                new_obs, reward, _, _, _ = env.step(action)
                self.update(obs, action, reward, new_obs)
                obs = new_obs
            self.decay_epsilon()
        if trunc_error:
            train_error = copy.deepcopy(self.error)
            self.error = []
        return train_error

    def step_and_update(
        self,
        env,
        obs,
        answer=None,
        retrain_iterations=2000,
        learning_rate=0.1,
        random_retrain=False,
        act=None,
    ):
        old_lr = self.l_r
        self.l_r = learning_rate
        if act is None:
            action = self.get_action(obs, avoid_reps=True)
        else:
            action = act
        env.set_user_answer(answer)
        new_obs, reward, _, _, info = env.step(action)
        self.update(obs, action, reward, new_obs)
        error = self.error[-1]
        obs = new_obs
        old_state = obs
        self.epsilon+=self.e_d*retrain_iterations
        for _ in range(retrain_iterations):
            if random_retrain:
                a = self.random_action()
            else:
                a = self.get_action(obs, avoid_reps=True)
            new_obs, rr, _, _, _ = env.step(a)
            self.update(obs, a, rr, new_obs)
            obs = new_obs
            self.decay_epsilon()
        env.set_history(old_state)
        obs = old_state
        self.l_r = old_lr
        return action, reward, obs, info, error

class FatigueAwareAgent:
    """
    Q-Learning agent for the Gamification Preference Environment.
    Implements an `epsilon` probability of randomly picking an action.
    Optionally includes fatigue in Q value calculations.
    """

    def __init__(
        self,
        learn_rate,
        discount_factor,
        env,
        epsilon,
        epsilon_decay,
        epsilon_min,
    ) -> None:
        """
        Creates a FatigueAwareAgent.
        """
        self.q_values = defaultdict(lambda: np.zeros(env.action_space.n))
        self.l_r = learn_rate
        self.d_f = discount_factor
        self.action_space = env.action_space

        self.epsilon = epsilon
        self.e_min = epsilon_min
        self.e_d = epsilon_decay

        self.fatigues =  np.ones(self.action_space.n,dtype=float)
        self._fatigue_rep=.0
        self._last_use = np.zeros(self.action_space.n,dtype=int)
        self._current_step=0

        self.error = []
    
    def reset(self):
        self.q_values = defaultdict(lambda: np.zeros(self.action_space.n))
        self.fatigues =  np.ones(self.action_space.n,dtype=float)
        self._fatigue_rep=.0
        self._last_use = np.zeros(self.action_space.n,dtype=int)
        self._current_step=0
        self.error = []

    
    def decay_epsilon(self):
        self.epsilon = max(self.e_min, self.epsilon - self.e_d)

    def get_action(self, obs: tuple, avoid_reps=False):
        if np.random.random() < self.epsilon:
            action = self.action_space.sample()
            while avoid_reps and action in obs:
                action = self.action_space.sample()
            return action
        return int(np.argmax(self.q_values[obs]) + 1)

    def random_action(self):
        return self.action_space.sample()

    def update(self, obs, action, reward, next_obs):
        adjusted = np.multiply(self.q_values[next_obs],self.fatigues)
        new_q = np.max(adjusted)
        temp_diff = reward + self.d_f * new_q - self.q_values[obs][action - 1]

        self.q_values[obs][action - 1] += self.l_r * temp_diff

        self.error.append(temp_diff)

    def train(
        self,
        env,
        iterations=1000000,
        reset_env=True,
        trunc_error=False,
    ):
        obs = (13, 13)
        if reset_env:
            obs, _ = env.reset()
        for _ in tqdm(range(iterations // 1000)):
            for _ in range(1000):
                action = self.get_action(obs,avoid_reps=False)
                new_obs, reward, _, _, _ = env.step(action)
                self.update(obs, action, reward, new_obs)
                obs = new_obs
            self.decay_epsilon()
        if trunc_error:
            train_error = copy.deepcopy(self.error)
            self.error = []
        return train_error

    def step_and_update(
        self,
        env,
        obs,
        answer=None,
        retrain_iterations=2000,
        learning_rate=0.1,
        random_retrain=False,
        act=None,
    ):
        #Adjust learning rate
        old_lr = self.l_r
        self.l_r = learning_rate
        #Get the action to be performed or use the action provided.
        if act is None:
            action = self.get_action(obs, avoid_reps=True)
        else:
            action = act
        #Set user answer and advance environment.
        env.set_user_answer(answer)
        new_obs, reward, _, _, info = env.step(action)
        new_fatigue=info['fatigue'][env.action_to_ge[action]]
        #Update agent step
        self._current_step+=1
        #Update fatigue replenishment rate
        if new_fatigue>self.fatigues[action-1]:
            self._fatigue_rep=(new_fatigue-self.fatigues[action-1])/(self._current_step-self._last_use[action-1])
        #Update action fatigue and last use counter
        self._last_use[action-1]=self._current_step
        if self._fatigue_rep!=.0:
            for i,_ in enumerate(self.fatigues):
                if i!=action-1:
                    self.fatigues[i]=min(self.fatigues[i]+self._fatigue_rep,1.0)
                else:
                    self.fatigues[i]=new_fatigue
        #Update Q values and get error
        self.update(obs, action, reward, new_obs)
        error = self.error[-1]
        #retrain
        obs = new_obs
        old_state = obs
        self.epsilon+=self.e_d*retrain_iterations
        for _ in range(retrain_iterations):
            if random_retrain:
                a = self.random_action()
            else:
                a = self.get_action(obs, avoid_reps=True)
            new_obs, rr, _, _, _ = env.step(a)
            self.update(obs, a, rr, new_obs)
            obs = new_obs
            self.decay_epsilon()
        #reset state and return
        env.set_history(old_state)
        obs = old_state
        self.l_r = old_lr
        return action, reward, obs, info, error
