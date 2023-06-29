hexad_types={'pl','ach','ph','dis','s','fs'}
class hexad_load_dict:
    def __init__(self,pl=0,ach=0,ph=0,dis=0,s=0,fs=0,factor=1.0):
        self.load_dict={'pl':pl,'ach':ach,'ph':ph,'dis':dis,'s':s,'fs':fs}
        for key,value in self.load_dict.items():
            self.load_dict[key]=(float(value)*factor)
    def from_list(values:list=[0,0,0,0,0,0],factor=1.0):
        return hexad_load_dict(pl=values[0],ach=values[1],ph=values[2],
                   dis=values[3],s=values[4],fs=values[5],factor=factor)


        
class gamification_element:
    def __init__(self,name:str,primary_type:str,hexad_loads:hexad_load_dict):
        self.name=name
        assert(hexad_loads.load_dict.keys()==hexad_types)
        self.loads=hexad_loads.load_dict
        assert(primary_type in hexad_types or primary_type==None)
        self.type=primary_type
    def __str__(self) -> str:
        return self.name+'\nPrimary type: {self.type} - Loads: '+self.loads.load_dict.__str__()
    
##Marchewski weights
sample_gamification_elements={
    ##Player-oriented
    'Badges':gamification_element("Badges",'pl',
                         hexad_load_dict(pl=100,ach=25)),
    'Leaderboard':gamification_element("Leaderboard",'pl',
                                       hexad_load_dict(pl=100,ach=25,s=25,ph=25)),
    #Achiever-oriented
    'Levels':gamification_element('Levels','ach',
                                  hexad_load_dict(ach=100,pl=50)),
    'Challenges':gamification_element('Challenges','ach',
                                      hexad_load_dict(ach=100)),
    #Free Spirit-oriented
    'Exploration':gamification_element('Exploration','fs',
                                       hexad_load_dict(fs=100)),
    'Easter Eggs':gamification_element('Easter Eggs','fs',
                                       hexad_load_dict(fs=100,pl=25)),
    #Disruptor-oriented
    'Innovation Platform':gamification_element('Innovation Platform','dis',
                                               hexad_load_dict(dis=100)),
    'Development Tools':gamification_element('Development Tools','dis',
                                             hexad_load_dict(dis=100,fs=25)),
    #Philanthropist-oriented
    'Administrative Roles':gamification_element('Administrative Roles','ph',
                                   hexad_load_dict(ph=100,s=25)),
    'Gifting':gamification_element('Gifting','ph',
                                   hexad_load_dict(ph=100)),
    #Socializer-oriented
    'Social Discovery':gamification_element('Social Discovery','s',
                                            hexad_load_dict(s=100,ph=25)),
    'Competition':gamification_element('Competition','s',
                                       hexad_load_dict(s=100,pl=50)),
}
#average per type: 63.7
#average including zeroes: 19.5
#f=2.90
f=1.8
##TODO:Weights based on observed correlations
corr_gamification_elements={
    ##Player-oriented
    'Badges':gamification_element("Badges",'pl',
                         hexad_load_dict(s=16,ach=21,pl=27,factor=f)),
    'Leaderboard':gamification_element("Leaderboard",'pl',
                                       hexad_load_dict(s=20,dis=17,pl=30,factor=f)),
    #Achiever-oriented
    'Levels':gamification_element('Levels','ach',
                                  hexad_load_dict(s=17,fs=20,ach=24,pl=30,factor=f)),
    'Challenges':gamification_element('Challenges','ach',
                                      hexad_load_dict(fs=41,ach=46,dis=21,pl=32,factor=f)),
    #Free Spirit-oriented
    'Exploration':gamification_element('Exploration','fs',
                                       hexad_load_dict(fs=35,factor=f)),
    'Easter Eggs':gamification_element('Easter Eggs','fs',
                                       hexad_load_dict(s=14,fs=25,dis=15,pl=16,factor=f)),
    #Disruptor-oriented
    'Innovation Platform':gamification_element('Innovation Platform','dis',
                                               hexad_load_dict(dis=32,pl=17,factor=f)),
    'Development Tools':gamification_element('Development Tools','dis',
                                             hexad_load_dict(dis=29,pl=14,factor=f)),
    #Philanthropist-oriented
    'Administrative Roles':gamification_element('Administrative Roles','ph',
                                   hexad_load_dict(ph=25,dis=20,factor=f)),
    'Gifting':gamification_element('Gifting','ph',
                                   hexad_load_dict(s=16,pl=21,ph=30,factor=f)),
    #Socializer-oriented
    'Social Discovery':gamification_element('Social Discovery','s',
                                            hexad_load_dict(s=20,dis=18,pl=22,factor=f)),
    'Competition':gamification_element('Competition','s',
                                       hexad_load_dict(s=22,fs=25,ach=16,dis=32,pl=24,factor=f)),
}
nothing=gamification_element("Nothing",None,hexad_load_dict(pl=0.01,ach=0.01,ph=0.01,dis=0.01,s=0.01,fs=0.01))
