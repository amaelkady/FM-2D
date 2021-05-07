function write_SpliceSpring (INP, NStory, NBay, Splice, SpliceConnection)

if any(Splice(:) == 1)
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'#                                          COLUMN SPLICE SPRINGS                                  #\n');
fprintf(INP,'###################################################################################################\n');
fprintf(INP,'\n');
end
    
for Story=NStory:-1:1
    if Splice(Story, 1)==1
        for Axis=1:NBay+3
            iNode = 100000+1000*Story+100*Axis+71;
            jNode = 100000+1000*Story+100*Axis+72;
            SpringID=900000+Story*1000+Axis*100+07;
            if SpliceConnection==1
                fprintf(INP,'Spring_Zero %d %d %d; ', SpringID,iNode,jNode);
            else
                fprintf(INP,'Spring_Rigid %d %d %d; ', SpringID,iNode,jNode);
            end
            fprintf(INP,'\n');
        end
    end
end
fprintf(INP,'\n');