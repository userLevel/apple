set prog Frameunset exitset compile falseset rez falsenewer {prog}.a {prog}.pasif {status} != 0   set compile trueendnewer {prog} {prog}.rezif {Status} != 0   set rez trueendset exit onif {rez} == true   compile {prog}.rez keep={prog}endif {compile} == true   cmpl {parameters} {prog}.pas keep={prog}end