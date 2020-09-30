function write_Analysis_Gravity(INP)
global MainDirectory ProjectName ProjectPath
clc;
cd(ProjectPath)
load(ProjectName)
cd(MainDirectory)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                      STATIC GRAVITY ANALYSIS                                    #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

Ws=0;

if NStory==1
    HStory(2)=HStory(1);
end

fprintf(INP,'pattern Plain 100 Linear {\n');
fprintf(INP,'\n');

fprintf(INP,'	# MF COLUMNS LOADS\n');
for Floor=NStory+1:-1:2
    Story=Floor-1;
    for Axis=1:NBay+1
        Bay=max(1,Axis-1);
        if Floor~=NStory+1 && Floor~=2
            if Axis>1  && Axis < NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaIn + cCL_W * Cladding * (0.5*HStory(Story)+0.5*HStory(Story+1)) * (TAin1); end
            if Axis==1 || Axis ==NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaEx + cCL_W * Cladding * (0.5*HStory(Story)+0.5*HStory(Story+1)) * (TAex1); end
        elseif Floor==NStory+1
            if Axis>1  && Axis < NBay+1; Load  = (cDL_W * RoofDL	+ cLL_W * RoofLL    + cGL_W * RoofGL)    * TribAreaIn + cCL_W * Cladding * (0.5*HStory(Story)) * (TAin1); end
            if Axis==1 || Axis ==NBay+1; Load  = (cDL_W * RoofDL    + cLL_W * RoofLL    + cGL_W * RoofGL)    * TribAreaEx + cCL_W * Cladding * (0.5*HStory(Story)) * (TAex1); end
        elseif Floor==2
            if Axis>1  && Axis < NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaIn + cCL_W * Cladding * (0.5*HStory(2)+0.5*HStory(Story)) * (TAin1); end
            if Axis==1 || Axis ==NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaEx + cCL_W * Cladding * (0.5*HStory(2)+0.5*HStory(Story)) * (TAex1); end
        end
        
        if PZ_Multiplier==1
            nodeID=400000+1000*Floor+100*Axis+03;
        else
            nodeID=(10*Floor+Axis)*10;
        end
        
        fprintf(INP,'	load %d 0. %6.3f 0.; ',nodeID,-Load);
        Ws=Ws+Load;
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');

fprintf(INP,'	# EGF COLUMN LOADS\n');
for Floor=NStory+1:-1:2
    Story=Floor-1;
    for Axis=NBay+2:NBay+3
        SumLoadMF  = 0.0;
        if Floor~=NStory+1 && Floor~=2
                                          Load_ToT   = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TA_MF      + cCL_W * Cladding * (HStory(2))* (Perimeter/nMF);
            for AxisX=1:NBay+1
                if AxisX>1  && AxisX < NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaIn + cCL_W * Cladding * (0.5*HStory(Story)+0.5*HStory(Story+1)) * (TAin1); end
                if AxisX==1 || AxisX ==NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaEx + cCL_W * Cladding * (0.5*HStory(Story)+0.5*HStory(Story+1)) * (TAex1); end
                SumLoadMF  = SumLoadMF + Load;
            end
        elseif Floor==NStory+1
                                           Load_ToT  = (cDL_W * RoofDL + cLL_W * RoofLL + cGL_W * RoofGL) * TA_MF      + cCL_W * Cladding * (0.5*HStory(2)) * (Perimeter/nMF);
            for AxisX=1:NBay+1
                if AxisX>1  && AxisX < NBay+1; Load  = (cDL_W * RoofDL + cLL_W * RoofLL + cGL_W * RoofGL) * TribAreaIn + cCL_W * Cladding * 0.5*HStory(Story) * (TAin1); end
                if AxisX==1 || AxisX ==NBay+1; Load  = (cDL_W * RoofDL + cLL_W * RoofLL + cGL_W * RoofGL) * TribAreaEx + cCL_W * Cladding * 0.5*HStory(Story) * (TAex1); end
                SumLoadMF  = SumLoadMF + Load;
            end
        elseif Floor==2
                                          Load_ToT   = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TA_MF      + cCL_W * Cladding * ((HStory(2)*0.5+HStory(1)*0.5)) * (Perimeter/nMF);
            for AxisX=1:NBay+1
                if AxisX>1  && AxisX < NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaIn + cCL_W * Cladding * (HStory(2)*0.5+HStory(Story)*0.5) * (TAin1); end
                if AxisX==1 || AxisX ==NBay+1; Load  = (cDL_W * TypicalDL + cLL_W * TypicalLL + cGL_W * TypicalGL) * TribAreaEx + cCL_W * Cladding * (HStory(2)*0.5+HStory(Story)*0.5) * (TAex1); end
                SumLoadMF  = SumLoadMF + Load;
            end
        end
        Load_GF=(Load_ToT-SumLoadMF)/2;
        nodeID=(Floor*10+Axis)*10;
        fprintf(INP,'	load %d 0. %f 0.; ',nodeID,-Load_GF);
        Ws=Ws+Load_GF;
    end
    fprintf(INP,'\n');
end

fprintf(INP,'\n');
fprintf(INP,'}\n');
fprintf(INP,'\n');

fprintf(INP,'# Conversion Parameters\n');
fprintf(INP,'constraints Plain;\n');
fprintf(INP,'numberer RCM;\n');
fprintf(INP,'system BandGeneral;\n');
fprintf(INP,'test NormDispIncr 1.0e-5 60 ;\n');
fprintf(INP,'algorithm Newton;\n');
fprintf(INP,'integrator LoadControl 0.1;\n');
fprintf(INP,'analysis Static;\n');
fprintf(INP,'analyze 10;\n');
fprintf(INP,'\n');

fprintf(INP,'loadConst -time 0.0;\n');
fprintf(INP,'\n');

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'										puts "Gravity Done"\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

if Units==1
    fprintf(INP,'puts "Seismic Weight= %.3f kN";\n', Ws);
    fprintf(INP,'puts "Seismic Mass=  %.3f kN.sec2/mm";\n', MassTot);
else
    fprintf(INP,'puts "Seismic Weight= %.3f kip";\n', Ws);
    fprintf(INP,'puts "Seismic Mass=  %.3f kip.sec2/in";\n', MassTot);
end

fprintf(INP,'\n');
cd(ProjectPath)
save(ProjectName,'Ws','-append');
cd(MainDirectory)
