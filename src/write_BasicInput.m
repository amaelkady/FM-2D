
function write_BasicInput (INP, FrameType,NStory,NBay,CompositeX,Comp_I,Comp_I_GC,Units,E,mu0,fy,fyBrace,fyGP,Er,fyR,muR,Ec,fc,muC,EL_Multiplier,SteelMatID,TransformationX,nSegments,initialGI,nIntegration,Sigma, Uncertainty, resource_root)
            
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'#                                              INPUT                                               #\n');
fprintf(INP,'####################################################################################################\n');
fprintf(INP,'\n');

fprintf(INP,'# FRAME CENTERLINE DIMENSIONS\n');
fprintf(INP,'set NStory %2.0f;\n', NStory);
fprintf(INP,'set NBay   %2.0f;\n', NBay);
fprintf(INP,'\n');

fprintf(INP,'# MATERIAL PROPERTIES\n');
fprintf(INP,'set E   %.3f;\n',E);
if FrameType==4
    fprintf(INP,'set Ec  %.3f;\n',Ec);    
    fprintf(INP,'set Er  %.3f;\n',Er);    
    fprintf(INP,'set fc  %.3f;\n',fc);
    fprintf(INP,'set fyR %.3f;\n',fyR);
    fprintf(INP,'set muC %.3f;\n',muC);
end
fprintf(INP,'set mu  %.3f; \n',mu0);
if EL_Multiplier~= 1
fprintf(INP,'set fy  [expr %.3f * %5.1f]; % yield strength is amplified to implictly create an elastic model\n',fy,EL_Multiplier);
else
fprintf(INP,'set fy  [expr %.3f * %5.1f];\n',fy,EL_Multiplier);
end
if FrameType~=1 && FrameType~=4
    fprintf(INP,'set fyB [expr %.3f * %5.1f];\n',fyBrace,EL_Multiplier);
    fprintf(INP,'set fyG [expr %.3f * %5.1f];\n',fyGP,EL_Multiplier);
end
fprintf(INP,'\n');

fprintf(INP,'# BASIC MATERIALS\n');
fprintf(INP,'uniaxialMaterial Elastic  9  1.e-9; 		#Flexible Material \n');
fprintf(INP,'uniaxialMaterial Elastic 99  1.e12;        #Rigid Material \n');
if resource_root==''; load(strjoin(resource_root+"Material_Database.mat")); else; load resources\database\Material_Database.mat; end
if Units==1; transUnit=6.89476/1000; else; transUnit=1; end
if FrameType==4
    fprintf(INP,'uniaxialMaterial Steel02 666  $fyR $Er 0.01 18 0.925 0.15;  #Rebar Material \n')
    fprintf(INP,'Define_Material_RC       888  $Ec $fc "confined";           #Confined concrete Material \n')
    fprintf(INP,'Define_Material_RC       889  $Ec $fc "unconfined";          #Unconfined concrete Material \n')
else
    %fprintf(INP,'# Command syntax: uniaxial Material UVCuniaxial $matTag $E $fy $QInf $b $DInf $a $N $C1 $gamma1 $C2 $gamma2 \n');
    if SteelMatID==1
        fprintf(INP,'uniaxialMaterial UVCuniaxial  666 %.4f %.4f %.4f %.4f %.4f %.4f %d %.4f %.4f %.4f %.4f; #Voce-Chaboche Material', E, fy, Material.Qinf(1,1)*transUnit, Material.b(1,1), 0.00, 1.0, 2, Material.C1(1,1)*transUnit, Material.gamma1(1,1), Material.C2(1,1)*transUnit, Material.gamma2(1,1));
    else
        fprintf(INP,'uniaxialMaterial UVCuniaxial  666 %.4f %.4f %.4f %.4f %.4f %.4f %d %.4f %.4f %.4f %.4f; #Voce-Chaboche Material', Material.E(SteelMatID+1,1)*transUnit, Material.fy(SteelMatID+1,1)*transUnit, Material.Qinf(SteelMatID+1,1)*transUnit, Material.b(SteelMatID+1,1), 0.00, 1.0, 2, Material.C1(SteelMatID+1,1)*transUnit, Material.gamma1(SteelMatID+1,1), Material.C2(SteelMatID+1,1)*transUnit, Material.gamma2(SteelMatID+1,1));    
    end    
end
fprintf(INP,'\n\n');

fprintf(INP,'# GEOMETRIC TRANSFORMATIONS IDs\n');
fprintf(INP,'geomTransf Linear 		 1;\n');
fprintf(INP,'geomTransf PDelta 		 2;\n');
fprintf(INP,'geomTransf Corotational 3;\n');
fprintf(INP,'set trans_Linear 	1;\n');
fprintf(INP,'set trans_PDelta 	2;\n');
fprintf(INP,'set trans_Corot  	3;\n');
fprintf(INP,'set trans_selected  %d;\n', TransformationX);
fprintf(INP,'\n');

