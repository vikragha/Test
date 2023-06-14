function [ LCA ] = Indoor_Model_Facility_LCAegrid26regionstotal(T_o,RH,Pamb,avePamb,filesstring,i,elec)
%THIS FUNCTION IS THE INDOOR CANNABIS GROWTH MODEL THAT DETERMINES ALL
%MATERIAL AND ENERGY REQUIRED. DATA INPUT REQUIREMENTS ARE READ FROM
%SUPPORTING EXCEL FILES (PRELIMINARY MODEL AND TMY3 DATA AT EACH LOCATION).
%CALCUATIONS ARE DIVIDED INTO STAGE OF LIFE (k = 1,2,3,4 FOR CLONE, VEG,
%FLOWER, AND CURE, RESPECTIVELY). ANNUAL TOTALS ARE DETERMINED. MATERIAL
%AND ENERGY INVENTORY ARE CONVERTED TO GREENHOUSE GAS EMISSIONS THROUGH 
%LIFE CYCLE INVENTORY READ FROM SUPPORTING EXCEL DOCUMENTS. THE RESULTING 
%GREENHOUSE GAS EMISSIONS ARE FED BACK TO THE MAIN FILE FOR EACH LOCATION.


% clear all; close all; clc %ONLY UNCOMMENT IF RUNNING NOT AS A FUNCTION

tic
%INPUT VARIABLES FROM PRELIMINARY MODEL EXCCEL FILE:
Conversions = xlsread('Indoor Cannabis Model.xlsx','Conversions','G2:G100');
Properties = xlsread('Indoor Cannabis Model.xlsx','Properties','I2:I100');
input_og = readtable('Indoor Cannabis Model.xlsx','ReadRowNames',false,'Range','B5:H128');
input_dataset = table2cell(input_og,'ReadObsNames',true);
input_dataset_new = [input_dataset(:,5),input_dataset(:,6),input_dataset(:,7)];
input_trans = transpose(input_dataset_new);
input = cell2table(input_trans);
input.Properties.VariableNames = input_dataset(:,1);
%COMMENT OUT BELOW WHEN RUNNING AS FUNCTION
% Data = xlsread('724769TYA.csv','AF3:AO8762');
% T_o = Data(:,1); %OUTSIDE TEMPERATURE AT LOCATION
% RH = Data(:,7); %OUTISDE RELATIVE HUMIDIY AT LOCATION
% Pamb = Data(:,10)/10; %AMBIENT PRESSURE AT LOCATION
% avePamb = mean(Pamb);
% 
% Location = 'C:\Users\hsummers\Desktop\Matlab US Graph'; % folder where you have all TMY data
% D = dir([Location,'\*.csv']); % copy this script to that directory, same folder as TMY
% filenames = {D(:).name}.';
% filesstring = string(filenames);
% i = 526; %TMY3 FILE NUMBER IN FOLDER

%LCI INPUT TABLE+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
lci = readtable('Indoor Cannabis Model.xlsx','Sheet','LCI','ReadRowNames',false,'Range','D12:M40');
lci_headers = readtable('Indoor Cannabis Model.xlsx','Sheet','LCI','ReadRowNames',false,'Range','C12:C40');
lci_headers_new = table2cell(lci_headers,'ReadObsNames',false);
LCIinput_dataset = table2cell(lci,'ReadObsNames',true);
LCIinput_trans = transpose(LCIinput_dataset);
LCIinput = cell2table(LCIinput_trans);
LCIinput.Properties.VariableNames = lci_headers_new(:,1);

elec = readtable('Zipcodes.xlsx','ReadRowNames',false,'Range','A1:G1012');
% egridLCI = xlsread('Preliminary Model (Full Facility) v1.1.xlsx','eGrid','K5:K54');


%ELECTRICITY LCI AND CONVERSIONS+++++++++++++++++++++++++++++++++++++++++++
Elec = electricityLCIegrid26regionstotal(filesstring,i,elec);
Electricity = table2array(Elec);

%FUNCTION THAT ASSIGNS GEOSPATIALLY CORRECT LCI FOR ELECTRICITY

Time = zeros(1,8760);
for i = 1:((8760)/24)
    for k = 1:24
            j = ((i-1)*24)+k;
        Time(1,j) = k;    
    end
end
 
scenario = 2; %1 = optimistic, %2 = baseline, %3 = conservative
 
%VENTILATION SPECS ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
N = input.N(scenario);
extractor_fan_HP = input.extractor_fan_HP(scenario); %HP/hr
intake_fan_HP = input.intake_fan_HP(scenario); %HP/hr
circ_fan_HP = input.fan_power(scenario); %HP/hr
 
%LIGHTING SCHEDULE ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
L_clone = input.L_clone(scenario); %weeks
L_veg = input.L_veg(scenario); %weeks
L_flower  = input.L_flower(scenario); %weeks
L_cure = input.L_cure(scenario); %weeks
L_transition = input.transition_days(2); %days
 
ballast_loss = [-0.0601*log(input.L_clone_W(scenario))+0.52522,-0.0601*log(input.L_veg_W(scenario))+0.52522,... 
    -0.0601*log(input.L_flower_W(scenario))+0.52522,-0.0601*log(input.L_cure_W(scenario))+0.52522]; %Watts
grow_season = input.L_clone(scenario)+input.L_veg(scenario)+input.L_flower(scenario)+input.L_cure(scenario); %weeks
 
season_count_og = 365/(L_flower*7+L_transition); %not whole number
season_count_round = 1:1:floor(365/(L_flower*7+L_transition));  %limiting grow portion is flower
season_i_count = season_count_round*(L_flower*7+L_transition)*24;
if season_i_count <= 8760
    season_count = length(season_count_round)+2;
end
   
L_clone_hours = input.L_clone_hours(scenario); %hours/day
L_veg_hours = input.L_veg_hours(scenario); %hours/day
L_flower_hours = input.L_flower_hours(scenario); %hours/day
L_cure_hours = input.L_cure_hours(scenario); %hours/day 
L_break_hours = input.L_break_hours(scenario); %hours/day
 
L_clone_W =  input.L_clone_W(scenario);%*(1-ballast_loss(1)); %W/m^2
L_veg_W =   input.L_veg_W(scenario);%*(1-ballast_loss(2)); %W/m^2
L_flower_W = input.L_flower_W(scenario);%*(1-ballast_loss(3)); %W/m^2
L_cure_W = input.L_cure_W(scenario);%*(1-ballast_loss(4)); %W/m^2 
L_break_W = input.L_break_W(scenario);%*(1-ballast_loss(4)); %W/m^2
 
%RELATIVE HUMIDITY LIMITS +++++++++++++++++++++++++++++++++++++++++++++++++
RH_clone_max    = input.RH_clone_max(scenario)*100;  RH_clone_mean  = input.RH_clone_mean(scenario)*100;  RH_clone_min  = input.RH_clone_min(scenario)*100;
RH_veg_max      = input.RH_veg_max(scenario)*100;    RH_veg_mean    = input.RH_veg_mean(scenario)*100;    RH_veg_min    = input.RH_veg_min(scenario)*100;
RH_flower_max   = input.RH_flower_max(scenario)*100; RH_flower_mean = input.RH_flower_mean(scenario)*100; RH_flower_min = input.RH_flower_min(scenario)*100;
RH_cure_max     = input.RH_cure_max(scenario)*100;   RH_cure_mean   = input.RH_cure_mean(scenario)*100;   RH_cure_min   = input.RH_cure_min(scenario)*100;
RH_water = 100;
 
%TEMPERATURE LIMITS +++++++++++++++++++++++++++++++++++++++++++++++++++++++
T_clone_day = input.T_clone_day(scenario); %deg C
T_clone_night = input.T_clone_night(scenario); %deg C
T_veg_day = input.T_veg_day(scenario); %deg C
T_veg_night = input.T_veg_night(scenario); %deg C
T_flower_day = input.T_flower_day(scenario); %deg C
T_flower_night = input.T_flower_night(scenario); %deg C
T_cure_day = input.T_cure_day(scenario); %deg C
T_cure_night = input.T_cure_night(scenario); %deg C
T_well = input.T_well(scenario); %deg C
T_water = input.T_water(scenario); %deg C
 
%WATERING SCHEDULE ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
water_rate = input.water_rate(scenario); %gal/plant-day
pumping_power = input.pumping_power(scenario)*1000; %Wh/gallon
 
%NUTRIENTS/FUNGICIDES/INSECTICIDES+++++++++++++++++++++++++++++++++++++++++
soil_coco = input.soil_coco(scenario); %m3/plant
biofungicide_mass = input.biofungicide_mass(scenario); %kg/harvest
soil_amendment_mass = input.soil_amendment_mass(scenario); %kg/harvest
ammonium_nitrate_mass = input.ammonium_nitrate_mass(scenario); %grams/plant
triple_superphosphate_mass = input.triple_superphosphate_mass(scenario); %grams/plant
potassium_chloride_mass = input.potassium_chloride_mass(scenario); %grams/plant
% pesticide_mass = input.pesticide_mass(scenario); %kg/harvest
neem_oil_mass = input.neem_oil_mass(scenario); %liters/plant-cycle
neem_oil_water = input.neem_oil_water(scenario); %liters/plant-cycle
neem_oil_soap = input.neem_oil_soap(scenario); %liters/plant-cycle
 
%CO2 CONCENTRATIONS++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CO2_veg_conc = input.CO2_veg_conc(scenario); %ppm
CO2_flower_conc = input.CO2_flower_conc(scenario); %ppm
CO2_atmos = input.CO2_atmos(scenario); %ppm
 
%CONVERSIONS, PROPERTIES, EFFICIENCIES ++++++++++++++++++++++++++++++++++++
COP_chiller = input.COP_chiller(scenario);
Nth_heat = input.Nth_heat(scenario);
HHV_ng_mass = Properties(1); %MJ/kg
HP_to_kW = Conversions(22); %.7457 kW
kW_to_W = Conversions(16); %1000W
Day_to_hr = Conversions(31); %24 hrs
Year_to_days = Conversions(28); %365 days
Kg_to_g = Conversions(6); %1000 grams
tonnes_to_kg = Conversions(3); %1000 kgs
coco_density = Properties(19); %kg/m^3
perlite_density = Properties(18); %kg/m^3
neem_oil_density = Properties(20); %kg/m^3
soap_density = Properties(21); %kg/m^3
m3_to_liter = Conversions(10); %1000 liters
MJ_to_kWh = Conversions(15); %0.27778 kWh
gals_to_liters = Conversions(8); %3.78541 liters
peat_density = Properties(14); % kg/m^3
kg_to_lb = Conversions(7); %2.20462 lbs
mi_to_km = Conversions(43); %1.60934 km
 


%BASELINE INPUTS ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%Facility Specs
A = input.A(scenario);   %TOTAL area of floor (m^2)
A_g_total = input.A_g_total(scenario); %ALLOCATED GROW AREA, area solely occupied by plants (m^2)
A_g_perc = [input.A_g_1(scenario),input.A_g_2(scenario),input.A_g_3(scenario),input.A_g_4(scenario)];
A_g = A_g_perc*input.A_g_total(scenario);
A_g_use = input.A_g_use(scenario);
L = sqrt(A*A_g_perc);
W = L; %assumes square greenhouse
H = input.H(scenario); %assumed height of wall at exterior wall in meters
V = A*input.H(scenario); %TOTAL Volume of building (m^3)
r_v = input.N(scenario)*V/(input.A_g_total(scenario)); %ventilation rate (m^3/m^2-hr)
plant_area = input.plant_area(scenario); %plants/m^2-grow area
fan = 500*V*60/(1200*A_g_total); %fan rate (m^3/m^2-hr)
SA = 2*L.*H+2*W.*H+L.*W; %Surface area of entire building (m^2)
CFM = V*N/60/Conversions(11); %use this for fan sizing specs (was 1.0227E5)
t     = input.t(scenario);   %thickness of wall material in meters
k     = input.k(scenario);   %Thermal conductivity of exterior walls, concrete W/(m*K)
rho_air   = Properties(5);    %density of air (kg/m^3)
rho_water = Properties(4);    %density of water (kg/m^3)
cp_air    = Properties(6);    %specific heat of air at 300 deg K (J/kg-K)
specific_v_CO2   = Properties(9)*Conversions(7)*Conversions(11);    %specific volume of CO2 (m^3/kg)
cp_water = Properties(10); %kJ/kg-K
h_water = Properties(8); %J/kg-water
h_water_liq_20 = Properties(16); %J/kg-water
h_water_vap_100 = Properties(17); %J/kg-water
hfg_water = Properties(13); %J/kg-water
percent_recirc = input.percent_recirc(scenario);
h_air_out = input.h_air_out(scenario); %convective heat transfer coefficient, based on velocity W/m^2-K, could be calculated from TMY3
h_air_in  = input.h_air_in(scenario);  %convective heat transfer coefficient, based on velocity W/m^2-K, could be calculated from N
RH_sat = 100; %relative humidity at fully saturated, for dehumidification
Landfill_methane = input.Landfill_methane(scenario); %mass CH4 out per mass landfill in
Landfill_carbon = input.Landfill_carbon(scenario); %mass CH4 out per mass landfill in
carbon_seq_product = input.Carbon_seq_product(scenario); % of product mass that is sequestered CO2e mass
carbon_seq_landfill = input.Carbon_seq_landfill(scenario); % of landfill mass that is sequestered CO2e mass


%TRANSPORTATION DISTANCES
trans_landfill = input.Trans_landfill(scenario)*mi_to_km; %km
trans_dist_lorry = input.Trans_dist_lorry(scenario)*mi_to_km; %km
trans_dist_truck = input.Trans_dist_truck(scenario)*mi_to_km; %km
trans_dist_pass = input.Trans_dist_pass(scenario)*mi_to_km; %km

U = 1/(t/k+1/h_air_in+1/h_air_out); %page 116 in Heat Transfer Text %W/m^2-K
 
