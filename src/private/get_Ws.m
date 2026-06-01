function [LOAD]=get_Ws(LAYOUT, LOAD)
global Units

v2struct(LAYOUT);
v2struct(LOAD);

if Units==1;  convfactor=1/1000/1000;
else;         convfactor=1/12/12/1000;
end

LOAD.W1    = (DL_W * DLtyp  + LL_W * LLtyp  + GL_W * GLtyp)  * FootPrintArea + CL_W * Cladding * (0.5*H1+0.5*Htyp) * Perimeter;
LOAD.Wtyp  = (DL_W * DLtyp  + LL_W * LLtyp  + GL_W * GLtyp)  * FootPrintArea + CL_W * Cladding *            (Htyp) * Perimeter;
LOAD.Wroof = (DL_W * DLroof + LL_W * LLroof + GL_W * GLroof) * FootPrintArea + CL_W * Cladding *        (0.5*Htyp) * Perimeter;

if NStory==1
    Ws = LOAD.W1;
else
    Ws = LOAD.W1 + (NStory-2)*LOAD.Wtyp + LOAD.Wroof;
end

LOAD.W1    = LOAD.W1    *convfactor;
LOAD.Wtyp  = LOAD.Wtyp  *convfactor;
LOAD.Wroof = LOAD.Wroof *convfactor;
LOAD.Ws    = LOAD.Ws           *convfactor;