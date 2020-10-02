function Process_EigenAnalysis ()
global MainDirectory ProjectName ProjectPath
clc
cd (ProjectPath);
load (ProjectName);
cd(MainDirectory);

cd (RFpath);
cd ('Results');
cd ('EigenAnalysis');

% Read the Mode Shapes
for i=1:NStory
    FileX=sprintf('EigenVectorsMode%d.out', i);
    ModeShapei=importdata(FileX);
    for j=1:NStory
        ModalShape(j,i)=ModeShapei(1,j);
    end
end
fclose all;

% Normalize the Mode Shapes with Respect to the Roof displacement of Each Mode
for i=1:NStory
    for j=1:NStory
        ModeShape(j,i)=ModalShape(j,i)/ModalShape(NStory,i);
    end
end

for i=1:NStory
    for j=1:NStory
        TemporySn(j,i)=MassMatrix(j,1)*ModeShape(j,i);
        Mn(j,i) = MassMatrix(j,1)*ModeShape(j,i)^2;
        Ln(j,i) = MassMatrix(j,1)*ModeShape(j,i);
    end
    for j=1:NStory
        Sn(j,i) = TemporySn(j,i)/TemporySn(NStory,i);
    end
    LoadPattern(i,1) = Sn(i,1);
    SumMn(i) = sum(Mn(:, i));
    SumLn(i) = sum(Ln(:, i));
    Gamma(i) =SumLn(i)/SumMn(i);
    EffectiveModalMass(i) = Gamma(i)*SumLn(i);
end

for i=1:NStory
    ModalMassParticipation(i) = EffectiveModalMass(i)/sum(EffectiveModalMass);
    Cumulative(i) = sum(ModalMassParticipation(1,1:i));
    Cumulative(i) >= 0.9;
end


FileX=sprintf('EigenValues.out');
EigenValue=fopen(FileX,'w');
fprintf(EigenValue,' ************************************************\n');
fprintf(EigenValue,' EIGEN ANALYSIS RESULTS\n');
fprintf(EigenValue,' ************************************************\n');
fprintf(EigenValue,' PROBLEM NAME  = %dSCBF\n', NStory);
fprintf(EigenValue,' \n');
fprintf(EigenValue,' *----------------------\n');
fprintf(EigenValue,' MODE SHAPES AND PERIODS\n');
fprintf(EigenValue,' *----------------------\n');
fprintf(EigenValue,' \n');
fprintf(EigenValue,' PERIODS\n');
fprintf(EigenValue,' \n');
fprintf(EigenValue,' Mode No.');
for i=1:NStory
    fprintf(EigenValue,'           %d', i);
end
fprintf(EigenValue,'\n Period  ');
Temp=sprintf('EigenPeriod.out');
ReadData=fopen(Temp,'r');
for i=1:NStory
%     TempFreq=fscanf(ReadData, '%s',[1,1]);
%     Freq=str2num(TempFreq);
%     ModePeriod(i)=2*pi/sqrt(Freq);
    TempT=fscanf(ReadData, '%s',[1,1]);
    Treq=str2num(TempT);
    ModePeriod(i)=Treq;
    fprintf(EigenValue,'   %9.7f', ModePeriod(i));
end
fprintf(EigenValue,' \n');
fprintf(EigenValue,'\n MODAL PARTICIPATION FACTORS\n');
fprintf(EigenValue,' \n');
fprintf(EigenValue,' Mode        X-Motion    Y-Motion\n');
for i=1:NStory
    fprintf(EigenValue,'%5d        %f  0.00000000\n', i, Gamma(i));
end
fprintf(EigenValue,' \n');
fprintf(EigenValue,'\n EFFECTIVE MODAL MASS AS A FRACTION OF TOTAL MASS\n');
fprintf(EigenValue,' \n');
fprintf(EigenValue,' Mode        X-Motion    Y-Motion\n');
for i=1:NStory
    fprintf(EigenValue,'%5d        %f  0.00000000\n', i, ModalMassParticipation(i));
end
fprintf(EigenValue,' \n');
fprintf(EigenValue,' TOTAL =     %8f  0.00000000\n', Cumulative(NStory));
fprintf(EigenValue,' \n');
for i=1:NStory
    fprintf(EigenValue,' *--------------------------------*\n');
    fprintf(EigenValue,' MODE SHAPE    %d PERIOD  %9.7f\n', i, ModePeriod(i));
    fprintf(EigenValue,' *--------------------------------*\n');
    fprintf(EigenValue,' Node          X-Tran\n');
    fprintf(EigenValue,' \n');
    for j=1:NStory
        Node=100000+1000*(j+1)+105;
        fprintf(EigenValue,'%7d     %9.5f\n', Node, ModalShape(j,i));
    end
    fprintf(EigenValue,' \n');
end
fclose(EigenValue);
Temporary = fopen('Unnecessary.bat','w');
for i=1:NStory
    fprintf(Temporary,'del Mode%dXmodeNumber.out\n', i);
end
fclose(Temporary);
fclose all;

% delete the Mode Shapes
for i=1:NStory
    FileX=sprintf('EigenVectorsMode%d.out', i);
    evalc(sprintf(['delete ',FileX]));
end

delete 'EigenPeriod.out';

cd(MainDirectory)
