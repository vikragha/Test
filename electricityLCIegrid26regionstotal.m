function [ LCIelectricity ] = electricityLCIegrid26regionstotal(filesstring,i,elec)
%FUNCTION ASSIGNS ELECTRICITY


    TMY3Site = string(table2cell(elec(:,1)));

    for j = 1:1011
        a(j) = strcmp(filesstring(i),TMY3Site(j));
        if a(j) == 1;
            LCIelectricity = elec(j,7); %2020 GHGs
        end
    end