for a = 1:length(A_g)
mass_flow_air(a) = N*H*A_g(a)*rho_air/(3600*A_g_use); %DO *.1 for office validation %kg/s of air due to HVAC
mass_stored_air(a) = N*H*A_g(a)*rho_air/(3600*A_g_use)/N; %essentially sets N = 1 for the E_stored terms in Temp balances
%mass_flow_ac(a) = mass_flow_air(a)*percent_recirc; %kg/s of air due to A/C
end
 
%PLANT SPECS ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
plant_yield = input.plant_yield(scenario); %kg-dry weed/m^2-yr
plant_count = input.plant_count(scenario); %plants/harvest
plant_yield_year = plant_yield*season_count_og*sum(A_g)*A_g_perc(3); %kg-bud/yr
plant_waste = input.plant_waste(scenario); %lb waste/lb plant waste
soil_waste_clone = input.soil_waste_clone(scenario); %m3/plant
soil_waste_veg = input.soil_waste_veg(scenario); %m3/plant
soil_waste_flower = input.soil_waste_flower(scenario); %m3/plant
 
 
 
% PREALLOCATION OF ALL ARRAYS +++++++++++++++++++++++++++++++++++++++++++++
Q_lights = zeros(4,length(T_o));
Q_light_load = zeros(4,length(T_o)+1);
water = zeros(4,length(T_o));
Q_water = zeros(4,length(T_o));
DH_P = zeros(4,length(T_o));
HVAC_P = zeros(4,length(T_o));
CO2 = zeros(4,length(T_o)); 
HVAC_dehumid_heat = zeros(4,length(T_o));
HVAC_heating = zeros(4,length(T_o));
HVAC_Hum_heat = zeros(4,length(T_o));
HVAC_humid = zeros(4,length(T_o));
HVAC_cooling = zeros(4,length(T_o));
HVAC_hum_cool = zeros(4,length(T_o));
HVAC_dehumid_2 = zeros(4,length(T_o));
HVAC_dehumid = zeros(4,length(T_o));
HVAC_heat_temp_2 = zeros(4,length(T_o));
HVAC_heat_temp = zeros(4,length(T_o));
HVAC_humid_temp = zeros(4,length(T_o));
HVAC_cool_temp = zeros(4,length(T_o));
HVAC_hh_heat_1 = zeros(4,length(T_o));
HVAC_hh_heat_2 = zeros(4,length(T_o));
HVAC_hh_vap = zeros(4,length(T_o));
h_heat_max = zeros(4,length(T_o));
h_humheat_temp = zeros(4,length(T_o));
AC_P = zeros(4,length(T_o));
HEAT_P = zeros(4,length(T_o));
T_f_HVAC = zeros(4,length(T_o)+1);
T_f_AC = zeros(4,length(T_o)+1);
w_inside = zeros(4,length(T_o)+1);
w_outside = zeros(1,length(T_o));
h_outside = zeros(1,length(T_o));    
% w_inside_setpoint = zeros(4,length(T_o));
% h_setpoint = zeros(4,length(T_o));
% T_sat = zeros(4,length(T_o));
% h_sat = zeros(4,length(T_o));
% h_dehum_low = zeros(4,length(T_o));
% h_heat_max = zeros(4,length(T_o));
% h_dehumheat_temp = zeros(4,length(T_o));
% h_humheat_temp = zeros(4,length(T_o));
% w_hum = zeros(4,length(T_o));
% h_hum = zeros(4,length(T_o));
h_i = zeros(4,length(T_o)+1);
ET = zeros(4,length(T_o));   
 
               
for i = 1:8760             
[~,w_outside(i),~,h_outside(i),~,~,~] = Psychrometricsnew ('Tdb',T_o(i),'phi',RH(i),'Pamb',Pamb(i));  %Enthalphy of outside air at time n
 
end 
 
 
 
