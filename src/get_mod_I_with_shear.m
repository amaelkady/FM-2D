function factor_I_mod = get_mod_I_with_shear (MemberType, Bay, Story, SecData, idx)

global ProjectName ProjectPath
load(strcat(ProjectPath,ProjectName),'Kshearstatus','Support','E','HStory','WBay')

if Kshearstatus==1

    G = E/2/(1+0.3);

    if MemberType=="Column"

        Lcolumn = HStory(Story);

        if     Story==1 && Support==1; K_flexure    = 3*E*SecData.Ix(idx)/Lcolumn*0.5; 
        elseif Story==1 && Support~=1; K_flexure    = 3*E*SecData.Ix(idx)/Lcolumn*1.0; 
        elseif Story~=1;               K_flexure    = 3*E*SecData.Ix(idx)/Lcolumn*0.5; end

        K_shear      = G*SecData.Area(idx)*Lcolumn/(0.85+2.32*SecData.bf(idx)*SecData.tf(idx)/SecData.d(idx)/SecData.tw(idx));
    
    elseif MemberType=="Beam"
    
        Lbeam = WBay(Bay);

        K_flexure    = 3*E*SecData.Ix(idx)/Lbeam*0.5;
        K_shear      = G*SecData.Area(idx)*Lbeam/(0.85+2.32*SecData.bf(idx)*SecData.tf(idx)/SecData.d(idx)/SecData.tw(idx));

    end

    factor_I_mod = (K_shear/(K_shear+K_flexure));

else

    factor_I_mod = 1.0;

end