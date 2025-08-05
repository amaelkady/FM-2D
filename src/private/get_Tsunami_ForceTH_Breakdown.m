%
% INPUT
%----------------------
%
% NStory        number of stories
% HStory        story heights [m]
% Elevation     floor elevations [m]
% F             total tsunami force history [kN]
% Hinundation   inundation depth history [m]
%
% OUTPUT
%----------------------
%
% Floor_F       floor tsunami force history [kN]
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Floor_F]=get_Tsunami_ForceTH_Breakdown(NStory, HStory, Elevation, F, Hinundation, Units)


if Units ==1
    Hinundation    = Hinundation*1000;
end

for Floor=1:NStory+1

    StoryU=Floor; 
    StoryL=Floor-1;

    if Floor~=NStory+1
        ElevationU = Elevation(Floor)+HStory(StoryU)*0.5;
    else
        ElevationU = Elevation(Floor);
    end

    if Floor==1
        ElevationL = 0;
    else
        ElevationL = Elevation(Floor)-HStory(StoryL)*0.5;
    end


    if Floor==1
        tributary_height=HStory(StoryU)/2;
    elseif Floor==NStory+1
        tributary_height=HStory(StoryL)/2;
    else
        tributary_height=mean(HStory(StoryU),HStory(StoryL));
    end

    AmpU = max(0, (Hinundation-ElevationU)./Hinundation);
    AmpL = max(0, (Hinundation-ElevationL)./Hinundation);

    Floor_F_Weight(Floor,:) = (min(tributary_height,Hinundation).* (AmpU+AmpL)./2 ./(0.5*Hinundation.*1.0))';

end

for Floor=1:NStory+1

    Floor_F(Floor,:) = F.* Floor_F_Weight(Floor,:)';

end