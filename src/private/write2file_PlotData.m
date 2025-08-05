function write2file_PlotData(SavePath, TextFilename,Xdata,Ydata)
global MainDirectory

cd (SavePath)
fileX = fopen(TextFilename,'wt');

fprintf(fileX,'%s\t%s\t\n','X-data    ','Y-data   ');
fprintf(fileX,'%s\n','-------------------------------------------------------------------------------------------------');

if size(Xdata,2)==1
    for i=1:size(Xdata,1)
        fprintf(fileX,'%f\t%f\t\n',  Xdata(i,1), Ydata(i,1));
    end
else
    for i=1:size(Xdata,1)
        for j=1:size(Xdata,2)
            fprintf(fileX,'%f\t',  Xdata(i,j));
        end
        fprintf(fileX,'%f\t\n',  Ydata(i,1));
    end
end
fclose(fileX);
cd (MainDirectory)
end