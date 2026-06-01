function [Column_Index, Beam_Index, Brace_Index, XSecID] = get_Section_Database_Index()

global  ProjectName ProjectPath
load(strcat(ProjectPath,ProjectName));

v2struct(PROJECT);
v2struct(LAYOUT);
v2struct(PROPERTY);

XSecID.X=NaN;

for Story=1:NStory
    for Axis=1:NBay+1
        Section=MF_COLUMNS{Story,Axis};
        [SecData]=load_SecData (Section, Units);
        idx=find(contains(SecData.Name,Section),1,"first");
  
        Column_Index(Story,Axis)=idx;

        if ~contains(Section, 'W')==0 || ~contains(Section, 'BU')==0
            XSecID.Column=1;	
        elseif ~contains(Section, 'HSS')==0
            XSecID.Column=2;	
        elseif ~contains(Section, 'IP')==0 || ~contains(Section, 'HE')==0 
            XSecID.Column=3;	
        end
    end
end


for Floor=2:NStory+1
    for Bay=1:NBay
        
        Section=MF_BEAMS{Floor-1,Bay};
        [SecData]=load_SecData (Section, Units);
        idx=find(contains(SecData.Name,Section),1,"first");

        Beam_Index(Floor-1,Bay)=idx;

        if ~contains(Section, 'W')==0 || ~contains(Section, 'BU')==0
            XSecID.Beam=1;	
        elseif ~contains(Section, 'HSS')==0
            XSecID.Beam=2;	
        elseif ~contains(Section, 'IP')==0 || ~contains(Section, 'HE')==0
            XSecID.Beam=3;	
        end
    end
end

if FrameType~=1
    for Story=1:NStory
        for Bay=1:NBay

            Section=BRACES{Story,Bay};
            [SecData]=load_SecData (Section, Units);
            idx=find(contains(SecData.Name,Section),1,"first");

            Brace_Index(Story,Bay)=idx;

            if ~contains(Section, 'W')==0 || ~contains(Section, 'BU')==0
                XSecID.Brace=1;	
            elseif ~contains(Section, 'HSS')==0
                XSecID.Brace=2;	
            elseif ~contains(Section, 'IP')==0 || ~contains(Section, 'HE')==0
                XSecID.Brace=3;	
            end
        end
    end
else
    Brace_Index=0;
end
