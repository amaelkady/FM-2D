function write_EGFsprings_FiberFrame (INP,NStory,NBay,GFX)

fprintf(INP,'# GRAVITY BEAMS SPRINGS\n');
for Floor=NStory+1:-1:2
    SpringID_R=900000+Floor*1000+(NBay+2)*100+04;
    SpringID_L=900000+Floor*1000+(NBay+3)*100+02;
    if GFX==0
        nodeID0=(10*Floor+(NBay+2))*10;
        nodeID1=100*Floor+10*(NBay+2)+04;
        fprintf(INP,'Spring_Zero %7d %7d %7d; ', SpringID_R,nodeID0,nodeID1);
        nodeID0=(10*Floor+(NBay+3))*10;
        nodeID1=100*Floor+10*(NBay+3)+02;
        fprintf(INP,'Spring_Zero %7d %7d %7d; ', SpringID_L,nodeID0,nodeID1);
    else
        nodeID0=(10*Floor+(NBay+2))*10;
        nodeID1=100*Floor+10*(NBay+2)+04;
        fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID_R,nodeID0,nodeID1);
        nodeID0=(10*Floor+(NBay+3))*10;
        nodeID1=100*Floor+10*(NBay+3)+02;
        fprintf(INP,'Spring_Rigid %7d %7d %7d; ', SpringID_L,nodeID0,nodeID1);
    end
    fprintf(INP,'\n');
end
fprintf(INP,'\n');