function write_PZelement(INP)

global  MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'),'NStory','NBay','PZ_Multiplier','MF_COLUMNS','MF_BEAMS','Units');

if PZ_Multiplier==1
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                          PARALLELOGRAM PANEL ZONE NODES & ELEMENTS                              #\n');
fprintf(INP,'###################################################################################################\n');
elseif PZ_Multiplier==0
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                               CROSS PANEL ZONE NODES & ELEMENTS                                 #\n');
fprintf(INP,'###################################################################################################\n');
end
fprintf(INP,'\n');

fprintf(INP,'# Command Syntax; \n');
if PZ_Multiplier==1
    fprintf(INP,'# Construct_Panel_Rectangle Axis Floor X_Axis Y_Floor E A_Panel I_Panel d_Col d_Beam transfTag;\n');
else
    fprintf(INP,'# Construct_Panel_Cross Axis Floor X_Axis Y_Floor E A_Panel I_Panel d_Col d_Beam transfTag ShapeID;\n');
end
fprintf(INP,'\n');

for Floor=NStory+1:-1:2
    for Axis=1:NBay+1
        Bay=max(1, Axis-1);
        
        Section=MF_COLUMNS{Floor-1,Axis};
        [SecData]=load_SecData (Section,Units);
        idx=find(contains(SecData.Name,Section),1,'first');
        
        columndepth=SecData.d(idx);
        
        Section=MF_BEAMS{Floor-1,Bay};
        [SecData]=load_SecData (Section,Units);
        idx=find(contains(SecData.Name,Section),1,'first');
        
        beamdepth=SecData.d(idx);
        
        if PZ_Multiplier==1
            fprintf(INP,'Construct_Panel_Rectangle %d %d $Axis%d $Floor%d $E $A_Stiff $I_Stiff %5.2f %5.2f $trans_selected; ',Axis,Floor,Axis,Floor,columndepth,beamdepth);
        else
            ShapeID=0;
            if     Axis==1;                             ShapeID=2;  
            elseif Floor==NStory+1;                     ShapeID=3;  
            elseif Axis==1 && Floor==NStory+1;          ShapeID=23; 
            elseif Axis==NBay+1;                        ShapeID=4;  
            elseif Axis==NBay+1 && Floor==NStory+1;     ShapeID=34; end
            fprintf(INP,'Construct_Panel_Cross %2d %2d $Axis%d $Floor%d $E $A_Stiff $I_Stiff %5.2f %5.2f $trans_selected %2d; ',Axis,Floor,Axis,Floor,columndepth,beamdepth, ShapeID);
        end
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');