function [SummaryText]=Get_Project_Summary
global MainDirectory ProjectPath ProjectName

clc
cd (ProjectPath);
load(ProjectName)
cd (MainDirectory);

if Units==1
    massUnit=' kN.sec2/mm';
    dispUnit=' mm';
    forceUnit=' kN';
    loadUnit=' kN/m2';
    matUnit=' kN/mm2';
    KUnit=' kN/mm';
    convUnit=1000*1000;
else
    massUnit=' kip.sec2/in';
    dispUnit=' in';
    forceUnit=' kip';
    loadUnit=' psf';
    matUnit=' ksi';
    KUnit=' kip/in';
    convUnit=1000*12*12;
end

if Modelstatus==1

    i=1;
    SummaryText{i}='******************************************************';i=i+1;
    SummaryText{i}='******************************************************';i=i+1;
    SummaryText{i}='                    PROJECT SUMMARY                   ';i=i+1;
    SummaryText{i}='******************************************************';i=i+1;
    SummaryText{i}='******************************************************';i=i+1;
    SummaryText{i}='';i=i+1;

    SummaryText{i}=['- Project Name:           ',ProjectName];i=i+1;
    SummaryText{i}=['- OpenSEES tcl File Name: ',OpenSEESFileName];i=i+1;
    SummaryText{i}=['- Project Folder Path:    ',ProjectPath];i=i+1;
    SummaryText{i}=['- Results Folder Path:    ',RFpath];i=i+1;
    if Definestatus==1; SummaryText{i}=['- EXCEL File Path:        ',ExcelFilePath,ExcelFileName];i=i+1; end
    if Units==1
        SummaryText{i}='- Units: SI, kN & mm';i=i+1;
    else
        SummaryText{i}='- Units: Imperial, kip & in';i=i+1;
    end
    
    SummaryText{i}='';i=i+1;
    SummaryText{i}='NUMERICAL MODEL DESCRIPTION';i=i+1;
    SummaryText{i}='------------------------------------------------------';i=i+1;
    if ModelELOption==1
        SummaryText{i}=['- Linear Elastic Model'];i=i+1;
    else
        SummaryText{i}=['- Nonlinear Model'];i=i+1;
    end
    if TransformationX==1
        SummaryText{i}=['- Geometric Transformation: Linear'];i=i+1;
    elseif TransformationX==2
        SummaryText{i}=['- Geometric Transformation: P-Delta'];i=i+1;
    elseif TransformationX==3
        SummaryText{i}=['- Geometric Transformation: Corotational'];i=i+1;
    end
    if CompositeX==1
        SummaryText{i}=['- Composite floor action is considered'];i=i+1;
    else
        SummaryText{i}=['- Composite floor action is ignored (i.e., Bare steel frame)'];i=i+1;
    end
    if GFX==1
        if Orientation==1; SummaryText{i}=['- Gravity framing system is considerd with weak-axis orientation with respect to the modeled direction.'];i=i+1; end
        if Orientation==2; SummaryText{i}=['- Gravity framing system is considerd with strong-axis orientation with respect to the modeled direction.'];i=i+1; end
    else
        SummaryText{i}=['- Gravity framing system is not considerd.'];i=i+1;
    end
    if PZ_Multiplier==1
        SummaryText{i}=['- Panel zone deformation is considered'];i=i+1;
    else
        SummaryText{i}=['- Panel zone deformation is ignored'];i=i+1;
    end
    if RigidFloor==1
        SummaryText{i}=['- Rigid floor diaphragm movement is considered'];i=i+1;
    else
        SummaryText{i}=['- Rigid floor diaphragm movement is ignored'];i=i+1;
    end
end