%TOLERANCE FOR ITERATIVE SOLVING OF h_i & T_f_HVAC ++++++++++++++++++++++++
tolerance = 0.01;
 
 
%STAGE COUNTERS +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
i_count_clone = 24*7*L_clone;
i_count_veg = 24*7*L_veg;
i_count_flower = 24*7*L_flower;
i_count_cure = 24*7*L_cure;
i_count_break = 24*L_transition; %no 7 b/c this is days
i_count_clone = ceil(i_count_clone);
i_count_veg = ceil(i_count_veg);
i_count_flower = ceil(i_count_flower);
i_count_cure = ceil(i_count_cure);
 
 
%TIME DEPENDENT CALCULATIONS ++++++++++++++++++++++++++++++++++++++++++++++
for k = 1 %CLONE
%SETTING INITIAL CONDITIONS INSIDE [Tdb, w, phi, h, Tdp, v, Twb]
T_i = T_clone_day;
T_f_HVAC(1) = T_clone_day;
T_f_AC(1) = T_clone_day;
%RH = 100 at fully saturated, this is for dehumidification calculations
[~,w_inside(1),~,h_i(1),~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_clone_max(2)*100,'Pamb',avePamb); 
  for m = 1:season_count
    for j = 1:i_count_clone
 
            stage = 1;
            i = j+((m-1)*i_count_break + m*i_count_flower)-i_count_veg-i_count_clone-i_count_break;          
            if 1 <= i && i <= 8760
            %scaler_clone(i) = j/i_count_clone;
            
            if Time(i) == 24
                 water(k,i) = water_rate*plant_count*.1;%plant_area*A_g(stage);%scaler_clone(i);%*scaler(i)+water(i_count_veg-24)+water(i_count_veg-25); %BECAUSE THE ROUNDING ERROR WITH i %kg/hr
            end
            
            if Time(i)<=L_clone_hours %lights on
                Q_lights(k,i) = L_clone_W;  %will be zero when Time(i)>L_clone_hours
                T_i = input.T_clone_day(scenario); %setpoint
                T_max = input.T_clone_day(1); %maximum allowable T_clone_day
                T_min = input.T_clone_day(3); %minimum allowable T_clone_day
                RH_max = input.RH_clone_max(1)*100; %maximum allowbable RH_clone
                RH_min = input.RH_clone_min(3)*100; %minimum allowable RH_clone
            else %lights off
                T_i = input.T_clone_night(scenario);
                T_max = input.T_clone_night(1); %maximum allowable T_clone_night
                T_min = input.T_clone_night(3); %minimum allowable T_clone_night
                RH_max = input.RH_clone_max(1)*100; %maximum allowable RH_clone
                RH_min = input.RH_clone_min(3)*100; %minimum allowable RH_clone
            end
                %MAX AND MIN ABSOLUTE HUMIDITY
                [~,w_max,~,h_setpoint_max,~,~,~] = Psychrometricsnew ('Tdb',T_max,'phi',RH_max,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                [~,w_min,~,h_setpoint_min,~,~,~] = Psychrometricsnew ('Tdb',T_min,'phi',RH_min,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                
                if Q_lights(k,i)~=0
                    Q_light_load(k,i) = Q_lights(k,i)*A_g(stage); %Watts
                else
                    Q_light_load(k,i) = 0;
                end
                
                 %HVAC, ALWAYS ON BASED ON AIR CHANGES
                if w_outside(i)>w_max %Dehumidification and re-heat
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_clone_mean(2)*100,'Pamb',Pamb(i));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid(k,i) = mass_flow_air(stage)*((h_outside(i)-h_sat)-cp_water*T_sat*(w_outside(i)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp(k,i) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/Nth_heat;
                    HVAC_dehumid_heat(k,i) = HVAC_dehumid(k,i) + HVAC_heat_temp(k,i);
                elseif w_outside(i)<w_max && w_outside(i)>w_min %Simple Heating
                    if RH(i)>RH_max && T_o(i)<T_max
                        if T_o(i)<T_max && T_o(i)>T_i
                            [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,i) = mass_flow_air(stage)*(h_heat_max-h_outside(i))/Nth_heat;
                        elseif T_o(i)<=T_i && T_o(i)>T_min
                            [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_i,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,i) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(i))/Nth_heat;
                        elseif T_o(i)<=T_min
                            [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                            HVAC_heating(k,i) = mass_flow_air(stage)*(h_humheat_temp-h_outside(i))/Nth_heat;
                        end
                    elseif RH(i)<=RH_max && T_o(i)<T_min
                        [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_i,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_heating(k,i) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(i))/Nth_heat;
                        
                    elseif RH(i)<=RH_min && T_o(i)>T_max %SIMPLE COOLING!!!!
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,i) = mass_flow_air(stage)*(h_outside(i)-h_heat_max)/COP_chiller;
                    elseif RH(i)<=RH_min && T_o(i)<=T_max
                        [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                        HVAC_cooling(k,i) = mass_flow_air(stage)*(h_outside(i)-h_humheat_temp)/COP_chiller;
                    elseif RH(i)>RH_min && T_o(i)>T_max
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,i) = mass_flow_air(stage)*(h_outside(i)-h_heat_max)/COP_chiller;
                    end                     
                elseif w_outside(i)<w_min && T_o(i)<T_min %Heating & Humidification
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_hh_heat_1(k,i) = mass_flow_air(stage)*(h_humheat_temp-h_outside(i))/Nth_heat;
                    %HVAC_hh_heat_2(k,i) = mass_flow_air(stage)*(h_setpoint_min(k,i)-h_humheat_temp(k,i))/Nth_heat;
                    HVAC_hh_vap(k,i) = mass_flow_air(stage)*(w_min-w_outside(i))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %If negative, then heating, shouldn't be though
                    HVAC_Hum_heat(k,i) = HVAC_hh_heat_1(k,i) + HVAC_hh_vap(k,i);
                elseif T_min<T_o(i) && T_max>T_o(i) %Isothermal Humidification
                    if w_outside(i)<w_min %&& RH(i)<RH_min(i) 
                    HVAC_humid(k,i) = mass_flow_air(stage)*(w_min-w_outside(i))*(h_water_vap_100-h_water_liq_20)/Nth_heat;
                    else
                    test = test; %shouldn't ever be in this zone, just a test
                    end               
                elseif w_outside(i)<w_min && T_o(i)>T_max
                    [~,w_hum,~,h_hum,~,~,~] = Psychrometricsnew ('phi',input.RH_clone_mean(2)*100,'Tdb',T_o(i),'Pamb',Pamb(i)); %Enthalphy at outside temp and RH setpoint for humidification
                    [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                    HVAC_humid_temp(k,i) = mass_flow_air(stage)*(w_min-w_outside(i))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %Isothermal Humidification
                    HVAC_cool_temp(k,i) = mass_flow_air(stage)*(h_hum-h_heat_max)/COP_chiller; %Simple Cooling, constant w
                    HVAC_hum_cool(k,i) = HVAC_humid_temp(k,i) + HVAC_cool_temp(k,i);                    
                end
 
                %CALCULATE PLANT MOISTURE VAPOR RELEASED
                if Q_lights(k,i) ~=0
                    ET(k,i) = (0.00006*Q_lights(k,i)+0.0004)*4;%*scaler(i); %kg H2O/m^2-hr
                else
                    ET(k,i) = (0.00006*L_clone_W+0.0004)*4*0.3;%scaler(i)*0.3; %30% of daytime sweat occurs at night
                end
                
                %AT END OF HVAC, GET NEW TEMP AND RH, USE FOR TEMPS AND W'S
                %NEEDED FOR CALCULATING T_FINAL AND W_FINAL
               
                
                %FIND INITIAL GUESS TEMPERATURE AT END OF HOUR
                T_f_HVAC(k,i+1) = (Q_light_load(k,i)+U*SA(stage)*(T_o(i)+273)+cp_air*mass_stored_air(stage)*(T_f_HVAC(k,i)+273)+...
                    cp_air*mass_flow_air(stage)*(T_min+273))/(cp_air*mass_stored_air(stage)+U*SA(stage)+cp_air*mass_flow_air(stage)); %temp at "end of hour" or i+1 iteration
                T_f_HVAC(k,i+1) = T_f_HVAC(k,i+1)-273; %convert to celsius %w
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,i+1) = (Q_light_load(k,i)+mass_stored_air(stage)*h_i(k,i)-U*SA(stage)*(T_f_HVAC(k,i+1)-T_o(i))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));          
                               
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,i+1) = (ET(k,i)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,i)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,i+1),'w',w_inside(k,i+1),'Pamb',Pamb(i));  %wmax_new
                
                count = 1;
                while abs(T_new-T_f_HVAC(k,i+1))>tolerance
                T_f_HVAC(k,i+1) = T_new;
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,i+1) = (Q_light_load(k,i)+mass_stored_air(stage)*h_i(k,i)-U*SA(stage)*(T_f_HVAC(k,i+1)-T_o(i))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,i+1) = (ET(k,i)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,i)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,i+1),'w',w_inside(k,i+1),'Pamb',Pamb(i));  %wmax_new
                %T_f_HVAC(i+1) = store/2;
                count = count + 1;
                end
                T_f_HVAC(k,i+1) = T_new; %celcius %CHANGE THIS TO T_f_HVAC(i+1)
 
                
                %AUXILARY DEHUMIDIFICATION
                if w_inside(k,i+1)>=w_max
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_clone_mean(2)*100,'Pamb',Pamb(i));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid_2(k,i) = mass_flow_air(stage)*((h_i(k,i+1)-h_sat)-cp_water*T_sat*(w_inside(k,i+1)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp_2(k,i) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/COP_chiller;
                    DH_P(k,i) = HVAC_dehumid_2(k,i) + HVAC_heat_temp_2(k,i);
                    T_f_HVAC(k,i+1) = T_min;
                    
                    %DH_P(i) = (ET(i)*A_g(stage)/3600*h_water-mass_flow_air(stage)*(h_i(i+1)-h_setpoint(i))-mass_stored_air(stage)*(h_i(i+1)-h_i(i)))/COP_chiller;
                elseif w_inside(k,i+1)<w_max && w_inside(k,i+1)>w_min
                    if T_f_HVAC(k,i+1)>T_max %AUXILARY AIR CONDITIONING
                        AC_P(k,i) = (Q_light_load(k,i)-mass_stored_air(stage)*cp_air*(T_max-T_f_HVAC(k,i+1))-U*SA(stage)*(T_max-T_o(i)))/COP_chiller;
                        T_f_HVAC(k,i+1) = T_max;   
                    end
                %AUXILARY HEATING
                elseif T_f_HVAC(k,i+1)<T_min
                        HEAT_P(k,i) = -(Q_light_load(k,i)-mass_stored_air(stage)*cp_air*(T_min-T_f_HVAC(k,i+1))-U*SA(stage)*(T_min-T_o(i)));
                        T_f_HVAC(k,i+1) = T_min;
                end 
        HVAC_P(k,i) = HVAC_dehumid_heat(k,i) + HVAC_heating(k,i) + HVAC_Hum_heat(k,i) + HVAC_humid(k,i) + HVAC_cooling(k,i) + HVAC_hum_cool(k,i);
        Climate_P(k,i) = HVAC_P(k,i) + AC_P(k,i) + DH_P(k,i);
            end
        end
%         elseif (j*i_count_flower+1)<=i && i<=(j*i_count_flower+1+i_count_break)% BREAK: NO PLANTS
        for n = (i+1):(((m)*i_count_break + (m+1)*i_count_flower)-i_count_veg-i_count_break-i_count_clone)
            if 1 <= n && n <= 8760
            stage = 1;
            
            if Time(n)<=L_break_hours %lights on
                Q_lights(k,n) = L_break_W;  %will be zero when Time(i)>L_clone_hours
                T_i = input.T_break_day(scenario); %setpoint
                T_max = input.T_break_day(1); %maximum allowable T_clone_day
                T_min = input.T_break_day(3); %minimum allowable T_clone_day
                RH_max = input.RH_break_max(1)*100; %maximum allowbable RH_clone
                RH_min = input.RH_break_min(3)*100; %minimum allowable RH_clone
            else %lights off
                T_i = input.T_break_night(scenario);
                T_max = input.T_break_night(1); %maximum allowable T_clone_night
                T_min = input.T_break_night(3); %minimum allowable T_clone_night
                RH_max = input.RH_break_max(1)*100; %maximum allowable RH_clone
                RH_min = input.RH_break_min(3)*100; %minimum allowable RH_clone
            end
                %MAX AND MIN ABSOLUTE HUMIDITY
                [~,w_max,~,h_setpoint_max,~,~,~] = Psychrometricsnew ('Tdb',T_max,'phi',RH_max,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                [~,w_min,~,h_setpoint_min,~,~,~] = Psychrometricsnew ('Tdb',T_min,'phi',RH_min,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                
                if Q_lights(k,n)~=0
                    Q_light_load(k,n) = Q_lights(k,n)*A_g(stage); %Watts
%                     CO2(k,i) = (CO2_flower_conc-CO2_atmos)*A_g(stage)*H*N/(1E6*specific_v_CO2); %kg CO2/hr
                else
                    Q_light_load(k,n) = 0;
                end
                
                 %HVAC, ALWAYS ON BASED ON AIR CHANGES
                if w_outside(n)>w_max %Dehumidification and re-heat
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_break_mean(2)*100,'Pamb',Pamb(n));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid(k,n) = mass_flow_air(stage)*((h_outside(n)-h_sat)-cp_water*T_sat*(w_outside(n)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp(k,n) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/Nth_heat;
                    HVAC_dehumid_heat(k,n) = HVAC_dehumid(k,n) + HVAC_heat_temp(k,n);
                elseif w_outside(n)<w_max && w_outside(n)>w_min %Simple Heating
                    if RH(n)>RH_max && T_o(n)<T_max
                        if T_o(n)<T_max && T_o(n)>T_i
                            [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,n) = mass_flow_air(stage)*(h_heat_max-h_outside(n))/Nth_heat;
                        elseif T_o(n)<=T_i && T_o(n)>T_min
                            [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_i,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,n) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(n))/Nth_heat;
                        elseif T_o(n)<=T_min
                            [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                            HVAC_heating(k,n) = mass_flow_air(stage)*(h_humheat_temp-h_outside(n))/Nth_heat;
                        end
                    elseif RH(n)<=RH_max && T_o(n)<T_min
                        [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_i,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_heating(k,n) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(n))/Nth_heat;
                        
                    elseif RH(n)<=RH_min && T_o(n)>T_max %SIMPLE COOLING!!!!
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,n) = mass_flow_air(stage)*(h_outside(n)-h_heat_max)/COP_chiller;
                    elseif RH(n)<=RH_min && T_o(n)<=T_max
                        [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                        HVAC_cooling(k,n) = mass_flow_air(stage)*(h_outside(n)-h_humheat_temp)/COP_chiller;
                    elseif RH(n)>RH_min && T_o(n)>T_max
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,n) = mass_flow_air(stage)*(h_outside(n)-h_heat_max)/COP_chiller;
                    end                     
                elseif w_outside(n)<w_min && T_o(n)<T_min %Heating & Humidification
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_hh_heat_1(k,n) = mass_flow_air(stage)*(h_humheat_temp-h_outside(n))/Nth_heat;
                    %HVAC_hh_heat_2(k,n) = mass_flow_air(stage)*(h_setpoint_min(k,n)-h_humheat_temp(k,n))/Nth_heat;
                    HVAC_hh_vap(k,n) = mass_flow_air(stage)*(w_min-w_outside(n))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %If negative, then heating, shouldn't be though
                    HVAC_Hum_heat(k,n) = HVAC_hh_heat_1(k,n) + HVAC_hh_vap(k,n);
                elseif T_min<T_o(n) && T_max>T_o(n) %Isothermal Humidification
                    if w_outside(n)<w_min %&& RH(n)<RH_min(n) 
                    HVAC_humid(k,n) = mass_flow_air(stage)*(w_min-w_outside(n))*(h_water_vap_100-h_water_liq_20)/Nth_heat;
                    else
                    test = test; %shouldn't ever be in this zone, just a test
                    end               
                elseif w_outside(n)<w_min && T_o(n)>T_max
                    [~,w_hum,~,h_hum,~,~,~] = Psychrometricsnew ('phi',input.RH_break_mean(2)*100,'Tdb',T_o(n),'Pamb',Pamb(n)); %Enthalphy at outside temp and RH setpoint for humidification
                    [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                    HVAC_humid_temp(k,n) = mass_flow_air(stage)*(w_min-w_outside(n))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %Isothermal Humidification
                    HVAC_cool_temp(k,n) = mass_flow_air(stage)*(h_hum-h_heat_max)/COP_chiller; %Simple Cooling, constant w
                    HVAC_hum_cool(k,n) = HVAC_humid_temp(k,n) + HVAC_cool_temp(k,n);                    
                end
                
                %AT END OF HVAC, GET NEW TEMP AND RH, USE FOR TEMPS AND W'S
                %NEEDED FOR CALCULATING T_FINAL AND W_FINAL
                
                %FIND INITIAL GUESS TEMPERATURE AT END OF HOUR
                T_f_HVAC(k,n+1) = (Q_light_load(k,n)+U*SA(stage)*(T_o(n)+273)+cp_air*mass_stored_air(stage)*(T_f_HVAC(k,n)+273)+...
                    cp_air*mass_flow_air(stage)*(T_min+273))/(cp_air*mass_stored_air(stage)+U*SA(stage)+cp_air*mass_flow_air(stage)); %temp at "end of hour" or i+1 iteration
                T_f_HVAC(k,n+1) = T_f_HVAC(k,n+1)-273; %convert to celsius %w
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,n+1) = (Q_light_load(k,n)+mass_stored_air(stage)*h_i(k,n)-U*SA(stage)*(T_f_HVAC(k,n+1)-T_o(n))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));          
                               
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,n+1) = (ET(k,n)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,n)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,n+1),'w',w_inside(k,n+1),'Pamb',Pamb(n));  %wmax_new
                
                count = 1;
                while abs(T_new-T_f_HVAC(k,n+1))>tolerance
                T_f_HVAC(k,n+1) = T_new;
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,n+1) = (Q_light_load(k,n)+mass_stored_air(stage)*h_i(k,n)-U*SA(stage)*(T_f_HVAC(k,n+1)-T_o(n))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,n+1) = (ET(k,n)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,n)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,n+1),'w',w_inside(k,n+1),'Pamb',Pamb(n));  %wmax_new
                %T_f_HVAC(i+1) = store/2;
                count = count + 1;
                end
                T_f_HVAC(k,n+1) = T_new; %celcius %CHANGE THIS TO T_f_HVAC(i+1)
 
                
                %AUXILARY DEHUMIDIFICATION
                if w_inside(k,n+1)>=w_max
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_break_mean(2)*100,'Pamb',Pamb(n));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid_2(k,n) = mass_flow_air(stage)*((h_i(k,n+1)-h_sat)-cp_water*T_sat*(w_inside(k,n+1)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp_2(k,n) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/COP_chiller;
                    DH_P(k,n) = HVAC_dehumid_2(k,n) + HVAC_heat_temp_2(k,n);
                    T_f_HVAC(k,n+1) = T_min;
                    
                %AUXILARY AIR CONDITIONING
                elseif w_inside(k,n+1)<w_max && w_inside(k,n+1)>w_min
                    if T_f_HVAC(k,n+1)>T_max %AUXILARY AIR CONDITIONING
                        AC_P(k,n) = (Q_light_load(k,n)-mass_stored_air(stage)*cp_air*(T_max-T_f_HVAC(k,n+1))-U*SA(stage)*(T_max-T_o(n)))/COP_chiller;
                        T_f_HVAC(k,n+1) = T_max;   
                    end
                %AUXILARY HEATING
                elseif T_f_HVAC(k,n+1)<T_min
                        HEAT_P(k,n) = -(Q_light_load(k,n)-mass_stored_air(stage)*cp_air*(T_min-T_f_HVAC(k,n+1))-U*SA(stage)*(T_min-T_o(n)));
                        T_f_HVAC(k,n+1) = T_min;
                end 
            HVAC_P(k,n) = HVAC_dehumid_heat(k,n) + HVAC_heating(k,n) + HVAC_Hum_heat(k,n) + HVAC_humid(k,n) + HVAC_cooling(k,n) + HVAC_hum_cool(k,n);
            Climate_P(k,n) = HVAC_P(k,n) + AC_P(k,n) + DH_P(k,n);
            end
        end
  end
end
%  
for k = 2 %VEGETATIVE
%SETTING INITIAL CONDITIONS INSIDE [Tdb, w, phi, h, Tdp, v, Twb]
T_i = T_veg_day;
T_f_HVAC(1) = T_veg_day;
T_f_AC(1) = T_veg_day;
RH_sat = 100; %RH = 100 at fully saturated, this is for dehumidification calculations
[~,w_inside(1),~,h_i(1),~,~,~] = Psychrometricsnew ('tdb',T_i,'phi',input.RH_veg_max(2)*100,'Pamb',avePamb); 
  for m = 1:season_count
    for j = 1:i_count_veg
 
            stage = 2;
            i = j+((m-2)*i_count_break + (m-1)*i_count_flower)-i_count_veg;           
            if 1 <= i && i <= 8760
           % scaler_veg(i) = j/i_count_veg;
            
            if Time(i) == 24
                 water(k,i) = water_rate*plant_count;%plant_area*A_g(stage);%*scaler_veg(i);%*scaler(i)+water(i_count_veg-24)+water(i_count_veg-25); %BECAUSE THE ROUNDING ERROR WITH i %kg/hr
            end
            
            if Time(i)<=L_veg_hours %lights on
                Q_lights(k,i) = L_veg_W;  %will be zero when Time(i)>L_veg_hours
                T_i = input.T_veg_day(scenario); %setpoint
                T_max = input.T_veg_day(1); %maximum allowable T_veg_day
                T_min = input.T_veg_day(3); %minimum allowable T_veg_day
                RH_max = input.RH_veg_max(1)*100; %maximum allowbable RH_veg
                RH_min = input.RH_veg_min(3)*100; %minimum allowable RH_veg
            else %lights off
                T_i = input.T_veg_night(scenario);
                T_max = input.T_veg_night(1); %maximum allowable T_veg_night
                T_min= input.T_veg_night(3); %minimum allowable T_veg_night
                RH_max = input.RH_veg_max(1)*100; %maximum allowable RH_veg
                RH_min = input.RH_veg_min(3)*100; %minimum allowable RH_veg
            end
                %MAX AND MIN ABSOLUTE HUMIDITY
                [~,w_max,~,h_setpoint_max,~,~,~] = Psychrometricsnew ('Tdb',T_max,'phi',RH_max,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                [~,w_min,~,h_setpoint_min,~,~,~] = Psychrometricsnew ('Tdb',T_min,'phi',RH_min,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                
                if Q_lights(k,i)~=0
                    Q_light_load(k,i) = Q_lights(k,i)*A_g(stage); %Watts
                    CO2(k,i) = (CO2_veg_conc-CO2_atmos)*A_g(stage)*H*N/(1E6*specific_v_CO2*A_g_use); %kg CO2/hr
                else
                    Q_light_load(k,i) = 0;
                end
                                
                
                %HVAC, ALWAYS ON BASED ON AIR CHANGES
                if w_outside(i)>w_max %Dehumidification and re-heat
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_veg_mean(2)*100,'Pamb',Pamb(i));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid(k,i) = mass_flow_air(stage)*((h_outside(i)-h_sat)-cp_water*T_sat*(w_outside(i)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp(k,i) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/Nth_heat;
                    HVAC_dehumid_heat(k,i) = HVAC_dehumid(k,i) + HVAC_heat_temp(k,i);
                elseif w_outside(i)<w_max && w_outside(i)>w_min %Simple Heating
                    if RH(i)>RH_max && T_o(i)<T_max
                        if T_o(i)<T_max && T_o(i)>T_i
                            [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,i) = mass_flow_air(stage)*(h_heat_max-h_outside(i))/Nth_heat;
                        elseif T_o(i)<=T_i && T_o(i)>T_min
                            [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_i,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,i) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(i))/Nth_heat;
                        elseif T_o(i)<=T_min
                            [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                            HVAC_heating(k,i) = mass_flow_air(stage)*(h_humheat_temp-h_outside(i))/Nth_heat;
                        end
                    elseif RH(i)<=RH_max && T_o(i)<T_min
                        [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_i,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_heating(k,i) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(i))/Nth_heat;
                        
                    elseif RH(i)<=RH_min && T_o(i)>T_max %SIMPLE COOLING!!!!
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,i) = mass_flow_air(stage)*(h_outside(i)-h_heat_max)/COP_chiller;
                    elseif RH(i)<=RH_min && T_o(i)<=T_max
                        [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                        HVAC_cooling(k,i) = mass_flow_air(stage)*(h_outside(i)-h_humheat_temp)/COP_chiller;
                    elseif RH(i)>RH_min && T_o(i)>T_max
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,i) = mass_flow_air(stage)*(h_outside(i)-h_heat_max)/COP_chiller;
                    end                     
                elseif w_outside(i)<w_min && T_o(i)<T_min %Heating & Humidification
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_hh_heat_1(k,i) = mass_flow_air(stage)*(h_humheat_temp-h_outside(i))/Nth_heat;
                    %HVAC_hh_heat_2(k,i) = mass_flow_air(stage)*(h_setpoint_min(k,i)-h_humheat_temp(k,i))/Nth_heat;
                    HVAC_hh_vap(k,i) = mass_flow_air(stage)*(w_min-w_outside(i))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %If negative, then heating, shouldn't be though
                    HVAC_Hum_heat(k,i) = HVAC_hh_heat_1(k,i) + HVAC_hh_vap(k,i);
                elseif T_min<T_o(i) && T_max>T_o(i) %Isothermal Humidification
                    if w_outside(i)<w_min %&& RH(i)<RH_min(i) 
                    HVAC_humid(k,i) = mass_flow_air(stage)*(w_min-w_outside(i))*(h_water_vap_100-h_water_liq_20)/Nth_heat;
                    else
                    test = test; %shouldn't ever be in this zone, just a test
                    end               
                elseif w_outside(i)<w_min && T_o(i)>T_max
                    [~,w_hum,~,h_hum,~,~,~] = Psychrometricsnew ('phi',input.RH_veg_mean(2)*100,'Tdb',T_o(i),'Pamb',Pamb(i)); %Enthalphy at outside temp and RH setpoint for humidification
                    [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                    HVAC_humid_temp(k,i) = mass_flow_air(stage)*(w_min-w_outside(i))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %Isothermal Humidification
                    HVAC_cool_temp(k,i) = mass_flow_air(stage)*(h_hum-h_heat_max)/COP_chiller; %Simple Cooling, constant w
                    HVAC_hum_cool(k,i) = HVAC_humid_temp(k,i) + HVAC_cool_temp(k,i);                    
                end
 
                
                %AT END OF HVAC, GET NEW TEMP AND RH, USE FOR TEMPS AND W'S
                %NEEDED FOR CALCULATING T_FINAL AND W_FINAL
                
                %CALCULATE PLANT MOISTURE VAPOR RELEASED
                if Q_lights(k,i) ~=0
                ET(k,i) = (0.00006*Q_lights(k,i)+0.0004)*4;%*scaler_veg(i); %kg H2O/m^2-hr
                else
                    ET(k,i) = (0.00006*L_veg_W+0.0004)*4*0.3;%scaler_veg(i)*.3;%+ET(i_count_veg-1); %30 of daytime moisture released at night
                end
                %ET(i) = (ET_no_scaler(i)-ET_no_scaler(i)*scaler(i))/(i_count_flower-i_count_veg)+ET(i_count_veg-L_veg_hours); %kg H2O/m^2-hr
                
                
                %AT END OF HVAC, GET NEW TEMP AND RH, USE FOR TEMPS AND W'S
                %NEEDED FOR CALCULATING T_FINAL AND W_FINAL
                               
                %FIND INITIAL GUESS TEMPERATURE AT END OF HOUR
                T_f_HVAC(k,i+1) = (Q_light_load(k,i)+U*SA(stage)*(T_o(i)+273)+cp_air*mass_stored_air(stage)*(T_f_HVAC(k,i)+273)+...
                    cp_air*mass_flow_air(stage)*(T_min+273))/(cp_air*mass_stored_air(stage)+U*SA(stage)+cp_air*mass_flow_air(stage)); %temp at "end of hour" or i+1 iteration
                T_f_HVAC(k,i+1) = T_f_HVAC(k,i+1)-273; %convert to celsius %w
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,i+1) = (Q_light_load(k,i)+mass_stored_air(stage)*h_i(k,i)-U*SA(stage)*(T_f_HVAC(k,i+1)-T_o(i))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));          
                               
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,i+1) = (ET(k,i)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,i)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,i+1),'w',w_inside(k,i+1),'Pamb',Pamb(i));  %wmax_new
                
                count = 1;
                while abs(T_new-T_f_HVAC(k,i+1))>tolerance
                T_f_HVAC(k,i+1) = T_new;
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,i+1) = (Q_light_load(k,i)+mass_stored_air(stage)*h_i(k,i)-U*SA(stage)*(T_f_HVAC(k,i+1)-T_o(i))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,i+1) = (ET(k,i)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,i)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,i+1),'w',w_inside(k,i+1),'Pamb',Pamb(i));  %wmax_new
                %T_f_HVAC(i+1) = store/2;
                count = count + 1;
                end
                T_f_HVAC(k,i+1) = T_new; %celcius %CHANGE THIS TO T_f_HVAC(i+1)
 
                
               %AUXILARY DEHUMIDIFICATION
                if w_inside(k,i+1)>=w_max
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_veg_mean(2)*100,'Pamb',Pamb(i));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid_2(k,i) = mass_flow_air(stage)*((h_i(k,i+1)-h_sat)-cp_water*T_sat*(w_inside(k,i+1)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp_2(k,i) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/COP_chiller;
                    DH_P(k,i) = HVAC_dehumid_2(k,i) + HVAC_heat_temp_2(k,i);
                    T_f_HVAC(k,i+1) = T_min;
                    
                %AUXILARY AIR CONDITIONING
                elseif w_inside(k,i+1)<w_max && w_inside(k,i+1)>w_min
                    if T_f_HVAC(k,i+1)>T_max %AUXILARY AIR CONDITIONING
                        AC_P(k,i) = (Q_light_load(k,i)-mass_stored_air(stage)*cp_air*(T_max-T_f_HVAC(k,i+1))-U*SA(stage)*(T_max-T_o(i)))/COP_chiller;
                        T_f_HVAC(k,i+1) = T_max;   
                    end
                %AUXILARY HEATING
                elseif T_f_HVAC(k,i+1)<T_min
                        HEAT_P(k,i) = -(Q_light_load(k,i)-mass_stored_air(stage)*cp_air*(T_min-T_f_HVAC(k,i+1))-U*SA(stage)*(T_min-T_o(i)));
                        T_f_HVAC(k,i+1) = T_min;
                end 
        HVAC_P(k,i) = HVAC_dehumid_heat(k,i) + HVAC_heating(k,i) + HVAC_Hum_heat(k,i) + HVAC_humid(k,i) + HVAC_cooling(k,i) + HVAC_hum_cool(k,i);
        Climate_P(k,i) = HVAC_P(k,i) + AC_P(k,i) + DH_P(k,i);
            end
    end
%         elseif (j*i_count_flower+1)<=i && i<=(j*i_count_flower+1+i_count_break)% BREAK: NO PLANTS
        for n = (i+1):(((m-1)*i_count_break+(m)*i_count_flower)-i_count_veg)
            if 1 <= n && n <= 8760
            stage = 2;
            
            if Time(n)<=L_break_hours %lights on
                Q_lights(k,n) = L_break_W;  %will be zero when Time(i)>L_break_hours
                T_i = input.T_break_day(scenario); %setpoint
                T_max = input.T_break_day(1); %maximum allowable T_break_day
                T_min = input.T_break_day(3); %minimum allowable T_break_day
                RH_max = input.RH_break_max(1)*100; %maximum allowbable RH_break
                RH_min = input.RH_break_min(3)*100; %minimum allowable RH_break
            else %lights off
                T_i = input.T_break_night(scenario);
                T_max = input.T_break_night(1); %maximum allowable T_break_night
                T_min = input.T_break_night(3); %minimum allowable T_break_night
                RH_max = input.RH_break_max(1)*100; %maximum allowable RH_break
                RH_min = input.RH_break_min(3)*100; %minimum allowable RH_break
            end
                %MAX AND MIN ABSOLUTE HUMIDITY
                [~,w_max,~,h_setpoint_max,~,~,~] = Psychrometricsnew ('Tdb',T_max,'phi',RH_max,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                [~,w_min,~,h_setpoint_min,~,~,~] = Psychrometricsnew ('Tdb',T_min,'phi',RH_min,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                
                if Q_lights(k,n)~=0
                    Q_light_load(k,n) = Q_lights(k,n)*A_g(stage); %Watts
%                     CO2(k,i) = (CO2_veg_conc-CO2_atmos)*A_g(stage)*H*N/(1E6*specific_v_CO2); %kg CO2/hr
                else
                    Q_light_load(k,n) = 0;
                end
                
                %HVAC, ALWAYS ON BASED ON AIR CHANGES
                if w_outside(n)>w_max %Dehumidification and re-heat
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_break_mean(2)*100,'Pamb',Pamb(n));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid(k,n) = mass_flow_air(stage)*((h_outside(n)-h_sat)-cp_water*T_sat*(w_outside(n)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp(k,n) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/Nth_heat;
                    HVAC_dehumid_heat(k,n) = HVAC_dehumid(k,n) + HVAC_heat_temp(k,n);
                elseif w_outside(n)<w_max && w_outside(n)>w_min %Simple Heating
                    if RH(n)>RH_max && T_o(n)<T_max
                        if T_o(n)<T_max && T_o(n)>T_i
                            [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,n) = mass_flow_air(stage)*(h_heat_max-h_outside(n))/Nth_heat;
                        elseif T_o(n)<=T_i && T_o(n)>T_min
                            [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_i,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,n) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(n))/Nth_heat;
                        elseif T_o(n)<=T_min
                            [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                            HVAC_heating(k,n) = mass_flow_air(stage)*(h_humheat_temp-h_outside(n))/Nth_heat;
                        end
                    elseif RH(n)<=RH_max && T_o(n)<T_min
                        [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_i,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_heating(k,n) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(n))/Nth_heat;
                        
                    elseif RH(n)<=RH_min && T_o(n)>T_max %SIMPLE COOLING!!!!
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,n) = mass_flow_air(stage)*(h_outside(n)-h_heat_max)/COP_chiller;
                    elseif RH(n)<=RH_min && T_o(n)<=T_max
                        [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                        HVAC_cooling(k,n) = mass_flow_air(stage)*(h_outside(n)-h_humheat_temp)/COP_chiller;
                    elseif RH(n)>RH_min && T_o(n)>T_max
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,n) = mass_flow_air(stage)*(h_outside(n)-h_heat_max)/COP_chiller;
                    end                     
                elseif w_outside(n)<w_min && T_o(n)<T_min %Heating & Humidification
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_hh_heat_1(k,n) = mass_flow_air(stage)*(h_humheat_temp-h_outside(n))/Nth_heat;
                    %HVAC_hh_heat_2(k,n) = mass_flow_air(stage)*(h_setpoint_min(k,n)-h_humheat_temp(k,n))/Nth_heat;
                    HVAC_hh_vap(k,n) = mass_flow_air(stage)*(w_min-w_outside(n))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %If negative, then heating, shouldn't be though
                    HVAC_Hum_heat(k,n) = HVAC_hh_heat_1(k,n) + HVAC_hh_vap(k,n);
                elseif T_min<T_o(n) && T_max>T_o(n) %Isothermal Humidification
                    if w_outside(n)<w_min %&& RH(n)<RH_min(n) 
                    HVAC_humid(k,n) = mass_flow_air(stage)*(w_min-w_outside(n))*(h_water_vap_100-h_water_liq_20)/Nth_heat;
                    else
                    test = test; %shouldn't ever be in this zone, just a test
                    end               
                elseif w_outside(n)<w_min && T_o(n)>T_max
                    [~,w_hum,~,h_hum,~,~,~] = Psychrometricsnew ('phi',input.RH_break_mean(2)*100,'Tdb',T_o(n),'Pamb',Pamb(n)); %Enthalphy at outside temp and RH setpoint for humidification
                    [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                    HVAC_humid_temp(k,n) = mass_flow_air(stage)*(w_min-w_outside(n))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %Isothermal Humidification
                    HVAC_cool_temp(k,n) = mass_flow_air(stage)*(h_hum-h_heat_max)/COP_chiller; %Simple Cooling, constant w
                    HVAC_hum_cool(k,n) = HVAC_humid_temp(k,n) + HVAC_cool_temp(k,n);                    
                end
                
                %AT END OF HVAC, GET NEW TEMP AND RH, USE FOR TEMPS AND W'S
                %NEEDED FOR CALCULATING T_FINAL AND W_FINAL
                
                %FIND INITIAL GUESS TEMPERATURE AT END OF HOUR
                T_f_HVAC(k,n+1) = (Q_light_load(k,n)+U*SA(stage)*(T_o(n)+273)+cp_air*mass_stored_air(stage)*(T_f_HVAC(k,n)+273)+...
                    cp_air*mass_flow_air(stage)*(T_min+273))/(cp_air*mass_stored_air(stage)+U*SA(stage)+cp_air*mass_flow_air(stage)); %temp at "end of hour" or i+1 iteration
                T_f_HVAC(k,n+1) = T_f_HVAC(k,n+1)-273; %convert to celsius %w
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,n+1) = (Q_light_load(k,n)+mass_stored_air(stage)*h_i(k,n)-U*SA(stage)*(T_f_HVAC(k,n+1)-T_o(n))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));          
                               
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,n+1) = (ET(k,n)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,n)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,n+1),'w',w_inside(k,n+1),'Pamb',Pamb(n));  %wmax_new
                
                count = 1;
                while abs(T_new-T_f_HVAC(k,n+1))>tolerance
                T_f_HVAC(k,n+1) = T_new;
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,n+1) = (Q_light_load(k,n)+mass_stored_air(stage)*h_i(k,n)-U*SA(stage)*(T_f_HVAC(k,n+1)-T_o(n))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,n+1) = (ET(k,n)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,n)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,n+1),'w',w_inside(k,n+1),'Pamb',Pamb(n));  %wmax_new
                %T_f_HVAC(i+1) = store/2;
                count = count + 1;
                end
                T_f_HVAC(k,n+1) = T_new; %celcius %CHANGE THIS TO T_f_HVAC(i+1)
 
                
                %AUXILARY DEHUMIDIFICATION
                if w_inside(k,n+1)>=w_max
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_break_mean(2)*100,'Pamb',Pamb(n));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid_2(k,n) = mass_flow_air(stage)*((h_i(k,n+1)-h_sat)-cp_water*T_sat*(w_inside(k,n+1)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp_2(k,n) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/COP_chiller;
                    DH_P(k,n) = HVAC_dehumid_2(k,n) + HVAC_heat_temp_2(k,n);
                    T_f_HVAC(k,n+1) = T_min;
                    
                %AUXILARY AIR CONDITIONING
                elseif w_inside(k,n+1)<w_max && w_inside(k,n+1)>w_min
                    if T_f_HVAC(k,n+1)>T_max %AUXILARY AIR CONDITIONING
                        AC_P(k,n) = (Q_light_load(k,n)-mass_stored_air(stage)*cp_air*(T_max-T_f_HVAC(k,n+1))-U*SA(stage)*(T_max-T_o(n)))/COP_chiller;
                        T_f_HVAC(k,n+1) = T_max;   
                    end
                %AUXILARY HEATING
                elseif T_f_HVAC(k,n+1)<T_min
                        HEAT_P(k,n) = -(Q_light_load(k,n)-mass_stored_air(stage)*cp_air*(T_min-T_f_HVAC(k,n+1))-U*SA(stage)*(T_min-T_o(n)));
                        T_f_HVAC(k,n+1) = T_min;
                end 
            HVAC_P(k,n) = HVAC_dehumid_heat(k,n) + HVAC_heating(k,n) + HVAC_Hum_heat(k,n) + HVAC_humid(k,n) + HVAC_cooling(k,n) + HVAC_hum_cool(k,n);
            Climate_P(k,n) = HVAC_P(k,n) + AC_P(k,n) + DH_P(k,n);
            end
        end
  end
end
 
for k = 3 %FLOWERING
%SETTING INITIAL CONDITIONS INSIDE [Tdb, w, phi, h, Tdp, v, Twb]
T_i = T_flower_day;
T_f_HVAC(1) = T_flower_day;
T_f_AC(1) = T_flower_day;
RH_sat = 100; %RH = 100 at fully saturated, this is for dehumidification calculations
[~,w_inside(1),~,h_i(1),~,~,~] = Psychrometricsnew ('tdb',T_i,'phi',input.RH_flower_max(2)*100,'Pamb',avePamb); 
 
    for m = 1:season_count
        for j = 1:i_count_flower
 
            stage = 3;
            i = j+(m-1)*(i_count_flower+i_count_break);
            if 1 <= i && i <= 8760
            %scaler_flower(i) = j/i_count_flower;
            
            if Time(i) == 24
                 water(k,i) = water_rate*plant_count;%plant_area*A_g(stage);%*scaler_flower(i);%*scaler(i)+water(i_count_veg-24)+water(i_count_veg-25); %BECAUSE THE ROUNDING ERROR WITH i %kg/hr
            end
            
            if Time(i)<=L_flower_hours %lights on
                Q_lights(k,i) = L_flower_W;  %will be zero when Time(i)>L_clone_hours
                T_i = input.T_flower_day(scenario); %setpoint
                T_max = input.T_flower_day(1); %maximum allowable T_clone_day
                T_min = input.T_flower_day(3); %minimum allowable T_clone_day
                RH_max = input.RH_flower_max(1)*100; %maximum allowbable RH_clone
                RH_min = input.RH_flower_min(3)*100; %minimum allowable RH_clone
            else %lights off
                T_i = input.T_flower_night(scenario);
                T_max = input.T_flower_night(1); %maximum allowable T_clone_night
                T_min = input.T_flower_night(3); %minimum allowable T_clone_night
                RH_max = input.RH_flower_max(1)*100; %maximum allowable RH_clone
                RH_min = input.RH_flower_min(3)*100; %minimum allowable RH_clone
            end
                %MAX AND MIN ABSOLUTE HUMIDITY
                [~,w_max,~,h_setpoint_max,~,~,~] = Psychrometricsnew ('Tdb',T_max,'phi',RH_max,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                [~,w_min,~,h_setpoint_min,~,~,~] = Psychrometricsnew ('Tdb',T_min,'phi',RH_min,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                
                if Q_lights(k,i)~=0
                    Q_light_load(k,i) = Q_lights(k,i)*A_g(stage); %Watts
                    CO2(k,i) = (CO2_flower_conc-CO2_atmos)*A_g(stage)*H*N/(1E6*specific_v_CO2*A_g_use); %kg CO2/hr
                else
                    Q_light_load(k,i) = 0;
                end
                
                %HVAC, ALWAYS ON BASED ON AIR CHANGES
                if w_outside(i)>w_max %Dehumidification and re-heat
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_flower_mean(2)*100,'Pamb',Pamb(i));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid(k,i) = mass_flow_air(stage)*((h_outside(i)-h_sat)-cp_water*T_sat*(w_outside(i)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp(k,i) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/Nth_heat;
                    HVAC_dehumid_heat(k,i) = HVAC_dehumid(k,i) + HVAC_heat_temp(k,i);
                elseif w_outside(i)<w_max && w_outside(i)>w_min %Simple Heating
                    if RH(i)>RH_max && T_o(i)<T_max
                        if T_o(i)<T_max && T_o(i)>T_i
                            [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,i) = mass_flow_air(stage)*(h_heat_max-h_outside(i))/Nth_heat;
                        elseif T_o(i)<=T_i && T_o(i)>T_min
                            [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_i,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,i) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(i))/Nth_heat;
                        elseif T_o(i)<=T_min
                            [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                            HVAC_heating(k,i) = mass_flow_air(stage)*(h_humheat_temp-h_outside(i))/Nth_heat;
                        end
                    elseif RH(i)<=RH_max && T_o(i)<T_min
                        [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_i,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_heating(k,i) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(i))/Nth_heat;
                        
                    elseif RH(i)<=RH_min && T_o(i)>T_max %SIMPLE COOLING!!!!
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,i) = mass_flow_air(stage)*(h_outside(i)-h_heat_max)/COP_chiller;
                    elseif RH(i)<=RH_min && T_o(i)<=T_max
                        [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                        HVAC_cooling(k,i) = mass_flow_air(stage)*(h_outside(i)-h_humheat_temp)/COP_chiller;
                    elseif RH(i)>RH_min && T_o(i)>T_max
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,i) = mass_flow_air(stage)*(h_outside(i)-h_heat_max)/COP_chiller;
                    end                     
                elseif w_outside(i)<w_min && T_o(i)<T_min %Heating & Humidification
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_hh_heat_1(k,i) = mass_flow_air(stage)*(h_humheat_temp-h_outside(i))/Nth_heat;
                    %HVAC_hh_heat_2(k,i) = mass_flow_air(stage)*(h_setpoint_min(k,i)-h_humheat_temp(k,i))/Nth_heat;
                    HVAC_hh_vap(k,i) = mass_flow_air(stage)*(w_min-w_outside(i))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %If negative, then heating, shouldn't be though
                    HVAC_Hum_heat(k,i) = HVAC_hh_heat_1(k,i) + HVAC_hh_vap(k,i);
                elseif T_min<T_o(i) && T_max>T_o(i) %Isothermal Humidification
                    if w_outside(i)<w_min %&& RH(i)<RH_min(i) 
                    HVAC_humid(k,i) = mass_flow_air(stage)*(w_min-w_outside(i))*(h_water_vap_100-h_water_liq_20)/Nth_heat;
                    else
                    test = test; %shouldn't ever be in this zone, just a test
                    end               
                elseif w_outside(i)<w_min && T_o(i)>T_max
                    [~,w_hum,~,h_hum,~,~,~] = Psychrometricsnew ('phi',input.RH_flower_mean(2)*100,'Tdb',T_o(i),'Pamb',Pamb(i)); %Enthalphy at outside temp and RH setpoint for humidification
                    [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                    HVAC_humid_temp(k,i) = mass_flow_air(stage)*(w_min-w_outside(i))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %Isothermal Humidification
                    HVAC_cool_temp(k,i) = mass_flow_air(stage)*(h_hum-h_heat_max)/COP_chiller; %Simple Cooling, constant w
                    HVAC_hum_cool(k,i) = HVAC_humid_temp(k,i) + HVAC_cool_temp(k,i);                    
                end
 
                
                %AT END OF HVAC, GET NEW TEMP AND RH, USE FOR TEMPS AND W'S
                %NEEDED FOR CALCULATING T_FINAL AND W_FINAL
                
                %CALCULATE PLANT MOISTURE VAPOR RELEASED
                if Q_lights(k,i) ~=0
                ET(k,i) = (0.0003*Q_lights(k,i)+0.0021)*4;%*scaler_flower(i); %ET_no_scaler
               %ET(i) = ET_no_scaler(i)*scaler(i)+ET(i_count_veg-L_veg_hours);
                else
                    ET(k,i) = (0.0003*L_flower_W+0.0021)*4*0.3;%*scaler_flower(i);%+ET(i_count_veg-1); %30 of daytime moisture released at night
                end
                %ET(i) = (ET_no_scaler(i)-ET_no_scaler(i)*scaler(i))/(i_count_flower-i_count_veg)+ET(i_count_veg-L_veg_hours); %kg H2O/m^2-hr
                                
                %AT END OF HVAC, GET NEW TEMP AND RH, USE FOR TEMPS AND W'S
                %NEEDED FOR CALCULATING T_FINAL AND W_FINAL
                               
                %FIND INITIAL GUESS TEMPERATURE AT END OF HOUR
                T_f_HVAC(k,i+1) = (Q_light_load(k,i)+U*SA(stage)*(T_o(i)+273)+cp_air*mass_stored_air(stage)*(T_f_HVAC(k,i)+273)+...
                    cp_air*mass_flow_air(stage)*(T_min+273))/(cp_air*mass_stored_air(stage)+U*SA(stage)+cp_air*mass_flow_air(stage)); %temp at "end of hour" or i+1 iteration
                T_f_HVAC(k,i+1) = T_f_HVAC(k,i+1)-273; %convert to celsius %w
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,i+1) = (Q_light_load(k,i)+mass_stored_air(stage)*h_i(k,i)-U*SA(stage)*(T_f_HVAC(k,i+1)-T_o(i))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));          
                               
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,i+1) = (ET(k,i)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,i)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,i+1),'w',w_inside(k,i+1),'Pamb',Pamb(i));  %wmax_new
                
                count = 1;
                while abs(T_new-T_f_HVAC(k,i+1))>tolerance
                T_f_HVAC(k,i+1) = T_new;
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,i+1) = (Q_light_load(k,i)+mass_stored_air(stage)*h_i(k,i)-U*SA(stage)*(T_f_HVAC(k,i+1)-T_o(i))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,i+1) = (ET(k,i)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,i)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,i+1),'w',w_inside(k,i+1),'Pamb',Pamb(i));  %wmax_new
                %T_f_HVAC(i+1) = store/2;
                count = count + 1;
                end
                T_f_HVAC(k,i+1) = T_new; %celcius %CHANGE THIS TO T_f_HVAC(i+1)
 
                
               %AUXILARY DEHUMIDIFICATION
                if w_inside(k,i+1)>=w_max
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_flower_mean(2)*100,'Pamb',Pamb(i));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid_2(k,i) = mass_flow_air(stage)*((h_i(k,i+1)-h_sat)-cp_water*T_sat*(w_inside(k,i+1)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp_2(k,i) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/COP_chiller;
                    DH_P(k,i) = HVAC_dehumid_2(k,i) + HVAC_heat_temp_2(k,i);
                    T_f_HVAC(k,i+1) = T_min;
                    
                    %DH_P(i) = (ET(i)*A_g(stage)/3600*h_water-mass_flow_air(stage)*(h_i(i+1)-h_setpoint(i))-mass_stored_air(stage)*(h_i(i+1)-h_i(i)))/COP_chiller;
                elseif w_inside(k,i+1)<w_max && w_inside(k,i+1)>w_min
                    if T_f_HVAC(k,i+1)>T_max %AUXILARY AIR CONDITIONING
                        AC_P(k,i) = (Q_light_load(k,i)-mass_stored_air(stage)*cp_air*(T_max-T_f_HVAC(k,i+1))-U*SA(stage)*(T_max-T_o(i)))/COP_chiller;
                        T_f_HVAC(k,i+1) = T_max;   
                    end
                %AUXILARY HEATING
                elseif T_f_HVAC(k,i+1)<T_min
                        HEAT_P(k,i) = -(Q_light_load(k,i)-mass_stored_air(stage)*cp_air*(T_min-T_f_HVAC(k,i+1))-U*SA(stage)*(T_min-T_o(i)));
                        T_f_HVAC(k,i+1) = T_min;
                end 
 
        HVAC_P(k,i) = HVAC_dehumid_heat(k,i) + HVAC_heating(k,i) + HVAC_Hum_heat(k,i) + HVAC_humid(k,i) + HVAC_cooling(k,i) + HVAC_hum_cool(k,i);
        Climate_P(k,i) = HVAC_P(k,i) + AC_P(k,i) + DH_P(k,i);
            end
        end
%         elseif (j*i_count_flower+1)<=i && i<=(j*i_count_flower+1+i_count_break)% BREAK: NO PLANTS
        for n = (i+1):i+i_count_break
            if 1 <= n && n <= 8760
            stage = 3;       
            
            if Time(n)<=L_break_hours %lights on
                Q_lights(k,n) = L_break_W;  %will be zero when Time(i)>L_clone_hours
                T_i = input.T_break_day(scenario); %setpoint
                T_max = input.T_break_day(1); %maximum allowable T_clone_day
                T_min = input.T_break_day(3); %minimum allowable T_clone_day
                RH_max = input.RH_break_max(1)*100; %maximum allowbable RH_clone
                RH_min = input.RH_break_min(3)*100; %minimum allowable RH_clone
            else %lights off
                T_i = input.T_break_night(scenario);
                T_max = input.T_break_night(1); %maximum allowable T_clone_night
                T_min = input.T_break_night(3); %minimum allowable T_clone_night
                RH_max = input.RH_break_max(1)*100; %maximum allowable RH_clone
                RH_min = input.RH_break_min(3)*100; %minimum allowable RH_clone
            end
                %MAX AND MIN ABSOLUTE HUMIDITY
                [~,w_max,~,h_setpoint_max,~,~,~] = Psychrometricsnew ('Tdb',T_max,'phi',RH_max,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                [~,w_min,~,h_setpoint_min,~,~,~] = Psychrometricsnew ('Tdb',T_min,'phi',RH_min,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                
                if Q_lights(k,n)~=0
                    Q_light_load(k,n) = Q_lights(k,n)*A_g(stage); %Watts
%                     CO2(k,i) = (CO2_flower_conc-CO2_atmos)*A_g(stage)*H*N/(1E6*specific_v_CO2); %kg CO2/hr
                else
                    Q_light_load(k,n) = 0;
                end
                
                %HVAC, ALWAYS ON BASED ON AIR CHANGES
                if w_outside(n)>w_max %Dehumidification and re-heat
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_break_mean(2)*100,'Pamb',Pamb(n));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid(k,n) = mass_flow_air(stage)*((h_outside(n)-h_sat)-cp_water*T_sat*(w_outside(n)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp(k,n) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/Nth_heat;
                    HVAC_dehumid_heat(k,n) = HVAC_dehumid(k,n) + HVAC_heat_temp(k,n);
                elseif w_outside(n)<w_max && w_outside(n)>w_min %Simple Heating
                    if RH(n)>RH_max && T_o(n)<T_max
                        if T_o(n)<T_max && T_o(n)>T_i
                            [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,n) = mass_flow_air(stage)*(h_heat_max-h_outside(n))/Nth_heat;
                        elseif T_o(n)<=T_i && T_o(n)>T_min
                            [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_i,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,n) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(n))/Nth_heat;
                        elseif T_o(n)<=T_min
                            [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                            HVAC_heating(k,n) = mass_flow_air(stage)*(h_humheat_temp-h_outside(n))/Nth_heat;
                        end
                    elseif RH(n)<=RH_max && T_o(n)<T_min
                        [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_i,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_heating(k,n) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(n))/Nth_heat;
                        
                    elseif RH(n)<=RH_min && T_o(n)>T_max %SIMPLE COOLING!!!!
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,n) = mass_flow_air(stage)*(h_outside(n)-h_heat_max)/COP_chiller;
                    elseif RH(n)<=RH_min && T_o(n)<=T_max
                        [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                        HVAC_cooling(k,n) = mass_flow_air(stage)*(h_outside(n)-h_humheat_temp)/COP_chiller;
                    elseif RH(n)>RH_min && T_o(n)>T_max
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,n) = mass_flow_air(stage)*(h_outside(n)-h_heat_max)/COP_chiller;
                    end                     
                elseif w_outside(n)<w_min && T_o(n)<T_min %Heating & Humidification
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_hh_heat_1(k,n) = mass_flow_air(stage)*(h_humheat_temp-h_outside(n))/Nth_heat;
                    %HVAC_hh_heat_2(k,n) = mass_flow_air(stage)*(h_setpoint_min(k,n)-h_humheat_temp(k,n))/Nth_heat;
                    HVAC_hh_vap(k,n) = mass_flow_air(stage)*(w_min-w_outside(n))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %If negative, then heating, shouldn't be though
                    HVAC_Hum_heat(k,n) = HVAC_hh_heat_1(k,n) + HVAC_hh_vap(k,n);
                elseif T_min<T_o(n) && T_max>T_o(n) %Isothermal Humidification
                    if w_outside(n)<w_min %&& RH(n)<RH_min(n) 
                    HVAC_humid(k,n) = mass_flow_air(stage)*(w_min-w_outside(n))*(h_water_vap_100-h_water_liq_20)/Nth_heat;
                    else
                    test = test; %shouldn't ever be in this zone, just a test
                    end               
                elseif w_outside(n)<w_min && T_o(n)>T_max
                    [~,w_hum,~,h_hum,~,~,~] = Psychrometricsnew ('phi',input.RH_break_mean(2)*100,'Tdb',T_o(n),'Pamb',Pamb(n)); %Enthalphy at outside temp and RH setpoint for humidification
                    [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                    HVAC_humid_temp(k,n) = mass_flow_air(stage)*(w_min-w_outside(n))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %Isothermal Humidification
                    HVAC_cool_temp(k,n) = mass_flow_air(stage)*(h_hum-h_heat_max)/COP_chiller; %Simple Cooling, constant w
                    HVAC_hum_cool(k,n) = HVAC_humid_temp(k,n) + HVAC_cool_temp(k,n);                    
                end
                
                %AT END OF HVAC, GET NEW TEMP AND RH, USE FOR TEMPS AND W'S
                %NEEDED FOR CALCULATING T_FINAL AND W_FINAL
                
                %FIND INITIAL GUESS TEMPERATURE AT END OF HOUR
                T_f_HVAC(k,n+1) = (Q_light_load(k,n)+U*SA(stage)*(T_o(n)+273)+cp_air*mass_stored_air(stage)*(T_f_HVAC(k,n)+273)+...
                    cp_air*mass_flow_air(stage)*(T_min+273))/(cp_air*mass_stored_air(stage)+U*SA(stage)+cp_air*mass_flow_air(stage)); %temp at "end of hour" or i+1 iteration
                T_f_HVAC(k,n+1) = T_f_HVAC(k,n+1)-273; %convert to celsius %w
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,n+1) = (Q_light_load(k,n)+mass_stored_air(stage)*h_i(k,n)-U*SA(stage)*(T_f_HVAC(k,n+1)-T_o(n))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));          
                               
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,n+1) = (ET(k,n)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,n)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,n+1),'w',w_inside(k,n+1),'Pamb',Pamb(n));  %wmax_new
                
                count = 1;
                while abs(T_new-T_f_HVAC(k,n+1))>tolerance
                T_f_HVAC(k,n+1) = T_new;
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,n+1) = (Q_light_load(k,n)+mass_stored_air(stage)*h_i(k,n)-U*SA(stage)*(T_f_HVAC(k,n+1)-T_o(n))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,n+1) = (ET(k,n)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,n)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,n+1),'w',w_inside(k,n+1),'Pamb',Pamb(n));  %wmax_new
                %T_f_HVAC(i+1) = store/2;
                count = count + 1;
                end
                T_f_HVAC(k,n+1) = T_new; %celcius %CHANGE THIS TO T_f_HVAC(i+1)
 
                
                %AUXILARY DEHUMIDIFICATION
                if w_inside(k,n+1)>=w_max
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_break_mean(2)*100,'Pamb',Pamb(n));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid_2(k,n) = mass_flow_air(stage)*((h_i(k,n+1)-h_sat)-cp_water*T_sat*(w_inside(k,n+1)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp_2(k,n) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/COP_chiller;
                    DH_P(k,n) = HVAC_dehumid_2(k,n) + HVAC_heat_temp_2(k,n);
                    T_f_HVAC(k,n+1) = T_min;
                    
                %AUXILARY AIR CONDITIONING
                elseif w_inside(k,n+1)<w_max && w_inside(k,n+1)>w_min
                    if T_f_HVAC(k,n+1)>T_max %AUXILARY AIR CONDITIONING
                        AC_P(k,n) = (Q_light_load(k,n)-mass_stored_air(stage)*cp_air*(T_max-T_f_HVAC(k,n+1))-U*SA(stage)*(T_max-T_o(n)))/COP_chiller;
                        T_f_HVAC(k,n+1) = T_max;   
                    end
                %AUXILARY HEATING
                elseif T_f_HVAC(k,n+1)<T_min
                        HEAT_P(k,n) = -(Q_light_load(k,n)-mass_stored_air(stage)*cp_air*(T_min-T_f_HVAC(k,n+1))-U*SA(stage)*(T_min-T_o(n)));
                        T_f_HVAC(k,n+1) = T_min;
                end 
            HVAC_P(k,n) = HVAC_dehumid_heat(k,n) + HVAC_heating(k,n) + HVAC_Hum_heat(k,n) + HVAC_humid(k,n) + HVAC_cooling(k,n) + HVAC_hum_cool(k,n);
            Climate_P(k,n) = HVAC_P(k,n) + AC_P(k,n) + DH_P(k,n);
            end
        end
  end
end
%         
for k = 4 %CURE
%SETTING INITIAL CONDITIONS INSIDE [Tdb, w, phi, h, Tdp, v, Twb]
T_i = T_cure_day;
T_f_HVAC(1) = T_cure_day;
T_f_AC(1) = T_cure_day;
RH_sat = 100; %RH = 100 at fully saturated, this is for dehumidification calculations
[~,w_inside(1),~,h_i(1),~,~,~] = Psychrometricsnew ('tdb',T_i(1),'phi',input.RH_cure_max(2)*100,'Pamb',avePamb); 
  for m = 1:season_count
    for j = 1:i_count_cure
 
            stage = 4;
            i = j+(m-1)*(i_count_flower+i_count_break);          
            if 1 <= i && i <= 8760
           %
           %scaler_cure(i) = j/i_count_cure;
            
                        
            if Time(i)<=L_cure_hours %lights on
                Q_lights(k,i) = L_cure_W;  %will be zero when Time(i)>L_clone_hours
                T_i = input.T_cure_day(scenario); %setpoint
                T_max = input.T_cure_day(1); %maximum allowable T_clone_day
                T_min = input.T_cure_day(3); %minimum allowable T_clone_day
                RH_max = input.RH_cure_max(1)*100; %maximum allowbable RH_clone
                RH_min = input.RH_cure_min(3)*100; %minimum allowable RH_clone
            else %lights off
                T_i = input.T_cure_night(scenario);
                T_max = input.T_cure_night(1); %maximum allowable T_clone_night
                T_min = input.T_cure_night(3); %minimum allowable T_clone_night
                RH_max = input.RH_cure_max(1)*100; %maximum allowable RH_clone
                RH_min = input.RH_cure_min(3)*100; %minimum allowable RH_clone
            end
                %MAX AND MIN ABSOLUTE HUMIDITY
                [~,w_max,~,h_setpoint_max,~,~,~] = Psychrometricsnew ('Tdb',T_max,'phi',RH_max,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                [~,w_min,~,h_setpoint_min,~,~,~] = Psychrometricsnew ('Tdb',T_min,'phi',RH_min,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                
                if Q_lights(k,i)~=0
                    Q_light_load(k,i) = Q_lights(k,i)*A_g(stage); %Watts
                else
                    Q_light_load(k,i) = 0;
                end
                
                
                %HVAC, ALWAYS ON BASED ON AIR CHANGES
                if w_outside(i)>w_max %Dehumidification and re-heat
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_cure_mean(2)*100,'Pamb',Pamb(i));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid(k,i) = mass_flow_air(stage)*((h_outside(i)-h_sat)-cp_water*T_sat*(w_outside(i)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp(k,i) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/Nth_heat;
                    HVAC_dehumid_heat(k,i) = HVAC_dehumid(k,i) + HVAC_heat_temp(k,i);
                elseif w_outside(i)<w_max && w_outside(i)>w_min %Simple Heating
                    if RH(i)>RH_max && T_o(i)<T_max
                        if T_o(i)<T_max && T_o(i)>T_i
                            [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,i) = mass_flow_air(stage)*(h_heat_max-h_outside(i))/Nth_heat;
                        elseif T_o(i)<=T_i && T_o(i)>T_min
                            [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_i,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,i) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(i))/Nth_heat;
                        elseif T_o(i)<=T_min
                            [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                            HVAC_heating(k,i) = mass_flow_air(stage)*(h_humheat_temp-h_outside(i))/Nth_heat;
                        end
                    elseif RH(i)<=RH_max && T_o(i)<T_min
                        [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_i,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_heating(k,i) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(i))/Nth_heat;
                        
                    elseif RH(i)<=RH_min && T_o(i)>T_max %SIMPLE COOLING!!!!
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,i) = mass_flow_air(stage)*(h_outside(i)-h_heat_max)/COP_chiller;
                    elseif RH(i)<=RH_min && T_o(i)<=T_max
                        [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                        HVAC_cooling(k,i) = mass_flow_air(stage)*(h_outside(i)-h_humheat_temp)/COP_chiller;
                    elseif RH(i)>RH_min && T_o(i)>T_max
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,i) = mass_flow_air(stage)*(h_outside(i)-h_heat_max)/COP_chiller;
                    end                     
                elseif w_outside(i)<w_min && T_o(i)<T_min %Heating & Humidification
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_hh_heat_1(k,i) = mass_flow_air(stage)*(h_humheat_temp-h_outside(i))/Nth_heat;
                    %HVAC_hh_heat_2(k,i) = mass_flow_air(stage)*(h_setpoint_min(k,i)-h_humheat_temp(k,i))/Nth_heat;
                    HVAC_hh_vap(k,i) = mass_flow_air(stage)*(w_min-w_outside(i))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %If negative, then heating, shouldn't be though
                    HVAC_Hum_heat(k,i) = HVAC_hh_heat_1(k,i) + HVAC_hh_vap(k,i);
                elseif T_min<T_o(i) && T_max>T_o(i) %Isothermal Humidification
                    if w_outside(i)<w_min %&& RH(i)<RH_min(i) 
                    HVAC_humid(k,i) = mass_flow_air(stage)*(w_min-w_outside(i))*(h_water_vap_100-h_water_liq_20)/Nth_heat;
                    else
                    test = test; %shouldn't ever be in this zone, just a test
                    end               
                elseif w_outside(i)<w_min && T_o(i)>T_max
                    [~,w_hum,~,h_hum,~,~,~] = Psychrometricsnew ('phi',input.RH_cure_mean(2)*100,'Tdb',T_o(i),'Pamb',Pamb(i)); %Enthalphy at outside temp and RH setpoint for humidification
                    [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(i),'Tdb',T_max,'Pamb',Pamb(i)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                    HVAC_humid_temp(k,i) = mass_flow_air(stage)*(w_min-w_outside(i))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %Isothermal Humidification
                    HVAC_cool_temp(k,i) = mass_flow_air(stage)*(h_hum-h_heat_max)/COP_chiller; %Simple Cooling, constant w
                    HVAC_hum_cool(k,i) = HVAC_humid_temp(k,i) + HVAC_cool_temp(k,i);                    
                end
 
%                 %CALCULATE PLANT MOISTURE VAPOR RELEASED
                ET(k,i) = (0.0003*Q_lights(k,i)+0.0021)*4; %kg H2O/m^2-hr
                
                                %AT END OF HVAC, GET NEW TEMP AND RH, USE FOR TEMPS AND W'S
                %NEEDED FOR CALCULATING T_FINAL AND W_FINAL
                               
                %FIND INITIAL GUESS TEMPERATURE AT END OF HOUR
                T_f_HVAC(k,i+1) = (Q_light_load(k,i)+U*SA(stage)*(T_o(i)+273)+cp_air*mass_stored_air(stage)*(T_f_HVAC(k,i)+273)+...
                    cp_air*mass_flow_air(stage)*(T_min+273))/(cp_air*mass_stored_air(stage)+U*SA(stage)+cp_air*mass_flow_air(stage)); %temp at "end of hour" or i+1 iteration
                T_f_HVAC(k,i+1) = T_f_HVAC(k,i+1)-273; %convert to celsius %w
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,i+1) = (Q_light_load(k,i)+mass_stored_air(stage)*h_i(k,i)-U*SA(stage)*(T_f_HVAC(k,i+1)-T_o(i))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));          
                               
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,i+1) = (ET(k,i)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,i)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,i+1),'w',w_inside(k,i+1),'Pamb',Pamb(i));  %wmax_new
                
                count = 1;
                while abs(T_new-T_f_HVAC(k,i+1))>tolerance
                T_f_HVAC(k,i+1) = T_new;
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,i+1) = (Q_light_load(k,i)+mass_stored_air(stage)*h_i(k,i)-U*SA(stage)*(T_f_HVAC(k,i+1)-T_o(i))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,i+1) = (ET(k,i)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,i)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,i+1),'w',w_inside(k,i+1),'Pamb',Pamb(i));  %wmax_new
                %T_f_HVAC(i+1) = store/2;
                count = count + 1;
                end
                T_f_HVAC(k,i+1) = T_new; %celcius %CHANGE THIS TO T_f_HVAC(i+1)
 
                
               %AUXILARY DEHUMIDIFICATION
                if w_inside(k,i+1)>=w_max
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_cure_mean(2)*100,'Pamb',Pamb(i));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(i)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(i)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid_2(k,i) = mass_flow_air(stage)*((h_i(k,i+1)-h_sat)-cp_water*T_sat*(w_inside(k,i+1)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp_2(k,i) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/COP_chiller;
                    DH_P(k,i) = HVAC_dehumid_2(k,i) + HVAC_heat_temp_2(k,i);
                    T_f_HVAC(k,i+1) = T_min;
                    
                %AUXILARY AIR CONDITIONING
                elseif w_inside(k,i+1)<w_max && w_inside(k,i+1)>w_min
                    if T_f_HVAC(k,i+1)>T_max %AUXILARY AIR CONDITIONING
                        AC_P(k,i) = (Q_light_load(k,i)-mass_stored_air(stage)*cp_air*(T_max-T_f_HVAC(k,i+1))-U*SA(stage)*(T_max-T_o(i)))/COP_chiller;
                        T_f_HVAC(k,i+1) = T_max;   
                    end
                %AUXILARY HEATING
                elseif  T_f_HVAC(k,i+1)<T_min
                        HEAT_P(k,i) = -(Q_light_load(k,i)-mass_stored_air(stage)*cp_air*(T_min-T_f_HVAC(k,i+1))-U*SA(stage)*(T_min-T_o(i)));
                        T_f_HVAC(k,i+1) = T_min;
                end 
        HVAC_P(k,i) = HVAC_dehumid_heat(k,i) + HVAC_heating(k,i) + HVAC_Hum_heat(k,i) + HVAC_humid(k,i) + HVAC_cooling(k,i) + HVAC_hum_cool(k,i);
        Climate_P(k,i) = HVAC_P(k,i) + AC_P(k,i) + DH_P(k,i);
            end
    end
%         elseif (j*i_count_flower+1)<=i && i<=(j*i_count_flower+1+i_count_break)% BREAK: NO PLANTS
        for n = (i+1):(((m)*(i_count_flower+i_count_break))-1)
            if 1 <= n && n <= 8760
            stage = 4;
            
            if Time(n)<=L_break_hours %lights on
                Q_lights(k,n) = L_break_W;  %will be zero when Time(i)>L_clone_hours
                T_i = input.T_break_day(scenario); %setpoint
                T_max = input.T_break_day(1); %maximum allowable T_clone_day
                T_min = input.T_break_day(3); %minimum allowable T_clone_day
                RH_max = input.RH_break_max(1)*100; %maximum allowbable RH_clone
                RH_min = input.RH_break_min(3)*100; %minimum allowable RH_clone
            else %lights off
                T_i = input.T_break_night(scenario);
                T_max = input.T_break_night(1); %maximum allowable T_clone_night
                T_min = input.T_break_night(3); %minimum allowable T_clone_night
                RH_max = input.RH_break_max(1)*100; %maximum allowable RH_clone
                RH_min = input.RH_break_min(3)*100; %minimum allowable RH_clone
            end
                %MAX AND MIN ABSOLUTE HUMIDITY
                [~,w_max,~,h_setpoint_max,~,~,~] = Psychrometricsnew ('Tdb',T_max,'phi',RH_max,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                [~,w_min,~,h_setpoint_min,~,~,~] = Psychrometricsnew ('Tdb',T_min,'phi',RH_min,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                
                if Q_lights(k,n)~=0
                    Q_light_load(k,n) = Q_lights(k,n)*A_g(stage); %Watts
%                     CO2(k,i) = (CO2_flower_conc-CO2_atmos)*A_g(stage)*H*N/(1E6*specific_v_CO2); %kg CO2/hr
                else
                    Q_light_load(k,n) = 0;
                end
                
                                
                %HVAC, ALWAYS ON BASED ON AIR CHANGES
                if w_outside(n)>w_max %Dehumidification and re-heat
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_break_mean(2)*100,'Pamb',Pamb(n));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid(k,n) = mass_flow_air(stage)*((h_outside(n)-h_sat)-cp_water*T_sat*(w_outside(n)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp(k,n) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/Nth_heat;
                    HVAC_dehumid_heat(k,n) = HVAC_dehumid(k,n) + HVAC_heat_temp(k,n);
                elseif w_outside(n)<w_max && w_outside(n)>w_min %Simple Heating
                    if RH(n)>RH_max && T_o(n)<T_max
                        if T_o(n)<T_max && T_o(n)>T_i
                            [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,n) = mass_flow_air(stage)*(h_heat_max-h_outside(n))/Nth_heat;
                        elseif T_o(n)<=T_i && T_o(n)>T_min
                            [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_i,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                            HVAC_heating(k,n) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(n))/Nth_heat;
                        elseif T_o(n)<=T_min
                            [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                            HVAC_heating(k,n) = mass_flow_air(stage)*(h_humheat_temp-h_outside(n))/Nth_heat;
                        end
                    elseif RH(n)<=RH_max && T_o(n)<T_min
                        [~,~,~,h_dehumheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_i,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_heating(k,n) = mass_flow_air(stage)*(h_dehumheat_temp-h_outside(n))/Nth_heat;
                        
                    elseif RH(n)<=RH_min && T_o(n)>T_max %SIMPLE COOLING!!!!
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,n) = mass_flow_air(stage)*(h_outside(n)-h_heat_max)/COP_chiller;
                    elseif RH(n)<=RH_min && T_o(n)<=T_max
                        [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                        HVAC_cooling(k,n) = mass_flow_air(stage)*(h_outside(n)-h_humheat_temp)/COP_chiller;
                    elseif RH(n)>RH_min && T_o(n)>T_max
                        [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                        HVAC_cooling(k,n) = mass_flow_air(stage)*(h_outside(n)-h_heat_max)/COP_chiller;
                    end                     
                elseif w_outside(n)<w_min && T_o(n)<T_min %Heating & Humidification
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_hh_heat_1(k,n) = mass_flow_air(stage)*(h_humheat_temp-h_outside(n))/Nth_heat;
                    %HVAC_hh_heat_2(k,n) = mass_flow_air(stage)*(h_setpoint_min(k,n)-h_humheat_temp(k,n))/Nth_heat;
                    HVAC_hh_vap(k,n) = mass_flow_air(stage)*(w_min-w_outside(n))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %If negative, then heating, shouldn't be though
                    HVAC_Hum_heat(k,n) = HVAC_hh_heat_1(k,n) + HVAC_hh_vap(k,n);
                elseif T_min<T_o(n) && T_max>T_o(n) %Isothermal Humidification
                    if w_outside(n)<w_min %&& RH(n)<RH_min(n) 
                    HVAC_humid(k,n) = mass_flow_air(stage)*(w_min-w_outside(n))*(h_water_vap_100-h_water_liq_20)/Nth_heat;
                    else
                    test = test; %shouldn't ever be in this zone, just a test
                    end               
                elseif w_outside(n)<w_min && T_o(n)>T_max
                    [~,w_hum,~,h_hum,~,~,~] = Psychrometricsnew ('phi',input.RH_break_mean(2)*100,'Tdb',T_o(n),'Pamb',Pamb(n)); %Enthalphy at outside temp and RH setpoint for humidification
                    [~,~,~,h_heat_max,~,~,~] = Psychrometricsnew ('w',w_outside(n),'Tdb',T_max,'Pamb',Pamb(n)); %Enthalpy at w_outside and 100% RH for dehumidification calcs
                    HVAC_humid_temp(k,n) = mass_flow_air(stage)*(w_min-w_outside(n))*(h_water_vap_100-h_water_liq_20)/Nth_heat; %Isothermal Humidification
                    HVAC_cool_temp(k,n) = mass_flow_air(stage)*(h_hum-h_heat_max)/COP_chiller; %Simple Cooling, constant w
                    HVAC_hum_cool(k,n) = HVAC_humid_temp(k,n) + HVAC_cool_temp(k,n);                    
                end
                
                %AT END OF HVAC, GET NEW TEMP AND RH, USE FOR TEMPS AND W'S
                %NEEDED FOR CALCULATING T_FINAL AND W_FINAL
                
                %FIND INITIAL GUESS TEMPERATURE AT END OF HOUR
                T_f_HVAC(k,n+1) = (Q_light_load(k,n)+U*SA(stage)*(T_o(n)+273)+cp_air*mass_stored_air(stage)*(T_f_HVAC(k,n)+273)+...
                    cp_air*mass_flow_air(stage)*(T_min+273))/(cp_air*mass_stored_air(stage)+U*SA(stage)+cp_air*mass_flow_air(stage)); %temp at "end of hour" or i+1 iteration
                T_f_HVAC(k,n+1) = T_f_HVAC(k,n+1)-273; %convert to celsius %w
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,n+1) = (Q_light_load(k,n)+mass_stored_air(stage)*h_i(k,n)-U*SA(stage)*(T_f_HVAC(k,n+1)-T_o(n))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));          
                               
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,n+1) = (ET(k,n)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,n)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,n+1),'w',w_inside(k,n+1),'Pamb',Pamb(n));  %wmax_new
                
                count = 1;
                while abs(T_new-T_f_HVAC(k,n+1))>tolerance
                T_f_HVAC(k,n+1) = T_new;
 
                %CALCULATE INSIDE ENTHALPY AT END OF HOUR
                h_i(k,n+1) = (Q_light_load(k,n)+mass_stored_air(stage)*h_i(k,n)-U*SA(stage)*(T_f_HVAC(k,n+1)-T_o(n))+mass_flow_air(stage)*h_setpoint_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                %CALCULATE ABSOLUTE HUMIDITY INSIDE (kg H2O/kg dry air) & INSIDE TEMP
                w_inside(k,n+1) = (ET(k,n)*A_g(stage)/(3600)+mass_stored_air(stage)*w_inside(k,n)+mass_flow_air(stage)*w_min)/...
                    (mass_flow_air(stage)+mass_stored_air(stage));
                [T_new,~,~,~,~,~,~] = Psychrometricsnew ('h',h_i(k,n+1),'w',w_inside(k,n+1),'Pamb',Pamb(n));  %wmax_new
                %T_f_HVAC(i+1) = store/2;
                count = count + 1;
                end
                T_f_HVAC(k,n+1) = T_new; %celcius %CHANGE THIS TO T_f_HVAC(i+1)
 
                
                %AUXILARY DEHUMIDIFICATION
                if w_inside(k,n+1)>=w_max
                    [~,w_inside_setpoint,~,h_setpoint,~,~,~] = Psychrometricsnew ('Tdb',T_i,'phi',input.RH_break_mean(2)*100,'Pamb',Pamb(n));%Enthalpy based on set point values, what final h will be
                    [T_sat,~,~,h_sat,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'phi',RH_sat,'Pamb',Pamb(n)); %Enthalpy at w_inside and 100% RH
                    [~,~,~,h_humheat_temp,~,~,~] = Psychrometricsnew ('w',w_inside_setpoint,'Tdb',T_min,'Pamb',Pamb(n)); %Enthalpy at w_outside and T_low for heating and humidification cals
                    HVAC_dehumid_2(k,n) = mass_flow_air(stage)*((h_i(k,n+1)-h_sat)-cp_water*T_sat*(w_inside(k,n+1)-w_inside_setpoint))/COP_chiller;
                    HVAC_heat_temp_2(k,n) = mass_flow_air(stage)*((h_humheat_temp-h_sat))/COP_chiller;
                    DH_P(k,n) = HVAC_dehumid_2(k,n) + HVAC_heat_temp_2(k,n);
                    T_f_HVAC(k,n+1) = T_min;
                    
                %AUXILARY AIR CONDITIONING
                elseif w_inside(k,n+1)<w_max && w_inside(k,n+1)>w_min
                    if T_f_HVAC(k,n+1)>T_max %AUXILARY AIR CONDITIONING
                        AC_P(k,n) = (Q_light_load(k,n)-mass_stored_air(stage)*cp_air*(T_max-T_f_HVAC(k,n+1))-U*SA(stage)*(T_max-T_o(n)))/COP_chiller;
                        T_f_HVAC(k,n+1) = T_max;   
                    end
                %AUXILARY HEATING
                elseif T_f_HVAC(k,n+1)<T_min
                        HEAT_P(k,n) = -(Q_light_load(k,n)-mass_stored_air(stage)*cp_air*(T_min-T_f_HVAC(k,n+1))-U*SA(stage)*(T_min-T_o(n)));
                        T_f_HVAC(k,n+1) = T_min;
                end 
            HVAC_P(k,n) = HVAC_dehumid_heat(k,n) + HVAC_heating(k,n) + HVAC_Hum_heat(k,n) + HVAC_humid(k,n) + HVAC_cooling(k,n) + HVAC_hum_cool(k,n);
            Climate_P(k,n) = HVAC_P(k,n) + AC_P(k,n) + DH_P(k,n);
            end
        end
  end
end
 
%VARIABLES THAT ARE NOT TIME DEPENDENT
Q_water = water/(60*60)*cp_water*(T_water-T_well)/Nth_heat; %Whrs
Water_P = water*pumping_power; %Watts/hr
extractor_fan_HP_year = extractor_fan_HP*HP_to_kW*kW_to_W*Day_to_hr*Year_to_days; %Wh/yr
intake_fan_HP_year = intake_fan_HP*HP_to_kW*kW_to_W*Day_to_hr*Year_to_days; %Wh/yr
circ_fan_HP_year = circ_fan_HP*HP_to_kW*kW_to_W*Day_to_hr*Year_to_days; %Wh/yr
plant_waste_year = plant_waste*plant_yield_year; %kg waste/yr
soil_waste_clone_year = soil_waste_clone*plant_count*season_count_og*peat_density*2; %2X for 50% dilution, kg/yr
soil_waste_veg_year = soil_waste_veg*plant_count*season_count_og*peat_density*2; %2X for 50% dilution, kg/yr
soil_waste_flower_year = soil_waste_flower*plant_count*season_count_og*peat_density*2; %2X for 50% dilution, kg/yr
 
 
% p = 1; q =1;
% for p = 1:8760
%     HVAC_heating(q,p) = HVAC_heating(q,p); 
%     HVAC_cooling(q,p) = HVAC_cooling(q,p);
%     HVAC_dehumid(q,p) = HVAC_dehumid(q,p);
%     HVAC_reheat(q,p) = HVAC_heat_temp(q,p);
%     HVAC_Hum_heat(q,p) = HVAC_Hum_heat(q,p);
%     HVAC_humid(q,p) = HVAC_humid(q,p);
%     HVAC_hc_humid(q,p) = HVAC_humid_temp(q,p);
%     HVAC_hc_cool(q,p) = HVAC_cool_temp(q,p);
%     DH_P(q,p) = DH_P(q,p);
%     AC_P(q,p) = AC_P(q,p);
%     Q_light(q,p) = Q_light_load(q,p);
%     ET(q,p) = ET(q,p);
%     Water(q,p) = water(q,p);
%     Q_water(q,p) = Q_water(q,p);
%     CO2(q,p) = CO2(q,p);
%     HVAC_P(q,p) = HVAC_P(q,p); 
%     T_f_AC(q,p) = T_f_AC(q,p);
%     T_f_HVAC(q,p) = T_f_HVAC(q,p);
%     T_i(q,p) = T_i(q,p);
% end
 
 
p = 1;
for p = 1:4
HVAC_heat_year(p) = sum(HVAC_heating(p,:)); 
HVAC_cool_year(p) = sum(HVAC_cooling(p,:));
HVAC_dehumid_year(p) = sum(HVAC_dehumid(p,:));
HVAC_reheat_year(p) = sum(HVAC_heat_temp(p,:));
%HVAC_Hum_heat_year(p) = sum(HVAC_Hum_heat(p,:));
HVAC_hh_heat_1_year(p) = sum(HVAC_hh_heat_1(p,:));
HVAC_hh_vap_year(p) = sum(HVAC_hh_vap(p,:));
HVAC_humid_year(p) = sum(HVAC_humid(p,:));
HVAC_hc_humid_year(p) = sum(HVAC_humid_temp(p,:));
HVAC_hc_cool_year(p) = sum(HVAC_cool_temp(p,:));
DH_P_year(p) = sum(DH_P(p,:));
AC_P_year(p) = sum(AC_P(p,:));
Heat_year(p) = sum(HEAT_P(p,:));
Q_light_year(p) = sum(Q_light_load(p,:));
ET_year(p) = sum(ET(p,:));
Water_year(p) = sum(water(p,:));
Water_P_year(p) = sum(Water_P(p,:));
Q_water_year(p) = sum(Q_water(p,:));
CO2_year(p) = sum(CO2(p,:));
Total_HVAC_year(p) = sum(HVAC_P(p,:));
end


% BUILDING ARRAY FOR LCA ++++++++++++++++++++++++++++++++++++++++++++++++++
LCA_data(1) = sum(HVAC_heat_year)/(kW_to_W*MJ_to_kWh*HHV_ng_mass); %kg/yr (NG)
LCA_data(2) = sum(HVAC_cool_year)/kW_to_W; %kWh/yr (Electric)
LCA_data(3) = sum(HVAC_hh_heat_1_year)/(kW_to_W*MJ_to_kWh*HHV_ng_mass); %kg/yr (NG)
LCA_data(4) = sum(HVAC_hh_vap_year)/(kW_to_W*MJ_to_kWh*HHV_ng_mass); %kg/yr(NG)
LCA_data(5) = sum(HVAC_humid_year)/(kW_to_W*MJ_to_kWh*HHV_ng_mass); %kg/yr (NG)
LCA_data(6) = sum(HVAC_hc_humid_year)/(kW_to_W*MJ_to_kWh*HHV_ng_mass); %kg/yr (NG)
LCA_data(7) = sum(HVAC_hc_cool_year)/kW_to_W; %kWh/yr (Electric)
LCA_data(8) = sum(HVAC_dehumid_year)/kW_to_W; %kWh/yr (Electric)
LCA_data(9) = sum(HVAC_reheat_year)/(kW_to_W*MJ_to_kWh*HHV_ng_mass); %kg/yr (NG)
LCA_data(10) = sum(Q_light_year)/kW_to_W; %kWh/yr (Electric)
LCA_data(11) = sum(Water_year)*gals_to_liters*rho_water/m3_to_liter; %gallons/yr
LCA_data(12) = sum(Water_P_year)/kW_to_W; %kWh/yr (Electric)
LCA_data(13) = sum(Q_water_year)/kW_to_W; %kWh/yr (Electric)
LCA_data(14) = sum(CO2_year); %kg CO2/yr
LCA_data(15) = ammonium_nitrate_mass/Kg_to_g*plant_count*season_count_og;  %kg/yr
LCA_data(16) = triple_superphosphate_mass/Kg_to_g*plant_count*season_count_og; %kg/yr
LCA_data(17) = potassium_chloride_mass/Kg_to_g*plant_count*season_count_og; %kg/yr
LCA_data(18) = soil_coco*coco_density*plant_count*season_count_og; %kg/yr
LCA_data(19) = soil_amendment_mass*perlite_density*plant_count*season_count_og; %kg/yr
LCA_data(20) = neem_oil_mass*plant_count*season_count_og*neem_oil_density/m3_to_liter; %kg/yr
LCA_data(21) = neem_oil_water*plant_count*season_count_og*rho_water/m3_to_liter; %kg/yr
LCA_data(22) = neem_oil_soap*plant_count*season_count_og*soap_density/m3_to_liter; %kg/yr
LCA_data(23) = biofungicide_mass*season_count_og; %kg/yr
LCA_data(24) = extractor_fan_HP_year/kW_to_W; %kWh/yr (Electric)
LCA_data(25) = intake_fan_HP_year/kW_to_W; %kWh/yr (Electric)
LCA_data(26) = circ_fan_HP_year/kW_to_W; %kWh/yr (Electric)
LCA_data(27) = plant_waste_year+soil_waste_clone_year+soil_waste_veg_year+soil_waste_flower_year; %kg/yr
LCA_data(28) = LCA_data(27)*Landfill_methane; %kg CH4/yr
LCA_data(29) = LCA_data(27)*Landfill_carbon; %kg CO2/yr
LCA_data(30) = (LCA_data(23)+LCA_data(19)+LCA_data(15)+LCA_data(16)+LCA_data(17)+LCA_data(20)+LCA_data(22)+LCA_data(14)+LCA_data(18))/tonnes_to_kg; %tonnes/yr
LCA_data(31) = sum(AC_P_year)/kW_to_W; %kWh/yr (Electric)
LCA_data(32) = sum(DH_P_year)/kW_to_W; %kWh/yr (Electric)
LCA_data(33) = sum(Heat_year)/kW_to_W; %kWh/yr (Electric)
LCA_data(34) = LCA_data(30)*trans_dist_lorry; %tonne-km/yr
LCA_data(35) = LCA_data(30)*trans_dist_truck; %tonne-km/yr
LCA_data(36) = LCA_data(30)*trans_dist_pass; %tonne-km/yr

% 
elecintensity = LCA_data(2)+LCA_data(7)+LCA_data(8)+LCA_data(10)+LCA_data(12)+LCA_data(13)+...
    +LCA_data(24)+LCA_data(25)+LCA_data(26)+LCA_data(28)+LCA_data(29)+LCA_data(30);
ngintensity = (LCA_data(1)+LCA_data(3)+LCA_data(4)+LCA_data(5)+LCA_data(6)+LCA_data(9))*(HHV_ng_mass);

% m3_to_liter = Conversions(10); %1000 liters
% MJ_to_kWh = Conversions(15); %0.27778 kWh
% gals_to_liters = Conversions(8); %3.78541 liters

%2020 GHGs 
LCA(1,:) = LCA_data(1).*LCIinput.Natural_Gas;
LCA(2,:) = LCA_data(2).*Electricity;
LCA(3,:) = LCA_data(3).*LCIinput.Natural_Gas;
LCA(4,:) = LCA_data(4).*LCIinput.Natural_Gas;
LCA(5,:) = LCA_data(5).*LCIinput.Natural_Gas;
LCA(6,:) = LCA_data(6).*LCIinput.Natural_Gas;
LCA(7,:) = LCA_data(7).*Electricity;
LCA(8,:) = LCA_data(8).*Electricity;
LCA(9,:) = LCA_data(9).*LCIinput.Natural_Gas;
LCA(10,:) = LCA_data(10).*Electricity;
LCA(11,:) = LCA_data(11).*LCIinput.Tap_Water;
LCA(12,:) = LCA_data(12).*Electricity;
LCA(13,:) = LCA_data(13).*Electricity;
LCA(14,:) = LCA_data(14).*LCIinput.Carbon_Dioxide;
LCA(15,:) = LCA_data(15).*LCIinput.Ammonium_Nitrate;
LCA(16,:) = LCA_data(16).*LCIinput.Triple_Superphosphate;
LCA(17,:) = LCA_data(17).*LCIinput.Potassium_Chloride;
LCA(18,:) = LCA_data(18).*LCIinput.Coco_Husk;
LCA(19,:) = LCA_data(19).*LCIinput.Perlite;
LCA(20,:) = LCA_data(20).*LCIinput.Neem_Oil;
LCA(21,:) = LCA_data(21).*LCIinput.Tap_Water;
LCA(22,:) = LCA_data(22).*LCIinput.Surfactant_Production;
LCA(23,:) = LCA_data(23).*LCIinput.Biofungicide;
LCA(24,:) = LCA_data(24).*Electricity;
LCA(25,:) = LCA_data(25).*Electricity;
LCA(26,:) = LCA_data(26).*Electricity;
LCA(27,:) = LCA_data(27).*LCIinput.Landfill_Operations;
LCA(28,:) = LCA_data(28).*25+LCA_data(29); %IPCC AR4 value for methane is 25
LCA(29,:) = (LCA_data(27)*trans_landfill/tonnes_to_kg).*LCIinput.Transportation_Truck;
LCA(30,:) = LCA_data(31).*Electricity;
LCA(31,:) = LCA_data(32).*Electricity;
LCA(32,:) = LCA_data(33).*Electricity;
LCA(33,:) = LCA_data(34).*LCIinput.Transportation_Lorry;
LCA(34,:) = LCA_data(35).*LCIinput.Transportation_Truck;
LCA(35,:) = LCA_data(36).*LCIinput.Transportation_Passenger;
LCA(36,:) = -plant_yield_year*carbon_seq_product*plant_yield_year; %double plant yields b/c LCA is divided by plant yield below
LCA(37,:) = -LCA_data(27)/tonnes_to_kg*carbon_seq_landfill*plant_yield_year; %double plant yields b/c LCA is divided by plant yield below
LCA(38,:) = elecintensity;
LCA(39,:) = ngintensity;

 
 
LCA = LCA/plant_yield_year; %makes everything per kg-bud
 

 
 
 toc
 
                      
%%Sources
%[1] UGA extension Greenhouses Heating, Cooling and Ventilation
%[2] http://www.farmtek.com/farm/supplies/prod1;ft_greenhouse_plastic_covering;pg108654_108654.html
%[3] Wikipedia: https://en.wikipedia.org/wiki/Polycarbonate
%[4] Engineering Toolbox: https://www.engineeringtoolbox.com/thermal-conductance-conversion-d_1334.html
%[5] Ultimately from the Model for heating demand in greenhouses .pdf, but also http://hubpages.com/hub/How-To-Understand-Window-Energy-Ratings
 



