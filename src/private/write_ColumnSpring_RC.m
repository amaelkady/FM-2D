function [Pc]=write_ColumnSpring_RC (INP, NStory, NBay, HStory, ColElementOption, PM_Option, MF_COLUMNS, MF_BEAMS, fc, bond_slip, Units)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                           MF COLUMN SPRINGS                                     #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

[Pred]=Get_Col_Axial_Force(PM_Option);
for Floor=NStory+1:-1:1
    Story=min(NStory,Floor);
    for Axis=1:NBay+1
        Bay=max(1,Axis-1);
        Section=MF_COLUMNS{Story,Axis};
        [SecData]=Load_SecData_RC (Section);
        
        %             Section=MF_BEAMS{Floor,Bay};
        %             [SecDataBi]=Load_SecData_RC (Section);
        %
        %             Section=MF_BEAMS{Floor-1,Bay};
        %             [SecDataBj]=Load_SecData_RC (Section);
        %
        %             L_Col  =  HStory(Story) - 0.5*SecDataBi.H - 0.5*SecDataBj.H;
        %             Ls_Col =  L_Col*0.5;
        %             Lb_Col =  L_Col;
        
        Pc   = SecData.B * (SecData.H-SecData.coverH) * fc;
        PPc = Pred(Story,Axis)/Pc;
        
        iNode0 = (10*Floor+Axis)*10;

        iNode03 = 400000+1000*Floor+100*Axis+03;
        jNode03 = 100*Floor+10*Axis+03;
        SpringID03=900000+Floor*1000+Axis*100+03;

        iNode01 = 400000+1000*Floor+100*Axis+01;
        jNode01 = 100*Floor+10*Axis+01;
        SpringID01=900000+Floor*1000+Axis*100+01;
            
        if Floor~=NStory+1 && Floor~=1           
            if ColElementOption==1
                fprintf(INP,'Spring_IMK_RC %d %d %d $fc $Ec $fyR $Er %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %d %.3f %d;\n', SpringID03, iNode03, jNode03, SecData.B, SecData.H, SecData.coverH, SecData.s, SecData.rho_Top, SecData.rho_Bot, SecData.rho_Int, SecData.rho_Shear, bond_slip, PPc, Units);
                fprintf(INP,'Spring_IMK_RC %d %d %d $fc $Ec $fyR $Er %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %d %.3f %d;  ', SpringID01, iNode01, jNode01, SecData.B, SecData.H, SecData.coverH, SecData.s, SecData.rho_Top, SecData.rho_Bot, SecData.rho_Int, SecData.rho_Shear, bond_slip, PPc, Units);
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d;\n', SpringID03,iNode03,jNode03);
                fprintf(INP,'Spring_Rigid %7d %7d %7d;  ', SpringID01,iNode01,jNode01)
            end
        end
        
        if Floor==NStory+1
            if ColElementOption==1
                fprintf(INP,'Spring_IMK_RC %d %d %d $fc $Ec $fyR $Er %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %d %.3f %d; ', SpringID01, iNode01, jNode01, SecData.B, SecData.H, SecData.coverH, SecData.s, SecData.rho_Top, SecData.rho_Bot, SecData.rho_Int, SecData.rho_Shear, bond_slip, PPc, Units);
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID01,iNode01,jNode01);
            end
        end
        
        if Floor==1
            % L_Col  =  HStory(Story) - 0.5*SecDataBi.H;
            if ColElementOption==1
                fprintf(INP,'Spring_IMK_RC %d %d %d $fc $Ec $fyR $Er %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %d %.3f %d; ', SpringID01 ,iNode0, jNode03, SecData.B, SecData.H, SecData.coverH, SecData.s, SecData.rho_Top, SecData.rho_Bot, SecData.rho_Int, SecData.rho_Shear, bond_slip, PPc, Units);
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID01,iNode0,jNode03);
            end
        end
    
    end
    
    fprintf(INP,'\n');
end
fprintf(INP,'\n');