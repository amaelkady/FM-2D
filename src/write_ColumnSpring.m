function [Py_Col]=write_ColumnSpring (INP, NStory, NBay, HStory, ColElementOption, PM_Option, MF_COLUMNS, MF_BEAMS, Splice, fy, Units)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                           MF COLUMN SPRINGS                                     #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

[Pred]=Get_Col_Axial_Force(PM_Option);

for Floor=NStory+1:-1:1
    Story=min(NStory,Floor);
    if Floor~=NStory+1 && Floor~=1
        for Axis=1:NBay+1
            Bay=max(1,Axis-1);
            
            Section=MF_COLUMNS{Story,Axis}; if Splice(Floor-1,1)==1; Section = MF_COLUMNS{Floor,Axis}; end % to account for the fact that whenever there is a splice, the larger/bottom section is specified in Excel
            [SecDataC]=Load_SecData (Section, Units);
            idx=min(find(contains(SecDataC.Name,Section)));
            
            Section=MF_BEAMS{Floor,Bay};
            [SecDataB1]=Load_SecData (Section, Units);
            idxB1=min(find(contains(SecDataB1.Name,Section)));
            
            Section=MF_BEAMS{Floor-1,Bay};
            [SecDataB2]=Load_SecData (Section, Units);
            idxB2=min(find(contains(SecDataB2.Name,Section)));
            
            L_Col  =  HStory(Story) - 0.5*SecDataB1.d(idxB1) - 0.5*SecDataB2.d(idxB2);
            Ls_Col =  L_Col*0.5;
            Lb_Col =  L_Col;
            
            My_mod = 1.1 * SecDataC.Zx(idx) * fy;
            Py   = SecDataC.Area(idx) * fy;
            Py_Col(Story,Axis)   = SecDataC.Area(idx) * fy;
            PgPy = Pred(Story,Axis)/Py;
            
            iNode = 400000+1000*Floor+100*Axis+03;
            jNode = 100*Floor+10*Axis+03;
            SpringID=900000+Floor*1000+Axis*100+03;
            
            if ColElementOption==1
                fprintf(INP,'Spring_IMK %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f  0 2 %d; ', SpringID,iNode,jNode,SecDataC.Ix(idx),SecDataC.d(idx), SecDataC.h_tw(idx), SecDataC.bf_tf(idx),SecDataC.ry(idx),L_Col,Ls_Col,Lb_Col,My_mod,PgPy,Units);
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID,iNode,jNode);
            end

        end
        fprintf(INP,'\n');

        for Axis=1:NBay+1
            Bay=max(1,Axis-1);
            
            Section=MF_COLUMNS{Story,Axis}; if Splice(Floor-1,1)==1; Section = MF_COLUMNS{Floor,Axis}; end % to account for the fact that whenever there is a splice, the larger/bottom section is specified in Excel
            [SecDataC]=Load_SecData (Section, Units);
            idx=min(find(contains(SecDataC.Name,Section)));
            
            Section=MF_BEAMS{Floor-1,Bay};
            [SecDataB1]=Load_SecData (Section, Units);
            idxB1=min(find(contains(SecDataB1.Name,Section)));
            
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData (Section, Units);
            idxB2=min(find(contains(SecDataB2.Name,Section)));
            
            L_Col  =  HStory(Story) - 0.5*SecDataB1.d(idxB1) - 0.5*SecDataB2.d(idxB2);
            if Floor==2 
                Section=MF_BEAMS{Floor-1,Bay};
                [SecData]=Load_SecData (Section, Units);
                idxB1=min(find(contains(SecDataB1.Name,Section)));
                L_Col  =  HStory(Story-1) - 0.5*SecDataB1.d(idxB1); 
            end
            Ls_Col  = L_Col*0.5;
            Lb_Col =  L_Col;
            
            My_mod = 1.1 * SecDataC.Zx(idx) * fy;
            Py   = SecDataC.Area(idx) * fy;
            Py_Col(Story,Axis)   = SecDataC.Area(idx) * fy;
            PgPy = Pred(Story-1,Axis)/Py;
            
            iNode = 400000+1000*Floor+100*Axis+01;
            jNode = 100*Floor+10*Axis+01;
            SpringID=900000+Floor*1000+Axis*100+01;
            
            if ColElementOption==1
                fprintf(INP,'Spring_IMK %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f  0 2 %d; ', SpringID,iNode,jNode,SecData.Ix(idx),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx),L_Col,Ls_Col,Lb_Col,My_mod,PgPy,Units);
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID,iNode,jNode)
            end

        end

    elseif Floor==NStory+1  && NStory~=1
        
        for Axis=1:NBay+1
            Bay=max(1,Axis-1);
            
            Section=MF_COLUMNS{Story,Axis};
            [SecDataC]=Load_SecData (Section, Units);
            idx=min(find(contains(SecDataC.Name,Section)));
            
            Section=MF_BEAMS{Floor-1,Bay};
            [SecDataB1]=Load_SecData (Section, Units);
            idxB1=min(find(contains(SecDataB1.Name,Section)));
            
            Section=MF_BEAMS{Floor-2,Bay};
            [SecDataB2]=Load_SecData (Section, Units);
            idxB2=min(find(contains(SecDataB2.Name,Section)));
            
            L_Col  = HStory(Story) - 0.5*SecDataB1.d(idxB1) - 0.5*SecDataB2.d(idxB2);
            Ls_Col = L_Col*0.5;
            Lb_Col = L_Col;
            My_mod = 1.1 * SecDataC.Zx(idx) * fy;
            
            Py   = SecDataC.Area(idx) * fy;
            Py_Col(Story,Axis)   = SecDataC.Area(idx) * fy;
            PgPy = Pred(Story,Axis)/Py;
            
            iNode = 400000+1000*Floor+100*Axis+01;
            jNode = 100*Floor+10*Axis+01;
            SpringID=900000+Floor*1000+Axis*100+01;
            
            if ColElementOption==1
                fprintf(INP,'Spring_IMK %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f  0 2 %d; ', SpringID,iNode,jNode,SecDataC.Ix(idx),SecDataC.d(idx), SecDataC.h_tw(idx), SecDataC.bf_tf(idx),SecDataC.ry(idx),L_Col,Ls_Col,Lb_Col,My_mod,PgPy, Units);
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID,iNode,jNode);
            end

        end

    elseif Floor==NStory+1 && NStory==1
        
        for Axis=1:NBay+1
            Bay=max(1,Axis-1);
            
            Section=MF_COLUMNS{Story,Axis};
            [SecDataC]=Load_SecData (Section, Units);
            idx=min(find(contains(SecDataC.Name,Section)));
            
            Section=MF_BEAMS{Floor-1,Bay};
            [SecDataB1]=Load_SecData (Section, Units);
            idxB1=min(find(contains(SecDataB1.Name,Section)));
            
            L_Col  =  HStory(Story) - 0.5*SecDataB1.d(idxB1) - 0.5*SecDataB1.d(idxB1);
            Ls_Col  = L_Col*0.5;
            Lb_Col =  L_Col;
            
            My_mod = 1.1 * SecDataC.Zx(idx) * fy;
            Py   = SecDataC.Area(idx) * fy;
            Py_Col(Story,Axis)   = SecDataC.Area(idx) * fy;
            PgPy = Pred(Story,Axis)/Py;
            
            iNode = 400000+1000*Floor+100*Axis+01;
            jNode = 100*Floor+10*Axis+01;
            SpringID=900000+Floor*1000+Axis*100+01;
            
            if ColElementOption==1
                fprintf(INP,'Spring_IMK %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f  0 2 %d; ', SpringID,iNode,jNode,SecDataC.Ix(idx),SecDataC.d(idx), SecDataC.h_tw(idx), SecDataC.bf_tf(idx),SecDataC.ry(idx),L_Col,Ls_Col,Lb_Col,My_mod,PgPy, Units);
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID,iNode,jNode);
            end
            
        end

    elseif Floor==1
        
        for Axis=1:NBay+1
            Bay=max(1,Axis-1);
            
            Section=MF_COLUMNS{Story,Axis};
            [SecDataC]=Load_SecData (Section, Units);
            idx=min(find(contains(SecDataC.Name,Section)));
            
            Section=MF_BEAMS{Floor,Bay};
            [SecDataB1]=Load_SecData (Section, Units);
            idxB1=min(find(contains(SecDataB1.Name,Section)));
            
            L_Col  =  HStory(Story) - 0.5*SecDataB1.d(idxB1);
            Ls_Col =  L_Col*0.5;
            Lb_Col =  L_Col;
            
            My_mod = 1.1 * SecDataC.Zx(idx) * fy;
            Py   = SecDataC.Area(idx) * fy;
            Py_Col(Story,Axis)   = SecDataC.Area(idx) * fy;
            PgPy = Pred(Story,Axis)/Py;
            
            iNode = (10*Floor+Axis)*10;
            jNode = 100*Floor+10*Axis+03;
            SpringID=900000+Floor*1000+Axis*100+03;
            
            if ColElementOption==1
                fprintf(INP,'Spring_IMK %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f  0 2 %d; ', SpringID,iNode,jNode,SecDataC.Ix(idx),SecDataC.d(idx), SecDataC.h_tw(idx), SecDataC.bf_tf(idx),SecDataC.ry(idx),L_Col,Ls_Col,Lb_Col,My_mod,PgPy, Units);
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID,iNode,jNode);
            end

        end
    end
    
    fprintf(INP,'\n');
end
fprintf(INP,'\n');