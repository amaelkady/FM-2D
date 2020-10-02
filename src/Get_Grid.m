function [GridX, GridY, AXIS, Elevation, HalfElevation, XTickLabel, YTickLabel] = Get_Grid (NStory, NBay,HStory,WBay)

% Calculation of Axis Location
for Axis=2:NBay+1
    GridX(Axis)=sum(WBay(1:Axis-1));
end
GridX(end+1)=GridX(end)+0.5*WBay(1); % 1st EGF Column Axis
GridX(end+1)=GridX(end)+1.0*WBay(1); % 2nd EGF Column Axis
AXIS = GridX;

for i=1:NBay+3
    evalc(strcat('XTickLabel {i}=',num2str(i)));
end

% Calculation of Floor Elevations
for Floor=2:NStory+1
    GridY(Floor)=sum(HStory(1:Floor-1));
end
Elevation =GridY;

for i=1:NStory
    evalc(strcat('YTickLabel {i}=',num2str(i)));
end
YTickLabel{end+1}='Roof';
YTickLabel{1}='Ground';

% Calculation of Mid-Story Elevations
HalfElevation(1)=HStory(1)*0.5;
for Story=2:NStory
    HalfElevation(Story)=sum(HStory(1:Story-1))+HStory(Story)*0.5;
end
