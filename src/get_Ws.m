function [Ws, Weight]=get_Ws(NStory, FootPrintArea, Perimeter, H1, Htyp, Load, weightcoeff)
global Units

if Units==1;  convfactor=1/1000/1000;
else;         convfactor=1/12/12/1000;
end

Weight.W1    = (weightcoeff.DL_W * Load.DLtyp  + weightcoeff.LL_W * Load.LLtyp  + weightcoeff.GL_W * Load.GLtyp)  * FootPrintArea + weightcoeff.CL_W * Load.Cladding * (0.5*H1+0.5*Htyp) * Perimeter;
Weight.Wtyp  = (weightcoeff.DL_W * Load.DLtyp  + weightcoeff.LL_W * Load.LLtyp  + weightcoeff.GL_W * Load.GLtyp)  * FootPrintArea + weightcoeff.CL_W * Load.Cladding *            (Htyp) * Perimeter;
Weight.Wroof = (weightcoeff.DL_W * Load.DLroof + weightcoeff.LL_W * Load.LLroof + weightcoeff.GL_W * Load.GLroof) * FootPrintArea + weightcoeff.CL_W * Load.Cladding *        (0.5*Htyp) * Perimeter;

if NStory==1
    Ws = Weight.W1;
else
    Ws = Weight.W1 + (NStory-2)*Weight.Wtyp + Weight.Wroof;
end

Weight.W1    = Weight.W1    *convfactor;
Weight.Wtyp  = Weight.Wtyp  *convfactor;
Weight.Wroof = Weight.Wroof *convfactor;
Ws           = Ws           *convfactor;