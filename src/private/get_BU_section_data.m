function [SecData]=get_BU_section_data(Section, SecData, count)

    arguments
        Section  char;
        SecData = struct('d', 0);
        count   = 1;
    end

    SecData.Name(count,:)=cellstr(Section);

    Section(1:3) = [];
    SectionSplit = strsplit(Section,'x');
    d=str2num(cell2mat(SectionSplit(1)));
    tw=str2num(cell2mat(SectionSplit(3)));
    bf=str2num(cell2mat(SectionSplit(2)));
    tf=str2num(cell2mat(SectionSplit(4)));

    SecData.d(count,1)=d;
    SecData.tw(count,1)=tw;
    SecData.bf(count,1)=bf;
    SecData.tf(count,1)=tf;
    SecData.Ix(count,1)=bf*d^3/12 - (bf-tw)*(d-2*tf)^3/12;
    SecData.Iy(count,1)=2*tf*bf^3/12 + (d-2*tf)*tw^3/12;

    SecData.Area(count,1)=d*bf-(d-2*tf)*(bf-tw);
    SecData.rx(count,1)=sqrt(SecData.Ix(count,1)/SecData.Area(count,1));
    SecData.ry(count,1)=sqrt(SecData.Iy(count,1)/SecData.Area(count,1));

    SecData.Sx(count,1)=SecData.Ix(count,1)/(d/2);
    SecData.Sy(count,1)=SecData.Iy(count,1)/(bf/2);

    SecData.Zx(count,1)=2*(bf*tf*(d-tf)*0.5 + (d-2*tf)*0.5*tw*(d-2*tf)*0.25);
    SecData.Zy(count,1)=4*(0.5*bf*tf*(0.25*bf)) + 2*(0.5*d*tw * (0.25*tw));

    SecData.h_tw(count,1)=(d-2*tf)/tw;
    SecData.bf_tf(count,1)=(bf-tw)/2/tf;
end