function write_PZelement(INP,NStory,NBay,PZ_Multiplier,MF_COLUMNS,MF_BEAMS,Units)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                  PANEL ZONE NODES & ELEMENTS                                    #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

if PZ_Multiplier==1; fprintf(INP,'# PANEL ZONE NODES AND ELASTIC ELEMENTS\n');       end
if PZ_Multiplier==2; fprintf(INP,'# CROSS PANEL ZONE NODES AND ELASTIC ELEMENTS\n'); end
fprintf(INP,'# Command Syntax; \n');
if PZ_Multiplier==1
    fprintf(INP,'# ConstructPanel_Rectangle Axis Floor X_Axis Y_Floor E A_Panel I_Panel d_Col d_Beam transfTag \n');
else
    fprintf(INP,'# ConstructPanel_Cross Axis Floor X_Axis Y_Floor E A_Panel I_Panel d_Col d_Beam transfTag ShapeID\n');
end

for Floor=NStory+1:-1:2
    for Axis=1:NBay+1
        Bay=max(1, Axis-1);
        Section=MF_COLUMNS{Floor-1,Axis};
        [SecData]=Load_SecData (Section,Units);
        idx=find(contains(SecData.Name,Section));
        columndepth=SecData.d(idx);
        Section=MF_BEAMS{Floor-1,Bay};
        [SecData]=Load_SecData (Section,Units);
        idx=find(contains(SecData.Name,Section));
        beamdepth=SecData.d(idx);
        if PZ_Multiplier==1
            fprintf(INP,'ConstructPanel_Rectangle %d %d $Axis%d $Floor%d $E $A_Stiff $I_Stiff %5.2f %5.2f $trans_selected; ',Axis,Floor,Axis,Floor,columndepth,beamdepth);
        else
            ShapeID=0;
            if Axis==1;                             ShapeID=2;  end
            if Floor==NStory+1;                     ShapeID=3;  end
            if Axis==1 && Floor==NStory+1;          ShapeID=23; end
            if Axis==NBay+1;                        ShapeID=4;  end
            if Axis==NBay+1 && Floor==NStory+1;     ShapeID=34; end
            fprintf(INP,'ConstructPanel_Cross %2d %2d $Axis%d $Floor%d $E $A_Stiff $I_Stiff %5.2f %5.2f $trans_selected %2d; ',Axis,Floor,Axis,Floor,columndepth,beamdepth, ShapeID);
        end
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');