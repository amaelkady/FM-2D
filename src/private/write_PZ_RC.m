function write_PZ_RC(INP,NStory,NBay,MF_COLUMNS,MF_BEAMS)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                           SHEAR PANEL ZONE NODES, ELEMENTS & SPRING                                    #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'# Command Syntax; \n');
fprintf(INP,'# ConstructPanel_RC Axis Floor X_Axis Y_Floor E A_Panel I_Panel d_Col d_Beam transfTag ShapeID\n');

for Floor=NStory+1:-1:2
    for Axis=1:NBay+1
        Bay=max(1, Axis-1);
        Section=MF_COLUMNS{Floor-1,Axis};
        [SecData]=Load_SecData_RC (Section);
        columndepth=SecData.H;
        
        Section=MF_BEAMS{Floor-1,Bay};
        [SecData]=Load_SecData_RC (Section);
        beamdepth=SecData.H;
        
        ShapeID=0;
        if Axis==1;                             ShapeID=2;  end
        if Floor==NStory+1;                     ShapeID=3;  end
        if Axis==1 && Floor==NStory+1;          ShapeID=23; end
        if Axis==NBay+1;                        ShapeID=4;  end
        if Axis==NBay+1 && Floor==NStory+1;     ShapeID=34; end

        fprintf(INP,'ConstructPanel_RC %2d %2d $Axis%d $Floor%d $E $A_Stiff $I_Stiff %5.2f %5.2f $trans_selected %2d; ',Axis,Floor,Axis,Floor,columndepth,beamdepth, ShapeID);

    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');