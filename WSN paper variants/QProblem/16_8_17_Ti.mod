# reset;model 16_8_17_Ti.mod;data 16_8_17_stable.dat;solve;

param S;
param beta;
 
set players;
set states = {0..30};
set actions;

param mu{actions};		# SrvcPro -> 1
param lamda{actions};	# Router  -> 2

# Refer pg 12, Queue Paper. Theta is indexed as {mu,lamda}
param theta {actions, actions};
param rho {actions, actions};

/*
	Fig 2, pg 13: for{w in states}{print(sum{a in actions} lamda[a]*sigma['Router',w,a]);}
	Fig 3a		: for{w in states}{print(sum{a in actions} mu[a]*sum{w_ in states}(sigma['SrvcPro',w_,a]*T['SrvcPro',w_,w]));}
	Fig 3b		: for{w in states}{print(sum{a in actions} mu[a]*sum{w_ in states}(sigma['SrvcPro',w_,a]*T['Router',w_,w]));}
*/
var sigma {players, states, actions} >= 0;
var value {players, states};


param PI {k in states,s in states, a1 in actions, a2 in actions} = 
	if s=0 and k=1 then
		1
	else if s=S and k=S-1 then
		1
	else if s!=0 and k = s-1 then 
		mu[a1]/(lamda[a2] + mu[a1])  
	else if s!=S and k = s+1 then
		lamda[a2]/(lamda[a2] + mu[a1]);

param h {s in states} = 
	if s = 0 then 0
	else 1.2 * exp(0.2*s*log(1.9));

# Profit to SrvcPro -> 1
param XI{s in states, a1 in actions, a2 in actions } = 
	h[s] + theta[a1,a2] - rho[a1,a2];

var t{i in players,k in states, w in states, a1 in actions, a2 in actions}=
	if i='SrvcPro' then 
		if (XI[w,'low',a2] + beta*sum{w_ in states} value['SrvcPro',w_]*PI[w_,w,'low',a2]) > (XI[w,'high',a2] + beta*sum{w_ in states} value['SrvcPro',w_]*PI[w_,w,'high',a2]) then
			PI[k,w,'low',a2]
		else
			PI[k,w,'high',a2]
	else
		if (-XI[w,a1,'low'] + beta*sum{w_ in states} value['Router',w_]*PI[w_,w,a1,'low']) > (-XI[w,a1,'high'] + beta*sum{w_ in states} value['Router',w_]*PI[w_,w,a1,'high']) then
			PI[k,w,a1,'low']
		else
			PI[k,w,a1,'high'];

var T{i in players, k in states, s in states}=
	sum{a1 in actions, a2 in actions} sigma['SrvcPro',s,a1]*sigma['Router',s,a2]*t[i,k,s,a1,a2];




minimize obj: 
	sum{i in players,w in states} value[i,w];

subject to c1 {w in states, a1 in actions}:
	value['SrvcPro',w] >= sum{a2 in actions} sigma['Router',w,a2]*(XI[w,a1,a2] + beta*sum{w_ in states} value['SrvcPro',w_]*PI[w_,w,a1,a2]);

subject to c2 {w in states, a2 in actions}:
	value['Router',w] >= sum{a1 in actions} sigma['SrvcPro',w,a1]*(-XI[w,a1,a2] + beta*sum{w_ in states} value['Router',w_]*PI[w_,w,a1,a2]);

subject to probab_sum {i in players, s in states}:
	sum {a in actions} sigma[i,s,a] = 1;