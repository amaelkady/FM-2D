function [Eigen_Vector]=get_Eigen_Vector(i)
clc

global MainDirectory ProjectName ProjectPath
load (strcat(ProjectPath,ProjectName),'RFpath')

%% Go inside the results folder and read results
cd(strcat(RFpath,'\Results\EigenAnalysis'));

%% Read Eigen Vector Data
evalc(strcat('x=importdata(','''','EigenVectorsMode',num2str(i),'.out','''',')'));
Eigen_Vector=[0 x(1,:)./max(abs(x(1,:)))]';

cd(MainDirectory)