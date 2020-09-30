					
function Show_Status_Dynamic(GM_No,GM,SAstep,SAcurrent, SFcurrent,SDRincrmax,PFAincrmax, SA_last_NC,SDR_last_NC,PFA_last_NC,RunTime, CollapseIdentifier, SA_metric, IDA)					
					
%% Clear Window and Display Current GM data
if IDA==1
text1 = '            INCREMENTAL DYNAMIC ANALYSIS   '; str = sprintf('%s', text1);disp(str);
else
text1 = '                 DYNAMIC ANALYSIS          '; str = sprintf('%s', text1);disp(str);    
end
text1 = '           ******************************  '; str = sprintf('%s', text1);disp(str);
text1 = '                                           '; str = sprintf('%s', text1);disp(str);                
text1 = '        GROUND MOTION No.       ';     number = GM_No ;                         str = sprintf('%s %d',         text1, number);       disp(str);
text1 = '        GROUND MOTION NAME      ';     number = GM.Name{GM_No};                 str = sprintf('%s %s',         text1, number);       disp(str);
text1 = '        GROUND MOTION PGA       ';     number = GM.pga(GM_No);  text2=' [g]';   str = sprintf('%s %5.3f %s',   text1, number, text2);disp(str);
if SA_metric==1
text1 = '        GROUND MOTION SA(T1)    ';     number = GM.GMpsaT1;     text2=' [g]';   str = sprintf('%s %5.3f %s',   text1, number, text2);disp(str);
else
text1 = '        GROUND MOTION SAavg     ';     number = GM.GMpsaT1;     text2=' [g]';   str = sprintf('%s %5.3f %s',   text1, number, text2);disp(str);                        
end
text1 = '        GROUND MOTION dt        ';     number = GM.dt(GM_No);        text2=' [sec]'; str = sprintf('%s %5.3f %s',   text1, number, text2);disp(str);
text1 = '        GROUND MOTION Duration  ';     number = GM.duration(GM_No);  text2=' [sec]'; str = sprintf('%s %5.1f %s\n', text1, number, text2);disp(str);
if IDA==1
text1 = 'LAST NC SA                      ';     number = SA_last_NC;  	 text2=' [g]';   str = sprintf('%s %5.3f %s',   text1, number, text2);disp(str);
text1 = 'LAST NC MAXIMUM SDR             ';     number = SDR_last_NC;  	 text2=' [rad]'; str = sprintf('%s %5.3f %s',   text1, number, text2);disp(str);
text1 = 'LAST NC MAXIMUM PFA             ';     number = PFA_last_NC;  	 text2=' [g]';   str = sprintf('%s %5.3f %s\n', text1, number, text2);disp(str);
text1 = 'CURRENT SA Step                 ';     number = SAstep;      	 text2=' [g]';   str = sprintf('%s %5.3f %s',   text1, number, text2);disp(str);
text1 = 'CURRENT SA                      ';     number = SAcurrent;   	 text2=' [g]';   str = sprintf('%s %5.3f %s',   text1, number, text2);disp(str);
text1 = 'CURRENT SCALE FACTOR            ';     number = SFcurrent;                      str = sprintf('%s %4.2f\n',    text1, number);       disp(str);
text1 = 'PREVIOUS MAXIMUM SDR            ';     number = SDRincrmax;  	 text2=' [rad]'; str = sprintf('%s %5.3f %s',   text1, number, text2);disp(str);
text1 = 'PREVIOUS MAXIMUM PFA            ';     number = PFAincrmax;  	 text2=' [g]';   str = sprintf('%s %5.3f %s',   text1, number, text2);disp(str);
text1 = 'CURRENT  RUNTIME                ';     number = RunTime/60;  	 text2=' [min]'; str = sprintf('%s %5.3f %s',   text1, number, text2);disp(str);
end
if CollapseIdentifier==999
str = sprintf('\n%s', 'Collapse Range Reached .... Tracing Collapse Point ...'); disp(str);
end
