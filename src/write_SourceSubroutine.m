function write_SourceSubroutine (INP, AnalysisTypeID)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'), 'FrameType', 'ColElementOption','BeamElementOption', 'GFX', 'GFconnection', 'PZ_Multiplier','MFconnection');

fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                       SOURCING SUBROUTINES                                       #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'source DisplayModel3D.tcl;\n');
fprintf(INP,'source DisplayPlane.tcl;\n');
fprintf(INP,'source Spring_PZ.tcl;\n');
fprintf(INP,'source Spring_Connection_FullyRigid.tcl;\n');
fprintf(INP,'source Spring_Column_WideFlange.tcl;\n');
fprintf(INP,'source Spring_Zero.tcl;\n');
fprintf(INP,'source Spring_Rigid.tcl;\n');

if GFX==1
    if GFconnection ==3
        fprintf(INP,'source Spring_Connection_FEPC.tcl;\n');
    end
end

if MFconnection ==3 || GFconnection ==4
    fprintf(INP,'source Spring_Connection_SR_EEPC.tcl;\n');
end

if FrameType~=4 
    if GFX==1
        fprintf(INP,'source Spring_Connection_ShearTab.tcl;\n');
    end
    if GFX==0 || FrameType~=1
        fprintf(INP,'source Spring_Connection_ShearTab.tcl;\n');
    end
    if PZ_Multiplier==1; 	fprintf(INP,'source Construct_Panel_Rectangle.tcl;\n'); 	end
    if PZ_Multiplier~=1; 	fprintf(INP,'source Construct_Panel_Cross.tcl;\n'); 		end


    if FrameType~=1 && FrameType~=4
        fprintf(INP,'source Construct_Brace.tcl;\n');
        fprintf(INP,'source Spring_Gusset.tcl;\n');
        fprintf(INP,'source Spring_Gusset_FB.tcl;\n');
        fprintf(INP,'source Fiber_GP.tcl;\n');
        fprintf(INP,'source FatigueMat.tcl;\n');    
    end
    if ColElementOption~=1 || BeamElementOption~=1 || FrameType~=1 
        if ColElementOption~=1    
        fprintf(INP,'source Construct_FiberColumn.tcl;\n');
        end
        if BeamElementOption~=1    
        fprintf(INP,'source Construct_FiberBeam.tcl;\n');
        end
        fprintf(INP,'source Fiber_RHSS.tcl;\n');
        fprintf(INP,'source Fiber_CHSS.tcl;\n');
        fprintf(INP,'source Fiber_WF.tcl;\n');
    end
    if ColElementOption==4 || BeamElementOption==4
        fprintf(INP,'source Fibe_rWF_HLB.tcl;\n');
    end
    if ColElementOption==5 || BeamElementOption==5
        fprintf(INP,'source Fiber_WF_HLB_Nonlocal.tcl;\n');
    end
    if FrameType==3 
        fprintf(INP,'source Construct_FiberBeam.tcl;\n');
    end
else
    fprintf(INP,'source Construct_FiberColumn.tcl;\n');
    fprintf(INP,'source Construct_FiberBeam.tcl;\n');
    fprintf(INP,'source Fiber_RC_Rectangular.tcl;\n');
    fprintf(INP,'source Spring_IMK_RC.tcl;\n');
    fprintf(INP,'source Construct_Panel_RC.tcl;\n');
    fprintf(INP,'source Define_Material_RC.tcl;\n');
end
if AnalysisTypeID==3 ||  AnalysisTypeID==6;    fprintf(INP,'source Solver_Dynamic.tcl;\n'); end
fprintf(INP,'source Generate_lognrmrand.tcl;\n');
fprintf(INP,'\n');