if Definestatus==1

        SummaryText{i}='';i=i+1;
        SummaryText{i}='BUILDING DATA';i=i+1;
        SummaryText{i}='------------------------------------------------------';i=i+1;
        SummaryText{i}=char(BuildingDescription);i=i+1;
        SummaryText{i}='';i=i+1;
        SummaryText{i}='------------------------------------------------------';i=i+1;
        if FrameType==1;                     SummaryText{i}=['- Frame Type                       : MRF'];i=i+1;           end
        if FrameType==2 &&  BraceLayout==1;  SummaryText{i}=['- Frame Type                       : CBF X-Bracing'];i=i+1; end
        if FrameType==2 &&  BraceLayout==2;  SummaryText{i}=['- Frame Type                       : CBF Chevron'];i=i+1;   end
        if FrameType==3;                     SummaryText{i}=['- Frame Type                       : EBF'];i=i+1;           end

        SummaryText{i}=['- No. of Stories                   : ', num2str(NStory)];i=i+1;
        SummaryText{i}=['- No. of Frames per Direction      : ', num2str(nMF)];i=i+1;
        SummaryText{i}=['- Floor Area                       : ', num2str(DIM1), dispUnit,' x ', num2str(DIM2), dispUnit];i=i+1;
        SummaryText{i}=['- Tributary Area of Interior Column: ', num2str(TAin1), dispUnit,' x ', num2str(TAin2), dispUnit];i=i+1;
        SummaryText{i}=['- Tributary Area of Exterior Column: ', num2str(TAex1), dispUnit,' x ', num2str(TAex2), dispUnit];i=i+1;
        if GFX==1
        SummaryText{i}=['- No. of Gravity Columns           : ', num2str(nGC*nMF)];i=i+1;
        SummaryText{i}=['- No. of Gravity Beams             : ', num2str(nGB*nMF)];i=i+1;
        end

        SummaryText{i}='';i=i+1;
        SummaryText{i}='LOADS';i=i+1;
        SummaryText{i}='------------------------------------------------------';i=i+1;
        SummaryText{i}=['- Dead Load, Typical Floor         : ', num2str(TypicalDL*convUnit),loadUnit];i=i+1;
        SummaryText{i}=['- Dead Load, Roof                  : ', num2str(RoofDL   *convUnit),loadUnit];i=i+1;
        SummaryText{i}=['- Live Load, Typical Floor         : ', num2str(TypicalLL*convUnit),loadUnit];i=i+1;
        SummaryText{i}=['- Live Load, Roof                  : ', num2str(RoofLL   *convUnit),loadUnit];i=i+1;
        SummaryText{i}=['- Generic Load, Typical Floor      : ', num2str(TypicalGL*convUnit),loadUnit];i=i+1;
        SummaryText{i}=['- Generic Load, Roof               : ', num2str(RoofGL   *convUnit),loadUnit];i=i+1;
        SummaryText{i}=['- Cladding Load                    : ', num2str(Cladding *convUnit),loadUnit];i=i+1;
        SummaryText{i}='';i=i+1;
        SummaryText{i}=['- Load Combination for Seismic Weight:'];i=i+1;
        SummaryText{i}=['    ',num2str(cDL_W),'*DL + ', num2str(cLL_W),'*LL + ', num2str(cGL_W),'*GL +', num2str(cCL_W),'*Cladding'];i=i+1;
        SummaryText{i}=['- Load Combination for Mass:'];i=i+1;
        SummaryText{i}=['    ',num2str(cDL_M),'*DL + ', num2str(cLL_M),'*LL + ', num2str(cGL_M),'*GL +', num2str(cCL_M),'*Cladding'];i=i+1;
        SummaryText{i}='';i=i+1;

        SummaryText{i}='';i=i+1;
        SummaryText{i}='MATERIAL';i=i+1;
        SummaryText{i}='------------------------------------------------------';i=i+1;
        SummaryText{i}=['- Material type/grade              : ', SteelMatType];       i=i+1;
        SummaryText{i}=['- Elastic modulus                  : ', num2str(E), matUnit];i=i+1;
        SummaryText{i}=['- Yield stress                     : ', num2str(fy),matUnit];i=i+1;
        if FrameType~=1
        SummaryText{i}=['- Yield stress - Brace             : ', num2str(fyBrace),matUnit];i=i+1;
        SummaryText{i}=['- Yield stress - Gusset plate      : ', num2str(fyGP),matUnit];i=i+1;
        end
        SummaryText{i}=['- Poisson ratio                    : ', num2str(mu),matUnit];i=i+1;
        SummaryText{i}='';i=i+1;
    
    SummaryText{i}='SUPPORTS & CONNECTIONS';i=i+1;
    SummaryText{i}='------------------------------------------------------';i=i+1;
    if Support==1
        SummaryText{i}=['- Main frame column supports are fixed'];i=i+1;
    else
        SummaryText{i}=['- Main frame column supports are pinned'];i=i+1;
    end
    if SpliceConnection==1
        SummaryText{i}=['- Column splices are assumed as pinned connections'];i=i+1;
    else
        SummaryText{i}=['- Column splices are assumed as fixed connections'];i=i+1;
    end
    if FrameType==1
        if MFconnection==1
            SummaryText{i}=['- Beam-to-column connections: welded moment connection'];i=i+1;
        elseif MFconnection==2
            SummaryText{i}=['- Beam-to-column connections: reduced beam section(RBS) connection'];i=i+1;
            SummaryText{i}=['                              a= ',num2str(a),'bf'];i=i+1;
            SummaryText{i}=['                              b= ',num2str(b),'d'];i=i+1;
            SummaryText{i}=['                              b= ',num2str(c),'bf'];i=i+1;
        end
    end
    if FrameType~=1
        if MFconnectionEven==1
            SummaryText{i}=['- Beam-to-column connections at even-numbered floors are modeled as pinned connections'];i=i+1;
        elseif MFconnectionEven==2
            SummaryText{i}=['- Beam-to-column connections at even-numbered floors are modeled as shear connections'];i=i+1;
        elseif MFconnectionEven==3
            SummaryText{i}=['- Beam-to-column connections at even-numbered floors are modeled as moment connections'];i=i+1;
        end
        if MFconnectionOdd==1
            SummaryText{i}=['- Beam-to-column connections at odd-numbered floors are modeled as pinned connections'];i=i+1;
        elseif MFconnectionOdd==2
            SummaryText{i}=['- Beam-to-column connections at odd-numbered floors are modeled as shear connections'];i=i+1;
        elseif MFconnectionOdd==3
            SummaryText{i}=['- Beam-to-column connections at odd-numbered floors are modeled as moment connections'];i=i+1;
        end
        SummaryText{i}='';i=i+1;
        SummaryText{i}=['Brace modeling'];i=i+1;
        SummaryText{i}=['---------------'];i=i+1;
        SummaryText{i}=['- number of segments               : ', num2str(nSegments)];   i=i+1;
        SummaryText{i}=['- number of integration points     : ', num2str(nIntegration)];i=i+1;
        SummaryText{i}=['- mid-length imperfection          : ', num2str(initialGI),'L'];   i=i+1;

    end
    SummaryText{i}='';i=i+1;
    
    SummaryText{i}='MEMBER MODELING';i=i+1;
    SummaryText{i}='------------------------------------------------------';i=i+1;
    if ColElementOption==1
        SummaryText{i}=['- Column members are modeled using lumped plasticity approach'];i=i+1;
    elseif ColElementOption==2
        SummaryText{i}=['- Column members are modeled using displacement-based fiber elements'];i=i+1;
    elseif ColElementOption==3
        SummaryText{i}=['- Column members are modeled using force-based fiber elements'];i=i+1;
    end
    SummaryText{i}='------------------------------------------------------';i=i+1;
