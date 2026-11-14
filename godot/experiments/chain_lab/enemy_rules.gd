extends RefCounted
## Trial balance, not a claim that the original full bestiary has been ported.
const NAMES=["虛空步兵","疾行獸","護甲衛士","虛空薩滿","鼓舞精英","首領"]
static func pool(wave: int) -> Array:
 if wave<=2:return [0,0,1]
 if wave==3:return [0,0,1,2]
 if wave<=5:return [0,0,1,2,4]
 return [0,0,1,2,3,4]
static func stats(kind: int,wave: int,boss: bool=false) -> Dictionary:
 var late:=1.0+maxi(0,wave-8)*0.025
 return {"hp":([28.0,20.0,60.0,38.0,95.0,300.0][kind]+wave*(25 if boss else 3))*(1.0 if boss else late),"speed":[22.0,34.0,16.0,20.0,23.0,15.0][kind]+wave*0.35,"damage":(1.5+wave*0.18)*(1.0 if boss else late)}