fprintf(INP,'# STIFF ELEMENTS PROPERTY\n');
if Units==1
    fprintf(INP,'set A_Stiff 1000000.0;\n');
    fprintf(INP,'set I_Stiff 10000000000.0;\n');
else
    fprintf(INP,'set A_Stiff 1000.0;\n');
    fprintf(INP,'set I_Stiff 100000.0;\n');
end
fprintf(INP,'\n');

fprintf(INP,'# COMPOSITE BEAM FACTOR\n');
if FrameType ~= 4
if CompositeX == 1
    fprintf(INP,'puts "Composite Action is Considered"\n');
    fprintf(INP,'set Composite 1;\n');
    fprintf(INP,'set Comp_I    %.3f;\n', Comp_I);
    fprintf(INP,'set Comp_I_GC %.3f;\n', Comp_I_GC);
else
    fprintf(INP,'set Composite 0;\n');
    fprintf(INP,'set Comp_I    %.3f;\n', Comp_I);
    fprintf(INP,'set Comp_I_GC %.3f;\n', Comp_I_GC);
end
fprintf(INP,'\n');
end

fprintf(INP,'# FIBER ELEMENT PROPERTIES\n');
fprintf(INP,'set nSegments    %d;\n',nSegments);
fprintf(INP,'set initialGI    %.5f;\n',initialGI);
fprintf(INP,'set nIntegration %d;\n',nIntegration);
fprintf(INP,'\n');

fprintf(INP,'# LOGARITHMIC STANDARD DEVIATIONS (FOR UNCERTAINTY CONSIDERATION)\n');
fprintf(INP,'global Sigma_IMKcol Sigma_IMKbeam Sigma_Pinching4 Sigma_PZ; \n');
fprintf(INP,'set Sigma_IMKcol [list  ');
for i=1:9
    if Sigma.IMKcol(i)==1.e-9 || Uncertainty==0; fprintf(INP,'1.e-9 '); else; fprintf(INP,'%.3f ',Sigma.IMKcol(i)); end
end
fprintf(INP,'];\n');

fprintf(INP,'set Sigma_IMKbeam   [list  ');
for i=1:9
    if Sigma.IMKbeam(i)==1.e-9 || Uncertainty==0; fprintf(INP,'1.e-9 '); else; fprintf(INP,'%.3f ',Sigma.IMKbeam(i)); end
end
fprintf(INP,'];\n');

fprintf(INP,'set Sigma_Pinching4 [list  ');
for i=1:8
    if Sigma.Pinching4(i)==1.e-9 || Uncertainty==0; fprintf(INP,'1.e-9 '); else; fprintf(INP,'%.3f ',Sigma.Pinching4(i)); end
end
fprintf(INP,'];\n');

fprintf(INP,'set Sigma_PZ        [list  ');
for i=1:4
    if Sigma.PZ(i)==1.e-9 || Uncertainty==0; fprintf(INP,'1.e-9 '); else; fprintf(INP,'%.3f ',Sigma.PZ(i)); end
end
fprintf(INP,'];\n');

if Sigma.fy==1.e-9 || Uncertainty==0;   fprintf(INP,'set Sigma_fy     1.e-9;\n'); else; fprintf(INP,'set Sigma_fy     %.3f;\n ',Sigma.fy);   end
if FrameType~=1
if Sigma.fyB==1.e-9 || Uncertainty==0;  fprintf(INP,'set Sigma_fyB    1.e-9;\n'); else; fprintf(INP,'set Sigma_fyB    %.3f;\n ',Sigma.fyB);  end
if Sigma.fyG==1.e-9 || Uncertainty==0;  fprintf(INP,'set Sigma_fyG    1.e-9;\n'); else; fprintf(INP,'set Sigma_fyG    %.3f;\n ',Sigma.fyG);  end
if Sigma.GI ==1.e-9 || Uncertainty==0;  fprintf(INP,'set Sigma_GI     1.e-9;\n'); else; fprintf(INP,'set Sigma_GI     %.3f;\n ',Sigma.GI);   end
end
if Sigma.zeta==1.e-9 || Uncertainty==0; fprintf(INP,'set Sigma_zeta   1.e-9;\n'); else; fprintf(INP,'set Sigma_zeta   %.3f;\n ',Sigma.zeta); end
fprintf(INP,'global Sigma_fy Sigma_fyB Sigma_fyG Sigma_GI; global xRandom;\n');
fprintf(INP,'set SigmaX $Sigma_fy;  Generate_lognrmrand $fy 	$SigmaX; 	set fy      $xRandom;\n');
if FrameType~=1 && FrameType~=4
fprintf(INP,'set SigmaX $Sigma_fyB; Generate_lognrmrand $fyB 	$SigmaX; 	set fyB 	$xRandom;\n');
fprintf(INP,'set SigmaX $Sigma_fyG; Generate_lognrmrand $fyG 	$SigmaX; 	set fyG 	$xRandom;\n');
fprintf(INP,'set SigmaX $Sigma_GI;  Generate_lognrmrand %f 	    $SigmaX; 	set initialGI 	$xRandom;\n', initialGI);
end
fprintf(INP,'\n');