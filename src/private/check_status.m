folder=fileparts(mfilename('fullpath')); addpath(folder); cd(folder);
diary('validation_matlab.txt');
f='test_status.txt';
cases={
 'COMPLETED','DYNAMIC',1,1,0,'id',true;
 'COLLAPSE','DYNAMIC',0.2,1,0,'id',true;
 'COMPLETED','STATIC',0.53,0.53,0,'id',true;
 'COMPLETED','EIGEN',2,2,0,'id',true;
 'COMPLETED','DYNAMIC',0.4,1,0,'id',false;
 'FAILED','GRAVITY',0,0,0,'id',false;
 'STARTED','DYNAMIC',0,0,0,'id',false;
 'COMPLETED','DYNAMIC',1,1,1,'id',false;
 'COMPLETED','DYNAMIC',1,1,0,'old-id',false;
 'COMPLETED','DYNAMIC',NaN,1,0,'id',false;
 'COLLAPSE','STATIC',0.2,1,0,'id',false;
};
for k=1:size(cases,1)
    fid=fopen(f,'w');
    fprintf(fid,'%s\n%s\n%s\n%.12g\n%.12g\n%s\n',cases{k,6},cases{k,1},cases{k,2},cases{k,3},cases{k,4},'Test result');
    fclose(fid);
    accepted=true;
    try, read_RunResult(f,'id',cases{k,5}); catch ME, accepted=false; end
    assert(accepted==cases{k,7});
    fprintf('PASS case %d: state=%s stage=%s accepted=%d\n',k,cases{k,1},cases{k,2},accepted);
end
accepted=true;
try, read_RunResult('nonexistent_status_file.txt','id',0); catch ME, accepted=false; end
assert(~accepted); fprintf('PASS missing status rejected\n');
fprintf('ALL STATUS VALIDATION CHECKS PASSED\n'); diary off;