end


SummaryText{i}='';i=i+1;
if Analysisstatus==1
    SummaryText{i}='ANALYSIS PARAMETERS';i=i+1;
    SummaryText{i}='------------------------------------------------------';i=i+1;
    if EV==1
        SummaryText{i}=['- Analysis Type                    : Eigenvalue'];i=i+1;
    elseif PO==1
        SummaryText{i}=['- Analysis Type                    : Pushover'];i=i+1;
        SummaryText{i}=['- Pushover Pattern                 : Mode ',num2str(ModePO)];i=i+1;
        SummaryText{i}=['- Target Roof Drift                : ',num2str(DriftPO*100),'% of Building Height'];i=i+1;
    elseif IDA==1
                         SummaryText{i}=['- Analysis Type                    : IDA'];i=i+1;
        if SA_metric==1; SummaryText{i}=['- Intensity Measure                : Sa(T1, ',num2str(zeta*100),'%)'];i=i+1; end
        if SA_metric==2; SummaryText{i}=['- Intensity Measure                : Sa_avg(0.2T1~3T1, ',num2str(zeta*100),'%)'];i=i+1; end
        SummaryText{i}=['- Intensity Increment              : ',num2str(SA_Step),'g'];i=i+1;
        SummaryText{i}=['- Collapse Point Tolerance         : ',num2str(SAstepmin),'g'];i=i+1;
        SummaryText{i}=['- SDR Limit for Collapse           : ',num2str(CollapseSDR*100),'%'];i=i+1;
        SummaryText{i}=['- IDA Slope for Collapse           : ',num2str(IDAslopeLimit),'rad/g'];i=i+1;
    elseif Dynamic_TargetSF==1
        SummaryText{i}=['- Analysis Type                    : Dynamic, Target Scale Factor'];i=i+1;
        SummaryText{i}=['- Target Scale Factor              : ',num2str(SF)];i=i+1;
    elseif Dynamic_TargetSA==1
        SummaryText{i}=['- Analysis Type                    : Dynamic, Target Seismic Intensity'];i=i+1;
        SummaryText{i}=['- Target Seismic Intensity         : ',num2str(TargetSA),'g'];i=i+1;
        SummaryText{i}=['- Scaling Period                   : ',num2str(T1),'sec'];i=i+1;
    end

    if IDA==1 || Dynamic_TargetSF==1 || Dynamic_TargetSA==1
        SummaryText{i}=['- Raleigh Damping Period           : ',num2str(DampModeI),' and ',num2str(DampModeJ)];i=i+1;
        SummaryText{i}=['- Damping Coefficient              : ',num2str(zeta*100),'%'];i=i+1;
        SummaryText{i}='';i=i+1;
        SummaryText{i}=['- Ground Motion Folder Path        : ',GMFolderPath];i=i+1;
        SummaryText{i}=['- Considered GMs                   : GM#',num2str(GM_Start),' to GM#',num2str(GM_Last)];i=i+1;
        SummaryText{i}=['- Free Vibration                   : ',num2str(TFreeVibration),' sec'];i=i+1;
        SummaryText{i}=['- Analysis Time Step               : ',num2str(dtstep),' * dT_GM'];i=i+1;
    end
    
    if Uncertainty==1
        SummaryText{i}=['- Numerical modeling uncertainty is considered.'];i=i+1;
        SummaryText{i}=['- Number of realizations per GM    : ',num2str(nRealizations)];i=i+1;
    end
end

SummaryText{i}='';i=i+1;

SummaryText{i}='******************************************************';i=i+1;
SummaryText{i}='******************************************************';i=i+1;
