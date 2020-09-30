function [GM]=Get_IM( T1, GM,acc,GMdt, g, zeta, SA_metric)

if SA_metric==1
    GM.GMpsaT1 = Get_SA_SDoF(T1, GMdt, zeta, acc, g)/g;
else
    Sa_PRODUCT=1;
    nsample=0;
    for Ti=0.2*T1:0.01:3*T1
        nsample=nsample+1;
    end
    for Ti=0.2*T1:0.01:3*T1
        Sa_Ti = Get_SA_SDoF( Ti, GMdt, zeta, acc, g)/g;
        Sa_PRODUCT=Sa_PRODUCT*Sa_Ti^(1/nsample);
    end
    GM.GMpsaT1=(Sa_PRODUCT);
end