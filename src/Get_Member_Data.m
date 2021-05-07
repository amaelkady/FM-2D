function [Column_Data, Beam_Data, Brace_Data]=Get_Member_Data(NStory, NBay, FrameType, MF_COLUMNS, MF_BEAMS, BRACES, Units, fy)

a=0; b=0; c=0;

for Story=1:NStory
    for Axis=1:NBay+1
        Section=MF_COLUMNS{Story,Axis};
        [SecData]=Load_SecData (Section, Units);
        idx=find(contains(SecData.Name,Section));
        Column_Data.d(Story,Axis)=SecData.d(idx);
    end
end

for Floor=2:NStory+1
    for Bay=1:NBay
        Section=MF_BEAMS{Floor-1,Bay};
        [SecData]=Load_SecData (Section, Units);
        idx=find(contains(SecData.Name,Section));
        Beam_Data.d(Floor,Bay)=SecData.d(idx);
        Beam_Data.bf(Floor,Bay)=SecData.bf(idx);
        Beam_Data.LRBS(Floor,Bay)   = a *  SecData.bf(idx)+ b * SecData.d(idx)/2;
    end
end

if FrameType~=1
    for Storyi=1:NStory
        for Bayi=1:NBay
            Section=BRACES{Storyi,Bayi};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            Brace_Data.Py(Storyi,Bayi)=SecData.Area(idx)*fy;
        end
    end
else
    Brace_Data.Py=zeros(NStory,NBay);
end
