function write_Animation(INP,AnimSF,AnimX,AnimY)

fprintf(INP,'if {$ShowAnimation == 1} {\n');
fprintf(INP,'	DisplayModel3D DeformedShape %.2f 100 100  %d %d;\n',AnimSF,AnimX,AnimY);
fprintf(INP,'}\n');
fprintf(INP,'\n');