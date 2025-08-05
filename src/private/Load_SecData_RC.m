function [SecData]=Load_SecData_RC (Section)

% For rectangular sections:
%  H x B x coverH x coverB x nBarTop x dBarTop x nBarBot x dBarBot x nBarInt x dBarInt x nBarShear x dBarShear x s

% For circular sections:
%  D x cover x nBar x dBar x nBarShear x dBarShear x s

count=1;
last=1;
SecData.Data=zeros(1,13);
Section=string(Section);
for i=1:strlength(Section)
    if Section{1}(i)=="x"
        SecData.Data(1,count)=str2double(Section{1}(last:i-1));
        last=i+1;
        count=count+1;
    end
end
SecData.Data(1,count)=str2double(Section{1}(last:end));

if count==13  % rectangular section
    SecData.H           = SecData.Data(1,1);
    SecData.B           = SecData.Data(1,2);
    SecData.coverH      = SecData.Data(1,3);
    SecData.coverB      = SecData.Data(1,4);
    SecData.nBarTop     = SecData.Data(1,5);
    SecData.dBarTop     = SecData.Data(1,6);
    SecData.nBarBot     = SecData.Data(1,7);
    SecData.dBarBot     = SecData.Data(1,8);
    SecData.nBarInt     = SecData.Data(1,9);
    SecData.dBarInt     = SecData.Data(1,10);
    SecData.nBarShear   = SecData.Data(1,11);
    SecData.dBarShear   = SecData.Data(1,12);
    SecData.s           = SecData.Data(1,13);

    SecData.areaBarTop   = SecData.nBarTop   * pi()*SecData.dBarTop^2/4;
    SecData.areaBarBot   = SecData.nBarBot   * pi()*SecData.dBarBot^2/4;
    SecData.areaBarInt   = SecData.nBarInt   * pi()*SecData.dBarInt^2/4;
    SecData.areaBarShear = SecData.nBarShear * pi()*SecData.dBarShear^2/4;

    SecData.rho_Top   = SecData.areaBarTop   / (SecData.B * (SecData.H-SecData.coverH));
    SecData.rho_Bot   = SecData.areaBarBot   / (SecData.B * (SecData.H-SecData.coverH));
    SecData.rho_Int   = SecData.areaBarInt   / (SecData.B * (SecData.H-SecData.coverH));
    SecData.rho_Shear = SecData.areaBarShear / (SecData.B *  SecData.s);
    
else  % circular section
    SecData.D           = SecData.Data(1,1);
    SecData.cover       = SecData.Data(1,2);
    SecData.nBar        = SecData.Data(1,3);
    SecData.dBar        = SecData.Data(1,4);
    SecData.nBarShear   = SecData.Data(1,5);
    SecData.dBarShear   = SecData.Data(1,6);
    SecData.s           = SecData.Data(1,7);

    SecData.areaBar      = SecData.nBar      * pi()*SecData.dBar^2/4;
    SecData.areaBarShear = SecData.nBarShear * pi()*SecData.dBarShear^2/4;

    SecData.rho_Top   = SecData.areaBar      / (pi()* SecData.D * (SecData.D-SecData.cover) / 4);
    SecData.rho_Shear = SecData.areaBarShear / (SecData.D *  SecData.s);    
end


