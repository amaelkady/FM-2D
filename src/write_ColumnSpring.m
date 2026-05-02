function [Py_Col]=write_ColumnSpring (INP, NStory, NBay, HStory, ColElementOption, PM_Option, MF_COLUMNS, MF_BEAMS, Splice, fy, Units)

fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                           MF COLUMN SPRINGS                                     #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');

[Pred]=Get_Col_Axial_Force(PM_Option);

for Fi=NStory+1:-1:1
    Si=min(NStory,Fi);
    if Fi~=NStory+1 && Fi~=1
        for Axis=1:NBay+1
            Bay=max(1,Axis-1);

            Section=MF_COLUMNS{Si,Axis}; if Splice(Fi-1,1)==1; Section = MF_COLUMNS{Fi,Axis}; end % to account for the fact that whenever there is a splice, the larger/bottom section is specified in Excel
            SectionC=Section;
            [SecDataC]=Load_SecData (Section, Units);
            idx=min(find(contains(SecDataC.Name,Section)));

            Section=MF_BEAMS{Fi,Bay};
            [SecDataB1]=Load_SecData (Section, Units);
            idxB1=min(find(contains(SecDataB1.Name,Section)));

            Section=MF_BEAMS{Fi-1,Bay};
            [SecDataB2]=Load_SecData (Section, Units);
            idxB2=min(find(contains(SecDataB2.Name,Section)));

            L_Col  =  HStory(Si) - 0.5*SecDataB1.d(idxB1) - 0.5*SecDataB2.d(idxB2);
            Ls_Col =  L_Col*0.5;
            Lb_Col =  L_Col;

            My_mod = SecDataC.Zx(idx) * fy;
            Py   = SecDataC.Area(idx) * fy;
            Py_Col(Si,Axis)   = SecDataC.Area(idx) * fy;
            PgPy = Pred(Si,Axis)/Py;

            iNode = 400000+1000*Fi+100*Axis+03;
            jNode = 100*Fi+10*Axis+03;
            SpringID=900000+Fi*1000+Axis*100+03;

            if ColElementOption==1
                if isempty(strfind(SectionC, 'W'))==0
                    fprintf(INP,'Spring_Column_WideFlange %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %d; ', SpringID,iNode,jNode,SecDataC.Ix(idx),SecDataC.d(idx), SecDataC.h_tw(idx), SecDataC.bf_tf(idx),SecDataC.ry(idx),L_Col,Ls_Col,Lb_Col,My_mod,PgPy,Units);
                elseif isempty(strfind(SectionC, 'HSS'))==0
                    fprintf(INP,'Spring_Column_HSS %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f; ', SpringID,iNode,jNode,SecDataC.Ix(idx), SecDataC.h_t(idx),L_Col,My_mod,PgPy);
                end
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID,iNode,jNode);
            end

        end
        fprintf(INP,'\n');

        for Axis=1:NBay+1
            Bay=max(1,Axis-1);

            Section=MF_COLUMNS{Si,Axis}; if Splice(Fi-1,1)==1; Section = MF_COLUMNS{Fi,Axis}; end % to account for the fact that whenever there is a splice, the larger/bottom section is specified in Excel
            SectionC=Section;
            [SecDataC]=Load_SecData (Section, Units);
            idx=min(find(contains(SecDataC.Name,Section)));

            Section=MF_BEAMS{Fi-1,Bay};
            [SecDataB1]=Load_SecData (Section, Units);
            idxB1=min(find(contains(SecDataB1.Name,Section)));

            Section=MF_BEAMS{Fi-1,Bay};
            [SecData]=Load_SecData (Section, Units);
            idxB2=min(find(contains(SecDataB2.Name,Section)));

            L_Col  =  HStory(Si) - 0.5*SecDataB1.d(idxB1) - 0.5*SecDataB2.d(idxB2);
            if Fi==2
                Section=MF_BEAMS{Fi-1,Bay};
                [SecData]=Load_SecData (Section, Units);
                idxB1=min(find(contains(SecDataB1.Name,Section)));
                L_Col  =  HStory(Si-1) - 0.5*SecDataB1.d(idxB1);
            end
            Ls_Col  = L_Col*0.5;
            Lb_Col =  L_Col;

            My_mod = 1.1 * SecDataC.Zx(idx) * fy;
            Py   = SecDataC.Area(idx) * fy;
            Py_Col(Si,Axis)   = SecDataC.Area(idx) * fy;
            PgPy = Pred(Si-1,Axis)/Py;

            iNode = 100*Fi+10*Axis+01;
            jNode = 400000+1000*Fi+100*Axis+01;
            SpringID=900000+Fi*1000+Axis*100+01;

            if ColElementOption==1
                if isempty(strfind(SectionC, 'W'))==0
                    fprintf(INP,'Spring_Column_WideFlange %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %d; ', SpringID,iNode,jNode,SecData.Ix(idx),SecData.d(idx), SecData.h_tw(idx), SecData.bf_tf(idx),SecData.ry(idx),L_Col,Ls_Col,Lb_Col,My_mod,PgPy,Units);
                elseif isempty(strfind(SectionC, 'HSS'))==0
                    fprintf(INP,'Spring_Column_HSS %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f; ', SpringID,iNode,jNode,SecDataC.Ix(idx), SecDataC.h_t(idx),L_Col,My_mod,PgPy);
                end
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID,iNode,jNode);
            end

        end

    elseif Fi==NStory+1  && NStory~=1

        for Axis=1:NBay+1
            Bay=max(1,Axis-1);

            Section=MF_COLUMNS{Si,Axis};
            SectionC=Section;
            [SecDataC]=Load_SecData (Section, Units);
            idx=min(find(contains(SecDataC.Name,Section)));

            Section=MF_BEAMS{Fi-1,Bay};
            [SecDataB1]=Load_SecData (Section, Units);
            idxB1=min(find(contains(SecDataB1.Name,Section)));

            Section=MF_BEAMS{Fi-2,Bay};
            [SecDataB2]=Load_SecData (Section, Units);
            idxB2=min(find(contains(SecDataB2.Name,Section)));

            L_Col  = HStory(Si) - 0.5*SecDataB1.d(idxB1) - 0.5*SecDataB2.d(idxB2);
            Ls_Col = L_Col*0.5;
            Lb_Col = L_Col;
            My_mod = 1.1 * SecDataC.Zx(idx) * fy;

            Py   = SecDataC.Area(idx) * fy;
            Py_Col(Si,Axis)   = SecDataC.Area(idx) * fy;
            PgPy = Pred(Si,Axis)/Py;

            iNode = 100*Fi+10*Axis+01;
            jNode = 400000+1000*Fi+100*Axis+01;
            SpringID=900000+Fi*1000+Axis*100+01;

            if ColElementOption==1
                if isempty(strfind(SectionC, 'W'))==0
                    fprintf(INP,'Spring_Column_WideFlange %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %d; ', SpringID,iNode,jNode,SecDataC.Ix(idx),SecDataC.d(idx), SecDataC.h_tw(idx), SecDataC.bf_tf(idx),SecDataC.ry(idx),L_Col,Ls_Col,Lb_Col,My_mod,PgPy, Units);
                elseif isempty(strfind(SectionC, 'HSS'))==0
                    fprintf(INP,'Spring_Column_HSS %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f; ', SpringID,iNode,jNode,SecDataC.Ix(idx), SecDataC.h_t(idx),L_Col,My_mod,PgPy);
                end
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID,iNode,jNode);
            end

        end

    elseif Fi==NStory+1 && NStory==1

        for Axis=1:NBay+1
            Bay=max(1,Axis-1);

            Section=MF_COLUMNS{Si,Axis};
            SectionC=Section;
            [SecDataC]=Load_SecData (Section, Units);
            idx=min(find(contains(SecDataC.Name,Section)));

            Section=MF_BEAMS{Fi-1,Bay};
            [SecDataB1]=Load_SecData (Section, Units);
            idxB1=min(find(contains(SecDataB1.Name,Section)));

            L_Col  =  HStory(Si) - 0.5*SecDataB1.d(idxB1) - 0.5*SecDataB1.d(idxB1);
            Ls_Col  = L_Col*0.5;
            Lb_Col =  L_Col;

            My_mod = 1.1 * SecDataC.Zx(idx) * fy;
            Py   = SecDataC.Area(idx) * fy;
            Py_Col(Si,Axis)   = SecDataC.Area(idx) * fy;
            PgPy = Pred(Si,Axis)/Py;

            iNode = 100*Fi+10*Axis+01;
            jNode = 400000+1000*Fi+100*Axis+01;
            SpringID=900000+Fi*1000+Axis*100+01;

            if ColElementOption==1
                if isempty(strfind(SectionC, 'W'))==0
                    fprintf(INP,'Spring_Column_WideFlange %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %d; ', SpringID,iNode,jNode,SecDataC.Ix(idx),SecDataC.d(idx), SecDataC.h_tw(idx), SecDataC.bf_tf(idx),SecDataC.ry(idx),L_Col,Ls_Col,Lb_Col,My_mod,PgPy, Units);
                elseif isempty(strfind(SectionC, 'HSS'))==0
                    fprintf(INP,'Spring_Column_HSS %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f; ', SpringID,iNode,jNode,SecDataC.Ix(idx), SecDataC.h_t(idx),L_Col,My_mod,PgPy);
                end
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID,iNode,jNode);
            end

        end

    elseif Fi==1

        for Axis=1:NBay+1
            Bay=max(1,Axis-1);

            Section=MF_COLUMNS{Si,Axis};
            SectionC=Section;
            [SecDataC]=Load_SecData (Section, Units);
            idx=min(find(contains(SecDataC.Name,Section)));

            Section=MF_BEAMS{Fi,Bay};
            [SecDataB1]=Load_SecData (Section, Units);
            idxB1=min(find(contains(SecDataB1.Name,Section)));

            L_Col  =  HStory(Si) - 0.5*SecDataB1.d(idxB1);
            Ls_Col =  L_Col*0.5;
            Lb_Col =  L_Col;

            My_mod = 1.1 * SecDataC.Zx(idx) * fy;
            Py   = SecDataC.Area(idx) * fy;
            Py_Col(Si,Axis)   = SecDataC.Area(idx) * fy;
            PgPy = Pred(Si,Axis)/Py;

            iNode = (10*Fi+Axis)*10;
            jNode = 100*Fi+10*Axis+03;
            SpringID=900000+Fi*1000+Axis*100+03;

            if ColElementOption==1
                if isempty(strfind(SectionC, 'W'))==0
                    fprintf(INP,'Spring_Column_WideFlange %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %d; ', SpringID,iNode,jNode,SecDataC.Ix(idx),SecDataC.d(idx), SecDataC.h_tw(idx), SecDataC.bf_tf(idx),SecDataC.ry(idx),L_Col,Ls_Col,Lb_Col,My_mod,PgPy, Units);
                elseif isempty(strfind(SectionC, 'HSS'))==0
                    fprintf(INP,'Spring_Column_HSS %7d %7d %7d $E $fy %.4f %.4f %.4f %.4f %.4f; ', SpringID,iNode,jNode,SecDataC.Ix(idx), SecDataC.h_t(idx),L_Col,My_mod,PgPy);
                end
            else
                fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID,iNode,jNode);
            end

        end
    end

    fprintf(INP,'\n');
end
fprintf(INP,'\n');