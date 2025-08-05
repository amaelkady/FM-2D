function write_SourceSubroutine (INP, FrameType, AnalysisTypeID, ColElementOption, GFX, EGFconnection, PZ_Multiplier)


fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                       SOURCING SUBROUTINES                                       #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'source DisplayModel3D.tcl;\n');
fprintf(INP,'source DisplayPlane.tcl;\n');
fprintf(INP,'source Spring_PZ.tcl;\n');
fprintf(INP,'source Spring_IMK.tcl;\n');
fprintf(INP,'source Spring_Zero.tcl;\n');
fprintf(INP,'source Spring_Rigid.tcl;\n');

if GFX==1
    if EGFconnection ==3
        fprintf(INP,'source Spring_FEPC.tcl;\n');
    elseif EGFconnection ==4
        fprintf(INP,'source Spring_EEPC.tcl;\n');
    end
end

if FrameType~=4 
    if GFX==1
        fprintf(INP,'source Spring_Pinching.tcl;\n');
    end
    if GFX==0 || FrameType~=1
        fprintf(INP,'source Spring_Pinching.tcl;\n');
    end
    if PZ_Multiplier==1; 	fprintf(INP,'source ConstructPanel_Rectangle.tcl;\n'); 	end
    if PZ_Multiplier~=1; 	fprintf(INP,'source ConstructPanel_Cross.tcl;\n'); 		end


    if FrameType~=1 && FrameType~=4
        fprintf(INP,'source ConstructBrace.tcl;\n');
        fprintf(INP,'source Spring_Gusset.tcl;\n');
        fprintf(INP,'source Spring_Gusset_FB.tcl;\n');
        fprintf(INP,'source FiberGP.tcl;\n');
        fprintf(INP,'source FatigueMat.tcl;\n');    
    end
    if ColElementOption~=1 || FrameType~=1 
        fprintf(INP,'source ConstructFiberColumn.tcl;\n');
        fprintf(INP,'source FiberRHSS.tcl;\n');
        fprintf(INP,'source FiberCHSS.tcl;\n');
        fprintf(INP,'source FiberWF.tcl;\n');
    end
    if ColElementOption==4
        fprintf(INP,'source FiberWF_HLB.tcl;\n');
    end
    if FrameType==3 
        fprintf(INP,'source ConstructFiberBeam.tcl;\n');
    end
else
    fprintf(INP,'source ConstructFiberColumn.tcl;\n');
    fprintf(INP,'source ConstructFiberBeam.tcl;\n');
    fprintf(INP,'source FiberRC_Rectangular.tcl;\n');
    fprintf(INP,'source Spring_IMK_RC.tcl;\n');
    fprintf(INP,'source ConstructPanel_RC.tcl;\n');
    fprintf(INP,'source Define_Material_RC.tcl;\n');
end
if AnalysisTypeID==3 ||  AnalysisTypeID==6;    fprintf(INP,'source DynamicAnalysisCollapseSolverX.tcl;\n'); end
fprintf(INP,'source Generate_lognrmrand.tcl;\n');
fprintf(INP,'\n');