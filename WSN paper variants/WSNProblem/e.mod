# reset;model e.mod;data stoch.dat;solve;

param W;
param discount;
var Pd = 0.8;


set actions = {"low","high"};
set states = {0..W};
set players = {1,2};


param cost {w in states} = 10 * (exp(0.05*w)-1);
param constants{actions,players};
param S {actions,players};


var sigma {players, states, actions};
var value {players, states} ;

# inrtuder -> 1 and IDS -> 2 

param XI {i in players, w in states, a1 in actions, a2 in actions} = 
	if i=1 then
		-cost[w] + constants[a1,1]
	else
		 cost[w] + constants[a2,1];

var defend_probab {a1 in actions, a2 in actions} = min( 0.16*Pd*S[a2,2]/(S[a1,1] + 0.000001), 1);

var PI {w in states, w_next in states, a in actions, b in actions} =  
	if w_next = w-1 then 
		(w*defend_probab[a,b]/W)
	else if w_next = w then 
		(w*(1-defend_probab[a,b])/W  + (W-w)*defend_probab[a,b]/W)
	else if w_next = w+1 then  
		((W-w)*(1-defend_probab[a,b])/W)  
	else 0;


minimize total_val : 
		sum {i in players, w in states}(
			 value[i,w]
			- sum {a1 in actions, a2 in actions} 
				sigma[1,w,a1]*sigma[2,w,a2]*(XI[i,w,a1,a2] + discount*sum {w2 in states} (value[i,w2]*PI[w2,w,a1,a2])) 
		);

# Note u is current player's strategy, x is others

subject to indi_value_1 {w in states,u in actions}:
	value[1, w] >= 
		sum{x in actions} sigma[2,w,x]*(XI[1,w,u,x] + discount*sum{w2 in states} (value[1,w2]*PI[w2,w,u,x]));
	

subject to indi_value_2 {w in states,u in actions}:
	value[2, w] >= 
		sum{x in actions} sigma[1,w,x]*(XI[2,w,x,u] + discount*sum{w2 in states} (value[2,w2]*PI[w2,w,x,u]));
		
subject to probab_sum { i in players, w in states } : sum {a in actions} sigma[i,w,a] = 1 ;

subject to nonnegative {i in players, w in states, a in actions} : sigma[i,w,a]>=0;


