function write_PreCalculatedGeometry (INP, NStory, NBay, HStory, WBay, WBuilding, MF_BEAMS, CGP_RigidOffset, MGP_RigidOffset, a, b, FrameType, Units)

fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                          PRE-CALCULATIONS                                        #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

if FrameType==1
    
    fprintf(INP,'# REDUCED BEAM SECTION CONNECTION DISTANCE FROM COLUMN\n');
    for Floor=NStory+1:-1:2
        Section=MF_BEAMS{Floor-1,1};
        [SecData]=Load_SecData (Section,Units);
        idx=find(contains(SecData.Name,Section));
        fprintf(INP,'set L_RBS%d  [expr %6.3f * %5.2f + %6.3f * %5.2f/2.];\n',Floor,a,SecData.bf(idx),b,SecData.d(idx));
    end
    fprintf(INP,'\n');
    
else
    
    fprintf(INP,'set pi [expr 2.0*asin(1.0)];\n');
    fprintf(INP,'\n');
    
    fprintf(INP,'# Geometry of Corner Gusset Plate\n');
    for Story=1:NStory
        angle=atand(HStory(Story)/0.5/WBay(1));
        xx = CGP_RigidOffset(Story,1) * cosd(angle);
        yy = CGP_RigidOffset(Story,1) * sind(angle);
        fprintf(INP,'set   X_CGP%d  %.4f;  set   Y_CGP%d  %.4f;\n',Story,xx,Story,yy);
    end
    
    fprintf(INP,'# Geometry of Mid-Span Gusset Plate\n');
    for Story=1:NStory
        xx = MGP_RigidOffset(Story,1) * cosd(angle);
        yy = MGP_RigidOffset(Story,1) * sind(angle);
        fprintf(INP,'set   X_MGP%d  %.4f;  set   Y_MGP%d  %.4f;\n',Story,xx,Story,yy);
    end
    fprintf(INP,'\n');
end

fprintf(INP,'# FRAME GRID LINES\n');
for Floor=NStory+1:-1:2
    Story=Floor-1;
    fprintf(INP,'set Floor%d  %5.2f;\n', Floor,sum(HStory(1:Story)));
end
fprintf(INP,'set Floor1 0.0;\n');
fprintf(INP,'\n');

fprintf(INP,'set Axis1 0.0;\n');
for Axis=2:NBay+1
    Bay=Axis-1;
    fprintf(INP,'set Axis%d %5.2f;\n',Axis,sum(WBay(1:Bay)));
end
fprintf(INP,'set Axis%d %5.2f;\n', NBay+2,WBuilding+WBay(1));
fprintf(INP,'set Axis%d %5.2f;\n', NBay+3,WBuilding+2*WBay(1));
fprintf(INP,'\n');

fprintf(INP,'set HBuilding %5.2f;\n',sum(HStory));
fprintf(INP,'set WFrame %5.2f;\n', WBuilding);
fprintf(INP,'variable HBuilding %5.2f;\n',sum(HStory));
fprintf(INP,'\n');

