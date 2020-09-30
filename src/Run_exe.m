function [RunTime]=Run_exe(OpenSEESFileName,ShowOpenseesStatus)

if ShowOpenseesStatus==1  
	eval(strcat('! OpenSees.exe ', OpenSEESFileName));
else
	[status, screenOutfile] = dos([['OpenSees.exe ', num2str(OpenSEESFileName)]]);
end

RunTime=toc;