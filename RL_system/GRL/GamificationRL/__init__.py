from gymnasium.envs.registration import register

register(
    id="GamificationRL/GamificationPreferenceEnv-v0",
    entry_point="GamificationRL.envs:GamificationPreferenceEnv",
)