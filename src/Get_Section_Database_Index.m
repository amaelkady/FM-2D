function [Column_Index, Beam_Index, Brace_Index, XSecID] = Get_Section_Database_Index(FrameType, NStory, NBay, MF_COLUMNS, MF_BEAMS, BRACES, Units)

XSecID.X=NaN;

for Story=1:NStory
    for Axis=1:NBay+1
        Section=MF_COLUMNS{Story,Axis};
        [SecData]=Load_SecData (Section, Units);
        idx=find(contains(SecData.Name,Section));
        Column_Index(Story,Axis)=idx;
        if isempty(strfind(Section, 'W'))==0
            XSecID.Column=1;	
        elseif isempty(strfind(Section, 'HSS'))==0
            XSecID.Column=2;	
        elseif isempty(strfind(Section, 'IP'))==0 || isempty(strfind(Section, 'HE'))==0 isempty(strfind(Section, 'HE'))==0
            XSecID.Column=3;	
        end
    end
end


for Floor=2:NStory+1
    for Bay=1:NBay
        Section=MF_BEAMS{Floor-1,Bay};
        [SecData]=Load_SecData (Section, Units);
        idx=find(contains(SecData.Name,Section));
        Beam_Index(Floor-1,Bay)=idx;
        if isempty(strfind(Section, 'W'))==0
            XSecID.Beam=1;	
        elseif isempty(strfind(Section, 'HSS'))==0
            XSecID.Beam=2;	
        elseif isempty(strfind(Section, 'IP'))==0 || isempty(strfind(Section, 'HE'))==0 isempty(strfind(Section, 'HE'))==0
            XSecID.Beam=3;	
        end
    end
end

if FrameType~=1
    for Story=1:NStory
        for Bay=1:NBay
            Section=BRACES{Story,Bay};
            [SecData]=Load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section));
            Brace_Index(Story,Bay)=idx;
            if isempty(strfind(Section, 'W'))==0
                XSecID.Brace=1;	
            elseif isempty(strfind(Section, 'HSS'))==0
                XSecID.Brace=2;	
            elseif isempty(strfind(Section, 'IP'))==0 || isempty(strfind(Section, 'HE'))==0 isempty(strfind(Section, 'HE'))==0
                XSecID.Brace=3;	
            end
        end
    end
else
    Brace_Index=0;
end
