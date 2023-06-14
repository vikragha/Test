%SCRIPT WILL RUN AN INDOOR CANNABIS PRODUCTION MODEL FOR 1,011 U.S. LOCATIONS.
%RESULTS ARE PRINTED AS AN EXCEL FILE TITLED "OUTPUTS" IN THE FOLDER WHERE 
%THIS SCRIPT IS LOCATED. IT WILL CONTAIN GREENHOUSE GAS EMISSIONS, 
%ELECTRICITY REQUIRED, AND NATURAL GAS REQUIRED FOR EACH LOCATION

clc; clear all; close all;
% Extract data
Location = '..\Indoor Cannabis Analysis\TMY3'; % folder where you have all TMY data
D = dir([Location,'\*.csv']); % copy this script to that directory, same folder as TMY
filenames = {D(:).name}.';
filesstring = string(filenames);
data = cell(length(D),1); % empty matrix
carbon = zeros(length(D),1);
Site = string(zeros(length(D),2));
Lat = zeros(length(D),1);
Long = zeros(length(D),1);
Electricity = zeros(length(D),10);
elecintensity = zeros(length(D),1);
ngintensity = zeros(length(D),1);
count = 0;

elec = readtable('Zipcodes.xlsx','ReadRowNames',false,'Range','A1:G1012');

for i = 1:1011 %1011 total %526 is fort collins %length(D):-1:1 % reads 1 to the number of files in directory
    tic
    fullname = [Location filesep D(i).name];
    Coord = xlsread(fullname,1,'E1:F1'); % Extract coordinates
    Lat(i) = Coord(1); % Allocate latitude of site
    Long(i) = Coord(2);% Allocate longitude of site
    
    [~,Loc] = xlsread(fullname,1,'B1:C1'); % Read location
    Site(i,1) = Loc{1} ; % City or town
    Site(i,2) = Loc{2};  %State

    Data = xlsread(fullname,1,'AF3:AO8762'); % Extract data faster to do it all at once
    T_o = Data(:,1);
    
    RH = Data(:,7);
    Pamb = Data(:,10)/10;
    avePamb = mean(Pamb); %average Pressure in kPa for year
  
    A = Indoor_Model_Facility_LCAv5(T_o,RH,Pamb,avePamb,filesstring,i,elec);
    
    carbon(i,:) = sum(A(:,4))-A(38,4)-A(39,4);
    elecintensity(i) = A(38,1); %all columns are the same value here
    ngintensity(i) = A(39,1);

    count = count +1
    toc
end

% Write outputs into excel file
carbon = num2cell(carbon);
elecintensity = num2cell(elecintensity);
ngintensity = num2cell(ngintensity);

Output = [filenames,Lat,Long,Site,carbon,elecintensity,ngintensity];

xlswrite('\Outputs.xlsx',Output,1,'A2:H1012');

