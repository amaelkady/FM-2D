function write_Error(ME)
global MainDirectory ProjectPath

cd (ProjectPath)

xx={ME.stack.line};
fid = fopen('Error log.txt', 'wt');
fprintf(fid, 'Error Identifier:   %s\n', ME.identifier);
fprintf(fid, 'Error Message:      %s\n', ME.message);
fprintf(fid, '--------------------------------------------------\n');
fprintf(fid, 'Error Location:\n');
fprintf(fid, '----------------\n');
for i=1:size(xx,2)-2
    fprintf(fid, 'Line %4d in %s\n', xx{1,i}, ME.stack(i).name);
end
fclose(fid);

cd (MainDirectory)
