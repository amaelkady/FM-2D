function write_BeamSpring_MRF_RC (INP, NStory, NBay, WBay, ModelELOption, MF_COLUMNS, MF_BEAMS, bond_slip, Units)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                           MF BEAM SPRINGS                                       #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

if ModelELOption==2
    for Floor=NStory+1:-1:2
        Story=Floor-1;
        for Axis=1:NBay+1
            Bay=max(1,Axis-1);
            Axisi=Bay; Axisj=Bay+1;
            
            SpringID_L=900000+Floor*1000+Axis*100+02;
            SpringID_R=900000+Floor*1000+Axis*100+04;
            
            if Axis~=1 && Axis~=NBay+1
                iNode = 100*Floor+10*Axis+02;
                jNode = 400000+1000 *Floor+100 *Axis+02;
                fprintf(INP,'Spring_Rigid %d %d %d; ',SpringID_L,iNode,jNode);
                iNode = 100*Floor+10*Axis+04;
                jNode = 400000+1000 *Floor+100 *Axis+04;
                fprintf(INP,'Spring_Rigid %d %d %d; ',SpringID_R,iNode,jNode);
            end
            if Axis==1
                iNode = 100*Floor+10*Axis+04;
                jNode = 400000+1000 *Floor+100 *Axis+04;
                fprintf(INP,'Spring_Rigid %d %d %d; ',SpringID_R,iNode,jNode);
            end
            if Axis==NBay+1
                iNode = 100*Floor+10*Axis+02;
                jNode = 400000+1000 *Floor+100 *Axis+02;
                fprintf(INP,'Spring_Rigid %d %d %d; ',SpringID_L,iNode,jNode);
            end
        end
        fprintf(INP,'\n');
    end
    
else
    
    fprintf(INP,'\n');

    for Floor=NStory+1:-1:2
        Story=min(NStory,Floor);
        for Axis=1:NBay+1
            Bay=max(1,Axis-1);
            Axisi=Bay; Axisj=Bay+1;
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData_RC (Section); 
            
            %Section=MF_COLUMNS{Story,Axisi};
            %[SecDataCi]=Load_SecData_RC (Section); 
            
            %Section=MF_COLUMNS{Story,Axisj};
            %[SecDataCj]=Load_SecData_RC (Section); 
            
            %L_BEAM  =  WBay(Bay) - 0.5*SecDataCi.H - 0.5*SecDataCj.H;
            %Ls_BEAM = (WBay(Bay) - 0.5*SecDataCi.H - 0.5*SecDataCj.H)*0.5;
            
            SpringID_L=900000+Floor*1000+Axis*100+02;
            SpringID_R=900000+Floor*1000+Axis*100+04;
            
            Node20 = 100*Floor+10*Axis+02;
            Node02 = 400000+1000 *Floor+100 *Axis+02;
            Node40 = 100*Floor+10*Axis+04;
            Node04 = 400000+1000 *Floor+100 *Axis+04;
            
            if Axis~=1
                fprintf(INP,'Spring_IMK_RC %d %d %d $fc $Ec $fyR $Er %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %d 0.0 %d; ', SpringID_L, Node20, Node02, SecData.B, SecData.H, SecData.coverH, SecData.s, SecData.rho_Top, SecData.rho_Bot, SecData.rho_Int, SecData.rho_Shear, bond_slip, Units);
            end
            if Axis~=NBay+1
                fprintf(INP,'Spring_IMK_RC %d %d %d $fc $Ec $fyR $Er %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %d 0.0 %d; ', SpringID_R, Node04, Node40, SecData.B, SecData.H, SecData.coverH, SecData.s, SecData.rho_Top, SecData.rho_Bot, SecData.rho_Int, SecData.rho_Shear, bond_slip, Units);
            end
        end
        fprintf(INP,'\n');
    end
end
fprintf(INP,'\n');