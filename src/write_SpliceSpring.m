function write_SpliceSpring (INP)

global MainDirectory
load(strcat(MainDirectory,'\temp_unpacked'), 'NStory', 'NBay', 'Splice', 'SpliceConnection');

[~, ~, Pnode] = get_Weight_and_Mass();

if any(Splice(:) == 1)
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                          COLUMN SPLICE SPRINGS                                  #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');
end
    
MatID = 10;

for Si=NStory:-1:1
    if Splice(Si, 1)==1
        for Axis=1:NBay+3
            
            iNode = 100000+1000*Si+100*Axis+71;
            jNode = 100000+1000*Si+100*Axis+72;
            SpringID=900000+Si*1000+Axis*100+07;

            if SpliceConnection==1
                fprintf(INP,'Spring_Zero %d %d %d; ', SpringID,iNode,jNode);
            else
           
                % if Axis <= NBay+1; Section = MF_COLUMNS{Si+1,Axis}; else; Section = GF_COLUMNS{Si+1,1}; end
                % [SecDataC]=load_SecData (Section, Units);
                % idx=find(contains(SecData.Name,Section),1,'first');
                % 
                % Mpe  = 1.1*SecDataC.Zx(idx) * fy;
                % Py   =     SecDataC.Area(idx) * fy;
                % PgPy = sum(Pnode(Si+1:end,Axis))/Py;
                % Mpe  = Mpe * (1-PgPy);
                % MatID= MatID+1;

                % fprintf(INP,'Spring_Splice %d %d %d; ', SpringID, MatID, iNode,jNode, Mpe);

                fprintf(INP,'Spring_Rigid %d %d %d; ', SpringID,iNode,jNode);
            end
            
            fprintf(INP,'\n');
        end
    end
end
fprintf(INP,'\n');
