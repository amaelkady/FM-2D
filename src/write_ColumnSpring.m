function [Py_Col]=write_ColumnSpring (INP, NStory, NBay, HStory, ColElementOption, PM_Option, MF_COLUMNS, MF_BEAMS, fy, Units)

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
            Section=MF_COLUMNS{Story,Axis};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            Section=MF_BEAMS{Floor,Bay};
            [SecData]=Load_SecData (Section, Units);
            idxB1=find(contains(SecData.Name,Section));
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData (Section, Units);
            idxB2=find(contains(SecData.Name,Section));
            
            L_Col  =  HStory(Story) - 0.5*SecData.d(idxB1) - 0.5*SecData.d(idxB2);
            Ls_Col =  L_Col*0.5;
            Lb_Col =  L_Col;
            
            My_mod = 1.1 * SecData.Zx(idx) * fy;
            Py   = SecData.Area(idx) * fy;
            Py_Col(Story,Axis)   = SecData.Area(idx) * fy;
            PgPy = Pred(Story,Axis)/Py;
            
            iNode = 400000+1000*Floor+100*Axis+03;
            jNode = 100*Floor+10*Axis+03;
            SpringID=900000+Floor*1000+Axis*100+03;
            if ColElementOption==1
                fprintf(INP,'Spring_IMK %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f  0 0 %d; ', SpringID,iNode,jNode,SecData.Ix(idx),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx),L_Col,Ls_Col,Lb_Col,My_mod,PgPy,Units);
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID,iNode,jNode);
            end
        end
        fprintf(INP,'\n');
        for Axis=1:NBay+1
            Bay=max(1,Axis-1);
            Section=MF_COLUMNS{Story,Axis};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData (Section, Units);
            idxB1=find(contains(SecData.Name,Section));
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData (Section, Units);
            idxB2=find(contains(SecData.Name,Section));
            
            L_Col  =  HStory(Story) - 0.5*SecData.d(idxB1) - 0.5*SecData.d(idxB2);
            if Floor==2 
                Section=MF_BEAMS{Floor-1,Bay};
                [SecData]=Load_SecData (Section, Units);
                idxB1=find(contains(SecData.Name,Section));
                L_Col  =  HStory(Story-1) - 0.5*SecData.d(idxB1); 
            end
            Ls_Col  = L_Col*0.5;
            Lb_Col =  L_Col;
            
            My_mod = 1.1 * SecData.Zx(idx) * fy;
            Py   = SecData.Area(idx) * fy;
            Py_Col(Story,Axis)   = SecData.Area(idx) * fy;
            PgPy = Pred(Story-1,Axis)/Py;
            
            iNode = 400000+1000*Floor+100*Axis+01;
            jNode = 100*Floor+10*Axis+01;
            SpringID=900000+Floor*1000+Axis*100+01;
            if ColElementOption==1
                fprintf(INP,'Spring_IMK %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f  0 0 %d; ', SpringID,iNode,jNode,SecData.Ix(idx),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx),L_Col,Ls_Col,Lb_Col,My_mod,PgPy,Units);
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID,iNode,jNode)
            end
        end
    end
    if Floor==NStory+1  && NStory~=1
        for Axis=1:NBay+1
            Bay=max(1,Axis-1);
            Section=MF_COLUMNS{Story,Axis};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData (Section, Units);
            idxB1=find(contains(SecData.Name,Section));
            Section=MF_BEAMS{Floor-2,Bay};
            [SecData]=Load_SecData (Section, Units);
            idxB2=find(contains(SecData.Name,Section));
            
            L_Col  = HStory(Story) - 0.5*SecData.d(idxB1) - 0.5*SecData.d(idxB2);
            Ls_Col = L_Col*0.5;
            Lb_Col = L_Col;
            My_mod = 1.1 * SecData.Zx(idx) * fy;
            
            Py   = SecData.Area(idx) * fy;
            Py_Col(Story,Axis)   = SecData.Area(idx) * fy;
            PgPy = Pred(Story,Axis)/Py;
            
            iNode = 400000+1000*Floor+100*Axis+01;
            jNode = 100*Floor+10*Axis+01;
            SpringID=900000+Floor*1000+Axis*100+01;
            if ColElementOption==1
                fprintf(INP,'Spring_IMK %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f  0 0 %d; ', SpringID,iNode,jNode,SecData.Ix(idx),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx),L_Col,Ls_Col,Lb_Col,My_mod,PgPy, Units);
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID,iNode,jNode);
            end
        end
    end
    if Floor==NStory+1 && NStory==1
        for Axis=1:NBay+1
            Bay=max(1,Axis-1);
            Section=MF_COLUMNS{Story,Axis};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            Section=MF_BEAMS{Floor-1,Bay};
            [SecData]=Load_SecData (Section, Units);
            idxB1=find(contains(SecData.Name,Section));
            
            L_Col  =  HStory(Story) - 0.5*SecData.d(idxB1) - 0.5*SecData.d(idxB1);
            Ls_Col  = L_Col*0.5;
            Lb_Col =  L_Col;
            
            My_mod = 1.1 * SecData.Zx(idx) * fy;
            Py   = SecData.Area(idx) * fy;
            Py_Col(Story,Axis)   = SecData.Area(idx) * fy;
            PgPy = Pred(Story,Axis)/Py;
            
            iNode = 400000+1000*Floor+100*Axis+01;
            jNode = 100*Floor+10*Axis+01;
            SpringID=900000+Floor*1000+Axis*100+01;
            if ColElementOption==1
                fprintf(INP,'Spring_IMK %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f  0 0 %d; ', SpringID,iNode,jNode,SecData.Ix(idx),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx),L_Col,Ls_Col,Lb_Col,My_mod,PgPy, Units);
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID,iNode,jNode);
            end
        end
    end
    if Floor==1
        for Axis=1:NBay+1
            Bay=max(1,Axis-1);
            Section=MF_COLUMNS{Story,Axis};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            Section=MF_BEAMS{Floor,Bay};
            [SecData]=Load_SecData (Section, Units);
            idxB1=find(contains(SecData.Name,Section));
            
            L_Col  =  HStory(Story) - 0.5*SecData.d(idxB1);
            Ls_Col =  L_Col*0.5;
            Lb_Col =  L_Col;
            
            My_mod = 1.1 * SecData.Zx(idx) * fy;
            Py   = SecData.Area(idx) * fy;
            Py_Col(Story,Axis)   = SecData.Area(idx) * fy;
            PgPy = Pred(Story,Axis)/Py;
            
            iNode = (10*Floor+Axis)*10;
            jNode = 100*Floor+10*Axis+03;
            SpringID=900000+Floor*1000+Axis*100+03;
            if ColElementOption==1
                fprintf(INP,'Spring_IMK %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f  0 0 %d; ', SpringID,iNode,jNode,SecData.Ix(idx),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx),L_Col,Ls_Col,Lb_Col,My_mod,PgPy, Units);
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID,iNode,jNode);
            end
        end
    end
    
    fprintf(INP,'\n');
end
fprintf(INP,'\n');