function write_SourceSubroutine (INP, FrameType,AnalysisTypeID,ColElementOption,GFX,PZ_Multiplier)


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
    fprintf(INP,'source Spring_Pinching.tcl;\n');
end
if GFX==0 || FrameType~=1
    fprintf(INP,'source Spring_Pinching.tcl;\n');
end
if PZ_Multiplier==1; 	fprintf(INP,'source ConstructPanel_Rectangle.tcl;\n'); 	end
if PZ_Multiplier~=1; 	fprintf(INP,'source ConstructPanel_Cross.tcl;\n'); 		end

if FrameType~=1
    fprintf(INP,'source ConstructBrace.tcl;\n');
    fprintf(INP,'source Spring_Gusset.tcl;\n');
    fprintf(INP,'source FatigueMat.tcl;\n');    
end
if ColElementOption~=1 || FrameType~=1 
    fprintf(INP,'source ConstructFiberColumn.tcl;\n');
    fprintf(INP,'source FiberRHSS.tcl;\n');
    fprintf(INP,'source FiberCHSS.tcl;\n');
    fprintf(INP,'source FiberWF.tcl;\n');
end
if FrameType==3 
    fprintf(INP,'source ConstructFiberBeam.tcl;\n');
end
if AnalysisTypeID==3;    fprintf(INP,'source DynamicAnalysisCollapseSolverX.tcl;\n'); end
fprintf(INP,'source Generate_lognrmrand.tcl;\n');
fprintf(INP,'\n');