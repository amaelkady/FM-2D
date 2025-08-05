function [GM]=Get_IM( T1, GM,acc,GMdt, g, zeta, SA_metric, coeff_T_lower, coeff_T_upper)

arguments
    T1             (1,1) double {mustBePositive}
    GM
    acc
    GMdt           (1,1) double {mustBePositive}
    g              (1,1) double {mustBePositive}
    zeta           (1,1) double {mustBePositive}
    SA_metric      (1,1) double {mustBePositive}
    coeff_T_lower  (1,1) double {mustBePositive} = 0.2
    coeff_T_upper  (1,1) double {mustBePositive} = 3.0
end


if SA_metric==1
    GM.GMpsaT1 = Get_SA_SDoF(T1, GMdt, zeta, acc, g)/g;
else
    Sa_PRODUCT=1;
    nsample=0;
    for Ti=coeff_T_lower*T1:0.01:coeff_T_upper*T1
        nsample=nsample+1;
    end
    for Ti=coeff_T_lower*T1:0.01:coeff_T_upper*T1
        Sa_Ti = Get_SA_SDoF( Ti, GMdt, zeta, acc, g)/g;
        Sa_PRODUCT=Sa_PRODUCT*Sa_Ti^(1/nsample);
    end
    GM.GMpsaT1=(Sa_PRODUCT);
end