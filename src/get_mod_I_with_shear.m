function factor_I_mod = get_mod_I_with_shear (MemberType, Bay, Story, SecData, idx)

global ProjectName ProjectPath
load(strcat(ProjectPath,ProjectName),'Kshearstatus','Support','E','HStory','WBay')

if Kshearstatus==1

    G            = E/2/(1+0.3);

    if MemberType=="Column"
        if Story==1 && Support==1; K_flexure    = 3*E*SecData.Ix(idx)/HStory(Story)*0.5; end
        if Story==1 && Support~=1; K_flexure    = 3*E*SecData.Ix(idx)/HStory(Story)*1.0; end
        if Story~=1;               K_flexure    = 3*E*SecData.Ix(idx)/HStory(Story)*0.5;  end

        K_shear      = G*SecData.Area(idx)*HStory(Story)/(0.85+2.32*SecData.bf(idx)*SecData.tf(idx)/SecData.d(idx)/SecData.tw(idx));
    
    elseif MemberType=="Beam"
    
        K_flexure    = 3*E*SecData.Ix(idx)/WBay(Bay)*0.5;
        K_shear      = G*SecData.Area(idx)*WBay(Bay)/(0.85+2.32*SecData.bf(idx)*SecData.tf(idx)/SecData.d(idx)/SecData.tw(idx));

    end


    factor_I_mod = (K_shear/(K_shear+K_flexure));

else

    factor_I_mod = 1.0;

end