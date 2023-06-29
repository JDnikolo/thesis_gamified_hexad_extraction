import numpy as np
import gymnasium as gym
from gymnasium import spaces
from GamificationRL.envs.gamification_elements import *


class GamificationPreferenceEnv(gym.Env):
    metadata = {"render_modes":["ansi"]}
    pref_history={}
    
    def __init__(self,render_mode=None,
                 gamification_elements=[],
                 hexad_load=hexad_load_dict(pl=5,ach=4,ph=3,dis=2,s=1,fs=0).load_dict,
                 individual_modifications={},
                 repetition_penalty:tuple=(100,50),
                 use_fatigue=False,
                 seed=None):
        self.seed=seed
        self.ge=dict([(elem.name,elem) for elem in gamification_elements])
        self.ge["Nothing"]=nothing

        self.penalty=repetition_penalty

        self.hexad_type=hexad_load
        self.hexad_preference={'pl':1.0000001,'ach':1.0000002,'ph':1.0000003,'dis':1.0000004,'s':1.0000005,'fs':1.0000006}
        self.pref_enabled={'pl':True,'ach':True,'ph':True,'dis':True,'s':True,'fs':True}
        self.action_space = spaces.Discrete(len(self.ge),start=1,seed=seed)
        self._action_to_ge = {}
        self.ge_to_action = {}
        self.fatigue_enabled=use_fatigue
        self.fatigue = {}
        i=1
        for name,element in self.ge.items():
            assert isinstance(element,gamification_element)
            self._action_to_ge[i]=name
            self.ge_to_action[name]=i
            self.fatigue[name]=1.0
            i+=1
        
        self.observation_space = spaces.Tuple([
            spaces.Discrete(len(self.ge),start=1,seed=seed),
            spaces.Discrete(len(self.ge),start=1,seed=seed)
            ])
        
        assert render_mode is None or render_mode in self.metadata["render_mode"]
        self.render_mode=render_mode

        self.ge_mods={}
        self.hexad_mods={}
        for req,mod in individual_modifications:
            if req in list(self._action_to_ge.values()):
                self.ge_mods[req]=mod
            if req in list(self.hexad_type.keys()):
                self.hexad_mods[req]=mod

        self._history=(len(self.ge),len(self.ge))
        super().__init__()
    
    def _get_obs(self):
        return self._history

    def _get_info(self):
        return {"fatigue":self.fatigue,"preference":self.hexad_preference}
    
    def reset(self, seed=None, options=None,):
        super().reset(seed=seed)

        self.hexad_preference={'pl':1.0000001,'ach':1.0000002,'ph':1.0000003,'dis':1.0000004,'s':1.0000005,'fs':1.0000006}
        
        if self.fatigue_enabled:
            for key,value in self.fatigue:
                self.fatigue[key]=1.0

        self._history=(len(self.ge),len(self.ge))
        
        return self._get_obs(),self._get_info() 


    def step(self,action,user_answer=None):
        assert(user_answer in ('accept','decline',None))
        ge_name=self._action_to_ge[action]
        ge=self.ge[ge_name]
        hex_load = self.ge[ge_name].loads
        reward=0
        for type,value in hex_load.items():
            reward+=self.hexad_type[type]*self.hexad_preference[type]*value
        
        if action==self._history[0] and action!=self.ge_to_action["Nothing"]:
            reward-=self.penalty[0]
        if action==self._history[1] and action!=self.ge_to_action["Nothing"]:
            reward-=self.penalty[1]

        if ge_name in self.ge_mods.keys():
            reward+=self.ge_mods[ge_name]
        if ge.type!=None and ge.type in self.hexad_mods.keys():
            reward=reward*self.hexad_mods[ge_name.type]
        
        if self.fatigue_enabled:
            reward=reward*self.fatigue[ge_name]

        if user_answer=='accept' and self.pref_enabled[ge.type]:
            pref=self.hexad_preference[ge.type]
            if pref!=max(self.hexad_preference.values):
                pref += 0.2 if pref<1.0 else 0.1 if pref<1.25 else 0.05
                if pref>1.7: pref=1.7
                self.hexad_preference[ge.type]=pref

        if user_answer=='decline' and self.pref_enabled[ge.type]:
            pref=self.hexad_preference[ge.type]
            pref -= 0.1 if pref<1.0 else 0.2 if pref<1.25 else 0.2
            if pref<0.1 : pref=0.1
            self.hexad_preference[ge.type]=pref

        if user_answer!=None and self.fatigue_enabled:
            for elem in self.fatigue:
                new_fatigue=self.fatigue[elem]
                new_fatigue+=0.01 if elem!=ge_name else -0.05
                if new_fatigue>1.0: new_fatigue=1.0
                if new_fatigue<0.1: new_fatigue=0.1
                self.fatigue[elem]=new_fatigue


        self._history=(self._history[1],action)
        obs=self._get_obs()
        info=self._get_info()
        
        return obs,reward,False,False,info

    def set_history(self,new_history:tuple):
        self._history=new_history
    
    def disable_pref(self,pref):
        assert pref in self.pref_enabled.keys()
        if self.pref_enabled[pref]:
            self.pref_history[pref]=self.hexad_preference[pref]
            self.pref_enabled[pref]=False
            self.hexad_preference[pref]=0.0
    
    def enable_pref(self,pref):
        assert pref in self.pref_enabled.keys()
        if not self.pref_enabled[pref]:
            self.pref_enabled[pref]=True
            self.hexad_preference[pref]=self.pref_history[pref]
            self.pref_history.pop(pref)


    def close(self):
        pass