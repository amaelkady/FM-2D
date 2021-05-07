function write_Recorders(INP, NStory, NBay, Recorders, Filename, FrameType, BraceLayout, Splice, FloorLink, AnalysisTypeID)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                             RECORDERS                                           #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'# EIGEN VECTORS\n');
for Story=1:NStory
    fprintf(INP,'recorder Node -file $MainFolder/EigenAnalysis/EigenVectorsMode%d.out -node ',Story);
    for Floor=2:NStory+1
        nodeID=400000+1000*Floor+100*1+04;
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
            nodeID_MF  = 400000+1000*Floor+100*(1)+04;
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
                iNode=400000+1000*Fi+100*(1)+04;
                jNode=400000+1000*Fj+100*(1)+04;
                fprintf(INP,'recorder Drift -file $MainFolder/$SubFolder/%s%d_MF.out -iNode %7d -jNode %7d -dof 1 -perpDirn 2; ',Filename.SDR,Story,iNode,jNode);
            else
                iNode=(10*Fi+(1))*10;
                jNode=400000+1000*Fj+100*(1)+04;
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
                nodeID1=400000+1000*Floor+100*(1)+04;
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
                nodeID1=400000+1000*Floor+100*(1)+04;
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
                if Splice(Story,1)==0
                    ElemID=600000+1000*Story+100*Axis;
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%d.out -ele %7d force; ',Filename.Column,Story,Axis,ElemID);
                else
                    ElemID01=600000+1000*Story+100*Axis+01;
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%d.out -ele %7d force; ',Filename.Column,Story,Axis,ElemID01);
                end
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
    
    if Recorders.ColSpring==1
        fprintf(INP,'# COLUMN SPRINGS FORCES\n');
        for Floor=NStory+1:-1:1
            if Floor~=NStory+1 && Floor~=1
                for Axis=1:NBay+1
                    SpringID=900000+Floor*1000+Axis*100+03;
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dT_F.out -ele %7d force; ',Filename.ColSpring, Floor,Axis,SpringID);
                end
                fprintf(INP,'\n');
                for Axis=1:NBay+1
                    SpringID=900000+Floor*1000+Axis*100+01;
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dB_F.out -ele %7d force; ', Filename.ColSpring,Floor,Axis,SpringID);
                end
            end
            if Floor==NStory+1
                for Axis=1:NBay+1
                    SpringID=900000+Floor*1000+Axis*100+01;
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dB_F.out -ele %7d force; ', Filename.ColSpring,Floor,Axis,SpringID);
                end
            end
            if Floor==1
                for Axis=1:NBay+1
                    SpringID=900000+Floor*1000+Axis*100+03;
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dT_F.out -ele %7d force; ', Filename.ColSpring,Floor,Axis,SpringID);
                end
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
        
        fprintf(INP,'# COLUMN SPRINGS ROTATIONS\n');
        for Floor=NStory+1:-1:1
            if Floor~=NStory+1 && Floor~=1
                for Axis=1:NBay+1
                    SpringID=900000+Floor*1000+Axis*100+03;
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dT_D.out -ele %7d deformation; ', Filename.ColSpring, Floor,Axis,SpringID);
                end
                fprintf(INP,'\n');
                for Axis=1:NBay+1
                    SpringID=900000+Floor*1000+Axis*100+01;
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dB_D.out -ele %7d deformation; ', Filename.ColSpring, Floor,Axis,SpringID);
                end
            end
            if Floor==NStory+1
                for Axis=1:NBay+1
                    SpringID=900000+Floor*1000+Axis*100+01;
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dB_D.out -ele %7d deformation; ', Filename.ColSpring, Floor,Axis,SpringID);
                end
            end
            if Floor==1
                for Axis=1:NBay+1
                    SpringID=900000+Floor*1000+Axis*100+03;
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dT_D.out -ele %7d deformation; ', Filename.ColSpring, Floor,Axis,SpringID);
                end
            end
            
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
    end
    
    if Recorders.BeamSpring==1
        fprintf(INP,'# BEAM SPRINGS FORCES\n');
        for Floor=NStory+1:-1:2
            for Axis=1:NBay+1
                SpringID_L=900000+Floor*1000+Axis*100+02;
                SpringID_R=900000+Floor*1000+Axis*100+04;
                if Axis~=1 && Axis~=NBay+1
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dL_F.out -ele  %7d force; ',Filename.BeamSpring,Floor,Axis,SpringID_L);
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dR_F.out -ele  %7d force; ',Filename.BeamSpring,Floor,Axis,SpringID_R);
                end
                if Axis==1
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dR_F.out -ele  %7d force; ',Filename.BeamSpring,Floor,Axis,SpringID_R);
                end
                if Axis==NBay+1
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dL_F.out -ele  %7d force; ',Filename.BeamSpring,Floor,Axis,SpringID_L);
                end
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
        fprintf(INP,'# BEAM SPRINGS ROTATIONS\n');
        for Floor=NStory+1:-1:2
            for Axis=1:NBay+1
                SpringID_L=900000+Floor*1000+Axis*100+02;
                SpringID_R=900000+Floor*1000+Axis*100+04;
                if Axis~=1 && Axis~=NBay+1
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dL_D.out -ele  %7d deformation; ',Filename.BeamSpring,Floor,Axis,SpringID_L);
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dR_D.out -ele  %7d deformation; ',Filename.BeamSpring,Floor,Axis,SpringID_R);
                end
                if Axis==1
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dR_D.out -ele  %7d deformation; ',Filename.BeamSpring,Floor,Axis,SpringID_R);
                end
                if Axis==NBay+1
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dL_D.out -ele  %7d deformation; ',Filename.BeamSpring,Floor,Axis,SpringID_L);
                end
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
    end
    
    
    if Recorders.EGFconnection==1
        fprintf(INP,'# EGF CONNECTION SPRINGS FORCES\n');
        for Floor=NStory+1:-1:2
            for Axis=NBay+2:NBay+3
                SpringID_L=900000+Floor*1000+Axis*100+02;
                SpringID_R=900000+Floor*1000+Axis*100+04;
                if Axis~=1 && Axis~=NBay+1
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dL_F.out -ele  %7d force; ',Filename.EGFconnection,Floor,Axis,SpringID_L);
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dR_F.out -ele  %7d force; ',Filename.EGFconnection,Floor,Axis,SpringID_R);
                end
                if Axis==1
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dR_F.out -ele  %7d force; ',Filename.EGFconnection,Floor,Axis,SpringID_R);
                end
                if Axis==NBay+1
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dL_F.out -ele  %7d force; ',Filename.EGFconnection,Floor,Axis,SpringID_L);
                end
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
        fprintf(INP,'# EGF CONNECTION SPRINGS ROTATIONS\n');
        for Floor=NStory+1:-1:2
            for Axis=NBay+2:NBay+3
                SpringID_L=900000+Floor*1000+Axis*100+02;
                SpringID_R=900000+Floor*1000+Axis*100+04;
                if Axis~=1 && Axis~=NBay+1
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dL_D.out -ele  %7d deformation; ',Filename.EGFconnection,Floor,Axis,SpringID_L);
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dR_D.out -ele  %7d deformation; ',Filename.EGFconnection,Floor,Axis,SpringID_R);
                end
                if Axis==1
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dR_D.out -ele  %7d deformation; ',Filename.EGFconnection,Floor,Axis,SpringID_R);
                end
                if Axis==NBay+1
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dL_D.out -ele  %7d deformation; ',Filename.EGFconnection,Floor,Axis,SpringID_L);
                end
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
    end
    
        
    if Recorders.PZ==1
        fprintf(INP,'# PZ SPRING MOMENT\n');
        for Floor=NStory+1:-1:2
            for Axis=1:NBay+1
                nodeID=900000+Floor*1000+Axis*100+00;
                fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%d_F.out -ele %7d force; ',Filename.PZ,Floor,Axis,nodeID);
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
        
        fprintf(INP,'# PZ SPRING ROTATION\n');
        for Floor=NStory+1:-1:2
            for Axis=1:NBay+1
                nodeID=900000+Floor*1000+Axis*100+00;
                fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%d_D.out -ele %7d deformation; ',Filename.PZ,Floor,Axis,nodeID);
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
    end
    
    if Recorders.Brace==1
        fprintf(INP,'# BRACE ELEMENTS\n');
        for Story=1:NStory
            Fi=Story; Fj=Story+1;
            if rem(Story,2)~=0 || BraceLayout==2
                for Bay=1:NBay
                    AxisI=Bay; AxisJ=Bay+1;
                    ElemID_L=700000+1000*Fi+100*AxisI+11;
                    ElemID_R=700000+1000*Fi+100*AxisJ+11;
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dL_F.out -ele  %7d localForce;\n',Filename.Brace,Story,Bay,ElemID_L);
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dR_F.out -ele  %7d localForce;\n',Filename.Brace,Story,Bay,ElemID_R);
                end
            else
                for Bay=1:NBay
                    AxisI=Bay; AxisJ=Bay+1;
                    ElemID_L=700000+1000*Fj+100*AxisI+99;
                    ElemID_R=700000+1000*Fj+100*AxisJ+99;
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dL_F.out -ele  %7d localForce;\n',Filename.Brace,Story,Bay,ElemID_L);
                    fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dR_F.out -ele  %7d localForce;\n',Filename.Brace,Story,Bay,ElemID_R);
                end
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
        
        fprintf(INP,'# BRACE AXIAL DEFORMATION FROM GHOST BRACES\n');
        for Story=1:NStory
            for Bay=1:NBay
                ElemID_L=4100000+1000*Story+100*Bay;
                ElemID_R=4200000+1000*Story+100*Bay;
                fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dL_D.out -ele  %7d deformation;\n',Filename.Brace,Story,Bay,ElemID_L);
                fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%dR_D.out -ele  %7d deformation;\n',Filename.Brace,Story,Bay,ElemID_R);
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
    end
    
    if Recorders.CGP==1 && BraceLayout==1
        fprintf(INP,'# BRACE CORNER RIGID LINKS FORCES\n');
        for Story=NStory:-1:1
            Fi=Story; Fj=Story+1;
            for Axis=1:NBay+1
                if rem(Story,2)==0
                    ElemID=700000+1000*Fj+100*Axis+99;
                else
                    ElemID=700000+1000*Fi+100*Axis+11;
                end
                fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%d.out -ele %7d globalForce; ',Filename.CGP,Story,Axis,ElemID);
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
    end
    
    
    if Recorders.CGP==1 && BraceLayout==2
        fprintf(INP,'# BRACE CORNER RIGID LINKS FORCES\n');
        for Story=NStory:-1:1
            for Axis=1:NBay+1
                ElemID=700000+1000*Fi+100*Axis+11;
                fprintf(INP,'recorder Element -file $MainFolder/$SubFolder/%s%d%d.out -ele %7d globalForce; ',Filename.CGP,Story,Axis,ElemID);
            end
            fprintf(INP,'\n');
        end
        fprintf(INP,'\n');
    end
    
end
