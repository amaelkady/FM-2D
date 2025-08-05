function create_video(filepath)

scale = 10;

global ProjectPath ProjectName
load(strcat(ProjectPath,ProjectName),'NStory','RESULTS');

dispfloor=zeros(size(RESULTS.Time,1),NStory+1);
for Fi = 2:NStory+1
    evalc(['fname=','''','Disp',num2str(Fi),'_MF','''']);
    dispfloor(:,Fi)=RESULTS.(char(fname));
end
dispfloor=dispfloor*scale;

v = VideoWriter(filepath);
open(v)

%Generate a set of frames, get each frame from the figure, and then write each frame to the file.

maxDisp=max(max(abs(dispfloor)));

step=max(1, round(size(dispfloor,1)/300));
for Ti = 1:step:size(dispfloor,1)
   [h]=plot_Frame_Deformed_fig(dispfloor(Ti,:),maxDisp);
   plot_PH_state_fig (Ti, dispfloor(Ti,:));
   frame = getframe(gcf);
   writeVideo(v,frame)
   close(h);
end

close (v)