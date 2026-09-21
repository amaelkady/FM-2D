function [SecData] = load_PRConnParams(Section,ConnectionID)

% For extended endplate connections
% tep x bep x d_b x pt x g x nrows x StiffenerC {x BP X tbp x DP X tdp}  

% For flush endplate connections
% tep x d_b x dt x g x nrows x StiffenerC {x BP X tbp x DP X tdp}

% For single-sided extended endplate connections
% tep x d_b x pt x dt x g x nrows x StiffenerC {x BP X tbp x DP X tdp} 

count=1;
last=1;
SecData.Data=zeros(1,11);
Section=string(Section);
for i=1:strlength(Section)
    if Section{1}(i)=="x"
        SecData.Data(1,count)=str2double(Section{1}(last:i-1));
        last=i+1;
        count=count+1;
    end
end
SecData.Data(1,count)=str2double(Section{1}(last:end));

SecData.BP          = 0;
SecData.tbp         = 0;
SecData.DP          = 0;
SecData.tdp         = 0;

if ConnectionID==1 % extended endplate

    if count==7 || count==11
        SecData.tep         = SecData.Data(1,1);
        SecData.bep         = SecData.Data(1,2);
        SecData.d_b         = SecData.Data(1,3);
        SecData.pt          = SecData.Data(1,4);
        SecData.g           = SecData.Data(1,5);
        SecData.nrows       = SecData.Data(1,6);
        SecData.StiffenerC  = SecData.Data(1,7);
        SecData.dt          = 0;
    else
        errordlg('Number of input EEPC data are incorrect. Check Excel file!','Error');
        return;
    end
    if count==10
        SecData.BP          = SecData.Data(1,7);
        SecData.tbp         = SecData.Data(1,8);
        SecData.DP          = SecData.Data(1,9);
        SecData.tdp         = SecData.Data(1,10);
    end


elseif ConnectionID==2 % header endplate

elseif ConnectionID==3 % flush endplate

    if count==6  || count==10
        SecData.tep         = SecData.Data(1,1);
        SecData.d_b         = SecData.Data(1,2);
        SecData.dt          = SecData.Data(1,3);
        SecData.g           = SecData.Data(1,4);
        SecData.nrows       = SecData.Data(1,5);
        SecData.StiffenerC  = SecData.Data(1,6);
        SecData.pt          = 0;
    else
        errordlg('Number of input GF Connection data are incorrect. Check Excel file!','Error');
        return;
    end
    if count==10
        SecData.BP          = SecData.Data(1,7);
        SecData.tbp         = SecData.Data(1,8);
        SecData.DP          = SecData.Data(1,9);
        SecData.tdp         = SecData.Data(1,10);
    end

elseif ConnectionID==4 % extended endplate single-sided

    if count==7  || count==11
        SecData.tep         = SecData.Data(1,1);
        SecData.d_b         = SecData.Data(1,2);
        SecData.pt          = SecData.Data(1,3);
        SecData.dt          = SecData.Data(1,4);
        SecData.g           = SecData.Data(1,5);
        SecData.nrows       = SecData.Data(1,6);
        SecData.StiffenerC  = SecData.Data(1,7);
    else
        errordlg('Number of input GF Connection data are incorrect. Check Excel file!','Error');
        return;
    end
    if count==11
        SecData.BP          = SecData.Data(1,8);
        SecData.tbp         = SecData.Data(1,9);
        SecData.DP          = SecData.Data(1,10);
        SecData.tdp         = SecData.Data(1,11);
    end

end
