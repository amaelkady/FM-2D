function write_Recorders_FiberFrame(INP, NStory, NBay, Recorders, Filename, FloorLink, AnalysisTypeID)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                             RECORDERS                                           #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'# EIGEN VECTORS\n');
for Story=1:NStory
    fprintf(INP,'recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode%d.out -node ',Story);
    for Floor=2:NStory+1
        nodeID=100*Floor+10*1;
        fprintf(INP,'%d ', nodeID);
    end
    fprintf(INP,' -dof 1 "eigen  %d";',Story);
    fprintf(INP,'\n');
end
fprintf(INP,'\n');

if AnalysisTypeID~=1
    
    if Recorders.Time==1
        fprintf(INP,'# TIME\n');
        fprintf(INP,'recorder Node -file $MainFolder/$SubFolder/Time.out  -time -node 110 -dof 1 disp;\n');
        fprintf(INP,'\n');
    end
        
    if Recorders.Support==1
        fprintf(INP,'# SUPPORT REACTIONS\n');
        for Axis=1:NBay+3
            nodeID=(10*1+Axis)*10;
            fprintf(INP,'recorder Node -file $MainFolder/$SubFolder/%s%d.out -node %7d -dof 1 2 6 reaction; ',Filename.Support,Axis,nodeID);
        end
        fprintf(INP,'\n\n');
    end
    
    if Recorders.Disp==1
        fprintf(INP,'# FLOOR LATERAL DISPLACEMENT\n');
        for Floor=NStory+1:-1:2
            nodeID_MF  = (10*Floor+1)*10;
            nodeID_EGF = (10*Floor+(NBay+2))*10;
            fprintf(INP,'recorder Node -file $MainFolder/$SubFolder/%s%d_MF.out  -node %7d -dof 1 disp; ', Filename.Disp,Floor,nodeID_MF);
            if FloorLink==1; fprintf(INP,'\n'); end
            if FloorLink==2; fprintf(INP,'recorder Node -file $MainFolder/$SubFolder/%s%d_EGF.out -node %7d -dof 1 disp;\n',Filename.Disp,Floor,nodeID_EGF); end
        end
        fprintf(INP,'\n');
    end
    
    if Recorders.SDR==1
        fprintf(INP,'# STORY DRIFT RATIO\n');
        for Story=NStory:-1:1
            Fi=Story; Fj=Story+1;
            if Story~=1
                iNode=100*Fi+10*(1);
                jNode=100*Fj+10*(1);
                fprintf(INP,'recorder Drift -file $MainFolder/$SubFolder/%s%d_MF.out -iNode %7d -jNode %7d -dof 1 -perpDirn 2; ',Filename.SDR,Story,iNode,jNode);
            else
                iNode=(10*Fi+(1))*10;
                jNode=100*Fj+10*(1);
                fprintf(INP,'recorder Drift -file $MainFolder/$SubFolder/%s%d_MF.out -iNode %7d -jNode %7d -dof 1 -perpDirn 2; ',Filename.SDR,Story,iNode,jNode);
            end
            iNode=(10*Fi+(NBay+2))*10;
            jNode=(10*Fj+(NBay+2))*10;
            if FloorLink==2; fprintf(INP,'recorder Drift -file $MainFolder/$SubFolder/%s%d_EGF.out -iNode %7d -jNode %7d -dof 1 -perpDirn 2; ',Filename.SDR,Story,iNode,jNode); end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
    end
    
    if Recorders.RFA==1
        fprintf(INP,'# FLOOR ACCELERATION\n');
        for Floor=NStory+1:-1:1
            if Floor~=1
                nodeID1=100*Floor+10*(1);
                nodeID2=(10*Floor+(NBay+2))*10;
                fprintf(INP,'recorder Node -file $MainFolder/$SubFolder/%s%d_MF.out -node %d -dof 1 accel; ',Filename.RFA,Floor,nodeID1);
                if FloorLink==2; fprintf(INP,'recorder Node -file $MainFolder/$SubFolder/%s%d_EGF.out -node %7d -dof 1 accel; ',Filename.RFA,Floor,nodeID2); end
            else
                nodeID1=(10*Floor+(1))*10;
                nodeID2=(10*Floor+(NBay+2))*10;
                fprintf(INP,'recorder Node -file $MainFolder/$SubFolder/%s%d_MF.out -node %d -dof 1 accel; ',Filename.RFA,Floor,nodeID1);
                if FloorLink==2; fprintf(INP,'recorder Node -file $MainFolder/$SubFolder/%s%d_EGF.out -node %7d -dof 1 accel; ',Filename.RFA,Floor,nodeID2); end
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
    end
    
    if Recorders.RFV==1
        fprintf(INP,'# FLOOR VELOCITY\n');
        for Floor=NStory+1:-1:1
            if Floor~=1
                nodeID1=100*Floor+10*(1);
                nodeID2=(10*Floor+(NBay+2))*10;
                fprintf(INP,'recorder Node -file $MainFolder/$SubFolder/%s%d_MF.out -node %7d -dof 1 vel; ',Filename.RFV,Floor,nodeID1);
                if FloorLink==2; fprintf(INP,'recorder Node -file $MainFolder/$SubFolder/%s%d_EGF.out -node %7d -dof 1 vel; ',Filename.RFV,Floor,nodeID2); end
            else
                nodeID1=(10*Floor+(1))*10;
                nodeID2=(10*Floor+(NBay+2))*10;
                fprintf(INP,'recorder Node -file $MainFolder/$SubFolder/%s%d_MF.out -node %7d -dof 1 vel; ',Filename.RFV,Floor,nodeID1);
                if FloorLink==2; fprintf(INP,'recorder Node -file $MainFolder/$SubFolder/%s%d_EGF.out -node %7d -dof 1 vel; ',Filename.RFV,Floor,nodeID2); end
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
    end
    
    if Recorders.FloorLink==1
        fprintf(INP,'# FLOOR LINK FORCE\n');
        for Floor=NStory+1:-1:2
            ElemID=1000+Floor;
            fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d_F.out -ele %7d force;\n',Filename.FloorLink,Floor,ElemID);
        end
        fprintf(INP,'\n');
        
        fprintf(INP,'# FLOOR LINK DEFORMATION\n');
        for Floor=NStory+1:-1:2
            ElemID=1000+Floor;
            fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d_D.out -ele %7d deformation;\n',Filename.FloorLink,Floor,ElemID);
        end
        fprintf(INP,'\n');
    end
    
    if Recorders.Column==1
        fprintf(INP,'# COLUMN ELASTIC ELEMENT FORCES\n');
        for Story=NStory:-1:1
            for Axis=1:NBay+3
                ElemID=600000+1000*Story+100*Axis;
                fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%d.out -ele %7d force; ',Filename.Column,Story,Axis,ElemID);
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
    end
    
    if Recorders.Beam==1
        fprintf(INP,'# BEAM ELASTIC ELEMENT FORCES\n');
        for Floor=NStory+1:-1:2
            if FrameType==1 && rem(Floor,2)~=0
                for Bay=1:NBay
                    ElemID=500000+1000*Floor+100*Bay+00;
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%d.out -ele %7d force; ',Filename.Beam,Floor,Bay,ElemID);
                end
                fprintf(INP,'\n');
            end
            if FrameType~=1 || rem(Floor,2)==0
                for Bay=1:NBay
                    ElemIDL=500000+1000*Floor+100*Bay+01;
                    ElemIDR=500000+1000*Floor+100*Bay+02;
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dL.out -ele %7d force; ',Filename.Beam,Floor,Bay,ElemIDL);
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dR.out -ele %7d force; ',Filename.Beam,Floor,Bay,ElemIDR);
                end
                fprintf(INP,'\n');
            end
        end
        fprintf(INP,'\n');
        
    end
end
