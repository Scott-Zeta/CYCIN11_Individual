%%% TP optimiser code %%%%%
% v1 John Pitman 10/08/2022

% Core assumptions
    % Lap 1 is defined by input for time rather than energy
    % Always fully deplete (i.e. drop) 1 rider
    % Avoiding acceleration after lap 1
    % i.e. turn duration is increased if a rider has excess energy left over for a
    % given steady-state pace, rather than increasing their power
    % disproportionately to the others
    
% to do

% Dropped rider loop
% Repeat the first half, but with 3 riders. The initial redistribution has
% already been done.
% After each iteration, assess wprime balances
% If all three riders still have +ve wPrimes, increase until one does not
% At that point, take one half lap off the weakest rider and add onto the
% strongest and repeat
% Repeat until 3 riders cannot finish



clc ; clear all; close all; 

%% Input constants

% Environmental Variables
rho = 1.172 ; % air density, kg/m^3
relAirSpd = 0.5; % positive values = tailwind, m/sec

% timeStep, initial velocity                 
dt= 0.05 ;     %time step, sec
v0=0.1; %initial non-zero velocity, m/sec

% Input information 
timeStand = 17 ; % time from start to seated, seconds
lap1AccelBlendTime = 5 ; %time (sec) over which to blend lap 1 power back to steady state power
% (should be less than a half lap time)
weightDist= [0.4 0.6] ; % frt / rr
crrF= 0.0016 ;
crrR= 0.0016 ;
muScrub= 0.007 ; % empirical coefficient
mechEff= 0.98 ; % mech friction losses
MoI_F= 0.08 ;
MoI_R= 0.08 ;
wheelRadius=  0.336 ; % metres from axle to tyre contact patch
Track= 'Disc'  ; % track ID. In this example code there is only 1 option: DISC in Melbourne
reactTime=  0.05 ; % start reaction time, sec
Bike_Length = 1.75 ; % metres
Spacing = 0.25 ; % metres
finishLengthExtra = 0.5; % how many bike lengths the 3rd rider is behind lead rider over the finish line

% CDA scaling by position
cdaScaling = [0.96 0.7 0.6 0.62] ;

%% Optimiser setup

% Power Estimate
pEst = 650; %menTP = 650, womenTP = 420;

% Total time estimate - for initial calcs
Goal_Time_0 = 228 ; % input in secs, e.g. 228 = 3m:48s

% Lap 1 time 
timeLap1_0= 21.5 ; % defined lap 1 time, sec 

%% Input rider data

R1_I='Rider1'  ;
R2_I='Rider2'  ;
R3_I='Rider3'  ;
R4_I='Rider4'  ;


% input_details = [mass(kg), CDA standing(m^2), CDA seated(m^2), seat height(m), 
%   initial_power_turn(W), CP(W), W'(J)]
R1_info =[90.25, 0.5 , 0.167 , 1.03 , pEst, 380 , 112.5 , 27700] ;
R2_info =[92.5, 0.5 ,  0.178 , 1.09 , pEst, 415 , 132.3 , 38000] ; 
R3_info =[87.9 , 0.5 , 0.165 , 1.03 , pEst, 380 , 114.3 , 25300] ; 
R4_info =[95.2 , 0.5 , 0.180 , 1.00 , pEst , 405 , 131.8 , 38000] ; 

riderInfo = [ R1_info ; R2_info; R3_info; R4_info] ; 

%% Initial strategy 

% Define turn order
turnOrder = [1,3,2,4] ; 

% Initial turn durations
% Evenly distributed except starter who gets one less half lap on 2nd turn
% P4 finishes
turnDurations = [2.25, 2, 2, 2, 1.5, 2, 2, 2.25] ;

checkSum16 = sum(turnDurations);
if checkSum16 ~= 16
    error(['check turnDurations, checkSum = ',num2str(checkSum16)])
end
 


%% load data

% Import lean angle lookup table
leanAngleLookup0= readtable('lean_angle_lookup_table.xlsx');
leanAngleLookup = table2array(leanAngleLookup0);

% Note: There should be a 'super-user' facility to go in and add other
% track geometry options

% Import track bank angle data
load('bankingDisc.mat') ;
bankAngleData = bankingDisc;

% load actual measured turn curvature profiles
load('curvatureDISC.mat');
trackCurvatureData = curvatureDisc;

% Note: as we are inputting turn curvature from actual ride data rather than the black-line, we are
% not including a 'dist from black line' parameter as in the spreadsheet




%% Outer while loop - iterate the goal time
Goal_Time = Goal_Time_0;
goalTimeStore(1,1)=Goal_Time;
scheduleFeasible = 0;
iterationCounter = 1;

while scheduleFeasible ~=1 

    %% Initial setup calcs

    steadyStateTime = Goal_Time-timeLap1_0 ;  
    aveVelSteadyState = (3750/steadyStateTime)*0.99 ; 
    % *0.99 is to account for shorter/slower CoM distance/speed 
    % This just makes the initial time come out about the same as the goal
    % time

    timeLap1 = timeLap1_0;
    meanCrr = mean([crrF, crrR]);

    % Get velocity at end of lap 1
    [v250] = F_lap1(timeLap1,riderInfo(turnOrder(1),1),riderInfo(turnOrder(1),2),...
        riderInfo(turnOrder(1),3),meanCrr,mechEff,1,rho,timeStand);

    % Calculate energy requirement over lap 1 for each position
    % total:
    energyTotLap1 = zeros(1,4);
    for II = 1:4
        [v250, energyLap1, powerIn250, splitb2bHl] = F_lap1(timeLap1,riderInfo(turnOrder(II),1),riderInfo(turnOrder(II),2)...
            ,riderInfo(turnOrder(II),3),meanCrr,mechEff,II,rho,timeStand);
        energyTotLap1(1,II) = energyLap1 ;
    end
    % wPrime (over-threshold energy 'bucket'):
    wprimeLap1 = zeros(1,4);
    for II=1:4
        wprimeLap1(II) = energyTotLap1(II)-((riderInfo(turnOrder(II),6)*timeLap1))  ;
    end

    % define initial @power function for each rider
    % Use empirical scaling for aero (vel * 0.98) and roll power (crr * 1.4) to give
    % 'pseudo-velodrome' values
    powerSS_Rider1 = @(Power) (Power*mechEff)-(0.5*rho*R1_info(1,3)*(aveVelSteadyState*0.98)^3)-(meanCrr*1.4*R1_info(1,1)*9.81*aveVelSteadyState) ; 
    powerSS_Rider2 = @(Power) (Power*mechEff)-(0.5*rho*R2_info(1,3)*(aveVelSteadyState*0.98)^3)-(meanCrr*1.4*R2_info(1,1)*9.81*aveVelSteadyState) ; 
    powerSS_Rider3 = @(Power) (Power*mechEff)-(0.5*rho*R3_info(1,3)*(aveVelSteadyState*0.98)^3)-(meanCrr*1.4*R3_info(1,1)*9.81*aveVelSteadyState) ; 
    powerSS_Rider4 = @(Power) (Power*mechEff)-(0.5*rho*R4_info(1,3)*(aveVelSteadyState*0.98)^3)-(meanCrr*1.4*R4_info(1,1)*9.81*aveVelSteadyState) ; 

    % find roots of equations for each rider = steady state power (starting
    % point for optimisation)

    R1_info(1,5)=fzero(powerSS_Rider1,pEst)  ;
    R2_info(1,5)=fzero(powerSS_Rider2,pEst)  ;
    R3_info(1,5)=fzero(powerSS_Rider3,pEst)  ;
    R4_info(1,5)=fzero(powerSS_Rider4,pEst)  ;

    riderInfo = [ R1_info ; R2_info; R3_info; R4_info] ; 
    
    % Define lap 2 power blending:
    startLeadID = turnOrder(1);
    powerBlend = zeros(60/dt,1);
    powerBlend(1)=powerIn250-riderInfo(startLeadID,5);
    pX = [0,lap1AccelBlendTime/dt];
    pY = [powerBlend(1),0];
    ply=polyfit(pX,pY,1);
    for II = 2:lap1AccelBlendTime/dt
        powerBlend(II)= II*ply(1)+ply(2);
    end
        
    % Turn info
    turnDists_0 = turnDurations.*250;
    turnDistsCum_0 = cumsum(turnDists_0);
    turnLeadIDS_0 = repmat(turnOrder,1,4);

    
    % Half lap reference vectors
    % pursuit-pursuit
    halfLapInfo = zeros(33,5);
    halfLapInfo(:,1) = [125:125:4125];
    % bend-bend
    halfLapInfob2b = zeros(33,5);
    halfLapInfob2b(:,1) = [62.5:125:4062.5];
    
    % Half lap data stores per position
    % Columns for % hl dist, turn radius, seat height, velWheel, CoM speed(from fn)
    halfLapVelodromeCalcs = zeros(10/dt,20);

    %% Initial loop with 'evenly distributed' strategy - indicate who should be dropped

    % tp_Time is event time. t=0 to the point the third rider crosses the line
    % tp_Speed is the speed - assumed common to all riders, determined by the
    % energy balance of the lead rider.
    % 'tp#' relates to the position
    % 'rider#' relates to the rider

    % Preallocate vectors
    zeroLength = 8*60*1/dt;

    tp_Time = zeros(zeroLength,1);
    tp_CoMSpeed = zeros(zeroLength,1);
    tp_whlSpeed = zeros(zeroLength,1);

    tp1_ID = zeros(zeroLength,1);
    tp2_ID = zeros(zeroLength,1);
    tp3_ID = zeros(zeroLength,1);
    tp4_ID = zeros(zeroLength,1);

    tp1_AeroPower = zeros(zeroLength,1);
    tp1_RollPower = zeros(zeroLength,1);
    tp1_PowerIn = zeros(zeroLength,1);
    tp1_NetPower = zeros(zeroLength,1);
    tp1_PropForce = zeros(zeroLength,1);
    tp1_Accel = zeros(zeroLength,1);
    tp1_CoMDistance = zeros(zeroLength,1);
    tp1_whlDistance = zeros(zeroLength,1);
    tp1_wPrime = zeros(zeroLength,1);

    tp2_AeroPower = zeros(zeroLength,1);
    tp2_RollPower = zeros(zeroLength,1);
    tp2_PowerIn = zeros(zeroLength,1);
    tp2_wPrime = zeros(zeroLength,1);

    tp3_AeroPower = zeros(zeroLength,1);
    tp3_RollPower = zeros(zeroLength,1);
    tp3_PowerIn = zeros(zeroLength,1);
    tp3_wPrime = zeros(zeroLength,1);

    tp4_AeroPower = zeros(zeroLength,1);
    tp4_RollPower = zeros(zeroLength,1);
    tp4_PowerIn = zeros(zeroLength,1);
    tp4_wPrime = zeros(zeroLength,1);

    % riderData array
    % Col #1: wPrime, Col #2: aeroPower, Col #3: rollPower, Col #4: powerIn
    % for riders 1-4, in sequence
    riderData = zeros(zeroLength,16);

    %%
    % Initialise from the beginning of lap 2
    % initial values at first timestep

    tp_Time(1) = timeLap1;
    tp_CoMSpeed(1) = v250;
    tp_whlSpeed(1) = v250;
    tp1_AeroPower(1)=0.5*rho*tp_CoMSpeed(1)^3*riderInfo(turnOrder(1),3)*cdaScaling(1);
    tp1_RollPower(1)=crrF*riderInfo(turnOrder(1),1)*weightDist(1)*9.81*tp_CoMSpeed(1)...
        +crrR*riderInfo(turnOrder(1),1)*weightDist(2)*9.81*tp_CoMSpeed(1);
    tp1_PowerIn(1) = riderInfo(turnOrder(1),5)+powerBlend(1);
    tp1_NetPower(1) = tp1_PowerIn(1)*mechEff - tp1_AeroPower(1) - tp1_RollPower(1);
    tp1_PropForce(1) = tp1_NetPower(1)/tp_CoMSpeed(1);
    tp1_Accel(1) = tp1_PropForce(1)/(riderInfo(turnOrder(1),1)+(MoI_F/wheelRadius^2)+(MoI_R/wheelRadius^2));
    tp1_CoMDistance(1)= 250.01;
    tp1_whlDistance(1)= 250.01;
    tp1_wPrime(1)=(tp1_PowerIn(1)-riderInfo(turnOrder(1),6))*dt;
    
    % Initial turn radius, bank angle and radius of CoM
    % turn radius (1/k)
    halfLapVelodromeCalcs(1,2)=1/trackCurvatureData(1,2);
    % bank angle (radians)
    halfLapVelodromeCalcs(1,3)=deg2rad(bankAngleData(1,2));    
    % Radius of the CoM
    halfLapVelodromeCalcs(1,4)= halfLapVelodromeCalcs(1,2);

    tp1_ID(1) = turnOrder(1);
    tp2_ID(1) = turnOrder(2);
    tp3_ID(1) = turnOrder(3);
    tp4_ID(1) = turnOrder(4);

    wPrimebeginLap2 = zeros(1,4);
    for II = 1:4
        wPrimebeginLap2(II) = riderInfo(turnOrder(II),8)-wprimeLap1(turnOrder(II));    
    end

    % Rider data into array
    for II = 1:4
        % wPrime
        riderData(1,II*4-3) = wPrimebeginLap2(turnOrder ==II);
        % aero power
        riderData(1,II*4-2) = 0.5*rho*tp_CoMSpeed(1)^3*riderInfo(turnOrder(II),3)*cdaScaling(II);
        % roll power
        riderData(1,II*4-1) = crrF*riderInfo(turnOrder(II),1)*weightDist(1)*9.81*tp_CoMSpeed(1)...
            +crrR*riderInfo(turnOrder(1),1)*weightDist(2)*9.81*tp_CoMSpeed(1);  
    end
    % P1 power in
    riderData(1,4*tp1_ID(1))= tp1_PowerIn(1);

    % P2,3,4 power in
    for II = [2,3,4]
        accelPower = riderInfo(turnOrder(II),1)*tp1_Accel(1)*tp_CoMSpeed(1);
        riderData(1,4*turnOrder(II))=(riderData(1,II*4-2)+riderData(1,II*4-1)+accelPower)/mechEff;
    end


    %% 4k Distance loop
    % forward integrate in time

    dist4k = 0; % stopper for while loop @ 4km
    
    % Count timeSteps, turns, half-laps
    turnCounter = 1;
    turnCounterStore = ones(length(turnDurations)+1,1);
    tsCounter = 2;
    halfLapCounter = 3;
    halfLapCounterb2b = 3;
    halfLapTSCounter = 2;

    while dist4k ~= 1

        tp_Time(tsCounter)=tp_Time(tsCounter-1)+dt;
        tp_CoMSpeed(tsCounter)=tp_CoMSpeed(tsCounter-1)+tp1_Accel(tsCounter-1)*dt;
        tp1_CoMDistance(tsCounter) = tp_CoMSpeed(tsCounter)*dt;
        tp1_whlDistance(tsCounter) = tp_CoMSpeed(tsCounter-1)*dt*halfLapVelodromeCalcs(halfLapTSCounter-1,2)/halfLapVelodromeCalcs(halfLapTSCounter-1,4)+tp1_whlDistance(tsCounter-1);
        tp_whlSpeed(tsCounter)=(tp1_whlDistance(tsCounter)-tp1_whlDistance(tsCounter-1))/dt;
        
        % Percentage distance around (start-finish line) half-lap:
        halfLapVelodromeCalcs(halfLapTSCounter,1)=(tp1_whlDistance(tsCounter-1)-halfLapInfo(halfLapCounter-1,1))/125;
        
        if halfLapVelodromeCalcs(halfLapTSCounter,1) > 1
            lastTurnRadius = halfLapVelodromeCalcs(halfLapTSCounter-1,2);
            lastBankAngle = halfLapVelodromeCalcs(halfLapTSCounter-1,3);
            lastRadCoM = halfLapVelodromeCalcs(halfLapTSCounter-1,4);
            lastLeanAngle = halfLapVelodromeCalcs(halfLapTSCounter-1,5);
            % Reset the half-lap data vector
            halfLapVelodromeCalcs = zeros(10/dt,20);
            % Put the values from the last ts of previous half lap as first
            % values in this half lap
            halfLapVelodromeCalcs(1,2)=lastTurnRadius;
            halfLapVelodromeCalcs(1,3)=lastBankAngle;
            halfLapVelodromeCalcs(1,4)=lastRadCoM;
            halfLapVelodromeCalcs(1,5)=lastLeanAngle;
            % Reset the halfLapTSCounter
            halfLapTSCounter = 2;
        end
        
        % Get the turn radius (from inverse of turn curvature)
        idx1=find(trackCurvatureData(:,1)>=halfLapVelodromeCalcs(halfLapTSCounter-1,1),1) ;
        turnRadius = 1./trackCurvatureData(idx1,2) ; 
        halfLapVelodromeCalcs(halfLapTSCounter,2)=turnRadius;
        
        % Get the bank angle at current location:
        idx2=find(bankAngleData(:,1)>=halfLapVelodromeCalcs(halfLapTSCounter-1,1),1) ;
        bankAngleRad= deg2rad(bankAngleData(idx2,2)) ;
        halfLapVelodromeCalcs(halfLapTSCounter,3)=bankAngleRad;
        
        % Get radius of CoM

        [leanAngleDeg, radCoM] = F_leanAngle_velCoM(turnRadius,tp_CoMSpeed(tsCounter),riderInfo(tp1_ID(tsCounter-1),4));
        halfLapVelodromeCalcs(halfLapTSCounter,4)=radCoM;
        halfLapVelodromeCalcs(halfLapTSCounter,5)=leanAngleDeg;
        
        % ID of riders in each position
        tp1_ID(tsCounter) = turnLeadIDS_0(turnCounter);
        tp2_ID(tsCounter) = turnLeadIDS_0(turnCounter+1);
        tp3_ID(tsCounter) = turnLeadIDS_0(turnCounter+2);
        tp4_ID(tsCounter) = turnLeadIDS_0(turnCounter+3);
        
        % Seated Aero power with pos-dependent drafting factor
        
        tp1_AeroPower(tsCounter)= 0.5*rho*tp_CoMSpeed(tsCounter)^3*riderInfo(tp1_ID(tsCounter),3)*cdaScaling(1);
        tp2_AeroPower(tsCounter)= 0.5*rho*tp_CoMSpeed(tsCounter)^3*riderInfo(tp2_ID(tsCounter),3)*cdaScaling(2);
        tp3_AeroPower(tsCounter)= 0.5*rho*tp_CoMSpeed(tsCounter)^3*riderInfo(tp3_ID(tsCounter),3)*cdaScaling(3);
        tp4_AeroPower(tsCounter)= 0.5*rho*tp_CoMSpeed(tsCounter)^3*riderInfo(tp4_ID(tsCounter),3)*cdaScaling(4);

        % Rolling resistance power
        [fRR_frt, fRR_rr] = F_normForceRR(tp_CoMSpeed(tsCounter), radCoM, leanAngleDeg, riderInfo(tp1_ID(tsCounter),1), weightDist(1), bankAngleRad, muScrub, crrF, crrR);
        tp1_RollPower(tsCounter)=fRR_frt*tp_whlSpeed(tsCounter)+fRR_rr*tp_whlSpeed(tsCounter);
        [fRR_frt, fRR_rr] = F_normForceRR(tp_CoMSpeed(tsCounter), radCoM, leanAngleDeg, riderInfo(tp2_ID(tsCounter),1), weightDist(1), bankAngleRad, muScrub, crrF, crrR);
        tp2_RollPower(tsCounter)=fRR_frt*tp_whlSpeed(tsCounter)+fRR_rr*tp_whlSpeed(tsCounter);
        [fRR_frt, fRR_rr] = F_normForceRR(tp_CoMSpeed(tsCounter), radCoM, leanAngleDeg, riderInfo(tp3_ID(tsCounter),1), weightDist(1), bankAngleRad, muScrub, crrF, crrR);
        tp3_RollPower(tsCounter)=fRR_frt*tp_whlSpeed(tsCounter)+fRR_rr*tp_whlSpeed(tsCounter);
        [fRR_frt, fRR_rr] = F_normForceRR(tp_CoMSpeed(tsCounter), radCoM, leanAngleDeg, riderInfo(tp4_ID(tsCounter),1), weightDist(1), bankAngleRad, muScrub, crrF, crrR);
        tp4_RollPower(tsCounter)=fRR_frt*tp_whlSpeed(tsCounter)+fRR_rr*tp_whlSpeed(tsCounter);

        % Lookup P1 power input value
        tp1_PowerIn(tsCounter)= riderInfo(tp1_ID(tsCounter),5);
        
        % Add powerBlend value
        if halfLapCounter ==3
            tp1_PowerIn(tsCounter)=tp1_PowerIn(tsCounter)+ powerBlend(tsCounter);
        end
 
        % Power to accelerate (follow riders)
        dv = tp_CoMSpeed(tsCounter)-tp_CoMSpeed(tsCounter-1);

        tp2_AccelPower = (riderInfo(tp2_ID(tsCounter),1)+(MoI_F/wheelRadius^2)+(MoI_R/wheelRadius^2))*(dv/dt)*tp_CoMSpeed(tsCounter);
        tp3_AccelPower = (riderInfo(tp3_ID(tsCounter),1)+(MoI_F/wheelRadius^2)+(MoI_R/wheelRadius^2))*(dv/dt)*tp_CoMSpeed(tsCounter);
        tp4_AccelPower = (riderInfo(tp4_ID(tsCounter),1)+(MoI_F/wheelRadius^2)+(MoI_R/wheelRadius^2))*(dv/dt)*tp_CoMSpeed(tsCounter);

        % Calculate follow powers
        tp2_PowerIn(tsCounter)=(tp2_AeroPower(tsCounter)+tp2_RollPower(tsCounter)+tp2_AccelPower)/mechEff;
        tp3_PowerIn(tsCounter)=(tp3_AeroPower(tsCounter)+tp3_RollPower(tsCounter)+tp3_AccelPower)/mechEff;
        tp4_PowerIn(tsCounter)=(tp4_AeroPower(tsCounter)+tp4_RollPower(tsCounter)+tp4_AccelPower)/mechEff;

        % Power balance P1
        tp1_NetPower(tsCounter)= tp1_PowerIn(tsCounter)*mechEff -...
         tp1_AeroPower(tsCounter)- tp1_RollPower(1);

        % Propulsive force P1
        tp1_PropForce(tsCounter) = tp1_NetPower(tsCounter)/tp_CoMSpeed(tsCounter);

        % Acceleration P1
        tp1_Accel(tsCounter) = tp1_PropForce(tsCounter)/(riderInfo(tp1_ID(tsCounter),1)+(MoI_F/wheelRadius^2)+(MoI_R/wheelRadius^2));

        % Determine over or under CP for each position
        tp1_powerDiff = riderInfo(tp1_ID(tsCounter),6)-tp1_PowerIn(tsCounter);
        tp2_powerDiff = riderInfo(tp2_ID(tsCounter),6)-tp2_PowerIn(tsCounter);
        tp3_powerDiff = riderInfo(tp3_ID(tsCounter),6)-tp3_PowerIn(tsCounter);
        tp4_powerDiff = riderInfo(tp4_ID(tsCounter),6)-tp4_PowerIn(tsCounter);

        % wPrime balance, power data by rider
        % for lead rider
        if tp1_ID(tsCounter)==1
            riderData(tsCounter,1) = F_wPrimeBal(dt, tp1_powerDiff, riderData(tsCounter-1,1), riderInfo(1,8));
            riderData(tsCounter,2) = tp1_AeroPower(tsCounter);
            riderData(tsCounter,3) = tp1_RollPower(tsCounter);
            riderData(tsCounter,4) = tp1_PowerIn(tsCounter);
        elseif tp1_ID(tsCounter)==2
            riderData(tsCounter,5) = F_wPrimeBal(dt, tp1_powerDiff, riderData(tsCounter-1,5), riderInfo(2,8));
            riderData(tsCounter,6) = tp1_AeroPower(tsCounter);
            riderData(tsCounter,7) = tp1_RollPower(tsCounter);
            riderData(tsCounter,8) = tp1_PowerIn(tsCounter);
        elseif tp1_ID(tsCounter)==3
            riderData(tsCounter,9) = F_wPrimeBal(dt, tp1_powerDiff, riderData(tsCounter-1,9), riderInfo(3,8));
            riderData(tsCounter,10) = tp1_AeroPower(tsCounter);
            riderData(tsCounter,11) = tp1_RollPower(tsCounter);
            riderData(tsCounter,12) = tp1_PowerIn(tsCounter);
        elseif tp1_ID(tsCounter)==4
            riderData(tsCounter,13) = F_wPrimeBal(dt, tp1_powerDiff, riderData(tsCounter-1,13), riderInfo(4,8));
            riderData(tsCounter,14) = tp1_AeroPower(tsCounter);
            riderData(tsCounter,15) = tp1_RollPower(tsCounter);
            riderData(tsCounter,16) = tp1_PowerIn(tsCounter);
        end

        % for P2
        if tp2_ID(tsCounter)==1
            riderData(tsCounter,1) = F_wPrimeBal(dt, tp2_powerDiff, riderData(tsCounter-1,1), riderInfo(1,8));
            riderData(tsCounter,2) = tp2_AeroPower(tsCounter);
            riderData(tsCounter,3) = tp2_RollPower(tsCounter);
            riderData(tsCounter,4) = tp2_PowerIn(tsCounter);
        elseif tp2_ID(tsCounter)==2
            riderData(tsCounter,5) = F_wPrimeBal(dt, tp2_powerDiff, riderData(tsCounter-1,5), riderInfo(2,8));
            riderData(tsCounter,6) = tp2_AeroPower(tsCounter);
            riderData(tsCounter,7) = tp2_RollPower(tsCounter);
            riderData(tsCounter,8) = tp2_PowerIn(tsCounter);
        elseif tp2_ID(tsCounter)==3
            riderData(tsCounter,9) = F_wPrimeBal(dt, tp2_powerDiff, riderData(tsCounter-1,9), riderInfo(3,8));
            riderData(tsCounter,10) = tp2_AeroPower(tsCounter);
            riderData(tsCounter,11) = tp2_RollPower(tsCounter);
            riderData(tsCounter,12) = tp2_PowerIn(tsCounter);
        elseif tp2_ID(tsCounter)==4
            riderData(tsCounter,13) = F_wPrimeBal(dt, tp2_powerDiff, riderData(tsCounter-1,13), riderInfo(4,8));
            riderData(tsCounter,14) = tp2_AeroPower(tsCounter);
            riderData(tsCounter,15) = tp2_RollPower(tsCounter);
            riderData(tsCounter,16) = tp2_PowerIn(tsCounter);
        end

        % for P3
        if tp3_ID(tsCounter)==1
            riderData(tsCounter,1) = F_wPrimeBal(dt, tp3_powerDiff, riderData(tsCounter-1,1), riderInfo(1,8));
            riderData(tsCounter,2) = tp3_AeroPower(tsCounter);
            riderData(tsCounter,3) = tp3_RollPower(tsCounter);
            riderData(tsCounter,4) = tp3_PowerIn(tsCounter);
        elseif tp3_ID(tsCounter)==2
            riderData(tsCounter,5) = F_wPrimeBal(dt, tp3_powerDiff, riderData(tsCounter-1,5), riderInfo(2,8));
            riderData(tsCounter,6) = tp3_AeroPower(tsCounter);
            riderData(tsCounter,7) = tp3_RollPower(tsCounter);
            riderData(tsCounter,8) = tp3_PowerIn(tsCounter);
        elseif tp3_ID(tsCounter)==3
            riderData(tsCounter,9) = F_wPrimeBal(dt, tp3_powerDiff, riderData(tsCounter-1,9), riderInfo(3,8));
            riderData(tsCounter,10) = tp3_AeroPower(tsCounter);
            riderData(tsCounter,11) = tp3_RollPower(tsCounter);
            riderData(tsCounter,12) = tp3_PowerIn(tsCounter);
        elseif tp3_ID(tsCounter)==4
            riderData(tsCounter,13) = F_wPrimeBal(dt, tp3_powerDiff, riderData(tsCounter-1,13), riderInfo(4,8));
            riderData(tsCounter,14) = tp3_AeroPower(tsCounter);
            riderData(tsCounter,15) = tp3_RollPower(tsCounter);
            riderData(tsCounter,16) = tp3_PowerIn(tsCounter);
        end

        % for P4
        if tp4_ID(tsCounter)==1
            riderData(tsCounter,1) = F_wPrimeBal(dt, tp4_powerDiff, riderData(tsCounter-1,1), riderInfo(1,8));
            riderData(tsCounter,2) = tp4_AeroPower(tsCounter);
            riderData(tsCounter,3) = tp4_RollPower(tsCounter);
            riderData(tsCounter,4) = tp4_PowerIn(tsCounter);
        elseif tp4_ID(tsCounter)==2
            riderData(tsCounter,5) = F_wPrimeBal(dt, tp4_powerDiff, riderData(tsCounter-1,5), riderInfo(2,8));
            riderData(tsCounter,6) = tp4_AeroPower(tsCounter);
            riderData(tsCounter,7) = tp4_RollPower(tsCounter);
            riderData(tsCounter,8) = tp4_PowerIn(tsCounter);
        elseif tp4_ID(tsCounter)==3
            riderData(tsCounter,9) = F_wPrimeBal(dt, tp4_powerDiff, riderData(tsCounter-1,9), riderInfo(3,8));
            riderData(tsCounter,10) = tp4_AeroPower(tsCounter);
            riderData(tsCounter,11) = tp4_RollPower(tsCounter);
            riderData(tsCounter,12) = tp4_PowerIn(tsCounter);
        elseif tp4_ID(tsCounter)==4
            riderData(tsCounter,13) = F_wPrimeBal(dt, tp4_powerDiff, riderData(tsCounter-1,13), riderInfo(4,8));
            riderData(tsCounter,14) = tp4_AeroPower(tsCounter);
            riderData(tsCounter,15) = tp4_RollPower(tsCounter);
            riderData(tsCounter,16) = tp4_PowerIn(tsCounter);
        end


        
        % All half-lap location specific calcs now completed, so
        halfLapTSCounter = halfLapTSCounter+1;

        
        % Check if half lap distance has been completed, if so record time
        % and distance (for calculating split times)
        if tp1_whlDistance(tsCounter)>halfLapInfo(halfLapCounter,1)
            halfLapInfo(halfLapCounter,2)=tp1_whlDistance(tsCounter);
            halfLapInfo(halfLapCounter,3)=tp_Time(tsCounter); 
            halfLapInfo(halfLapCounter,4)=halfLapInfo(halfLapCounter,2)-halfLapInfo(halfLapCounter,1);
            halfLapInfo(halfLapCounter,5)=halfLapInfo(halfLapCounter,3)-halfLapInfo(halfLapCounter-1,3);
            halfLapCounter = halfLapCounter+1; 
            halfLapTSCounter = 2;            
        end
  
        % Check if bend-bend half lap distance has been completed, if so record time
        % and distance (for calculating split times)
        
        if tp1_whlDistance(tsCounter)>halfLapInfob2b(halfLapCounterb2b,1)
            halfLapInfob2b(halfLapCounterb2b,2)=tp1_whlDistance(tsCounter);
            halfLapInfob2b(halfLapCounterb2b,3)=tp_Time(tsCounter); 
            halfLapInfob2b(halfLapCounterb2b,4)=halfLapInfob2b(halfLapCounterb2b,2)-halfLapInfob2b(halfLapCounterb2b,1);
            halfLapInfob2b(halfLapCounterb2b,5)=halfLapInfob2b(halfLapCounterb2b,3)-halfLapInfob2b(halfLapCounterb2b-1,3);
            if halfLapCounterb2b == 3
               halfLapInfob2b(halfLapCounterb2b,5)=halfLapInfob2b(halfLapCounterb2b,5)-splitb2bHl;
            end
            halfLapCounterb2b = halfLapCounterb2b+1;
            
            % **then need to make interpolated bend-to-bend split times to
            % report out**
        end

        % check if turn distance has been completed
        % if so, write turn data to respective rider vectors
        if tp1_whlDistance(tsCounter)>=turnDistsCum_0(turnCounter)+Bike_Length+Spacing
            turnCounter = turnCounter+1;
            tp1_whlDistance(tsCounter)= tp1_whlDistance(tsCounter)-(Bike_Length+Spacing)+ 0.01;
            turnCounterStore(turnCounter)=tsCounter;
        end


        % check if 4k has been completed
        if max(tp1_whlDistance)>4000
            dist4k = 1;

            % Report minimum and final wPrime balances
            wPrimeBalEnd = zeros(1,4);
            wPrimeBalEnd(1)= riderData(tsCounter-1,1);
            wPrimeBalEnd(2)= riderData(tsCounter-1,5);
            wPrimeBalEnd(3)= riderData(tsCounter-1,9);
            wPrimeBalEnd(4)= riderData(tsCounter-1,13);
            wPrimeBalEnd_minID = find(wPrimeBalEnd==(min(wPrimeBalEnd)));

            wPrimeBalMin = zeros(1,4);
            wPrimeBalMin(1)= min(riderData(1:tsCounter-1,1));
            wPrimeBalMin(2)= min(riderData(1:tsCounter-1,5));
            wPrimeBalMin(3)= min(riderData(1:tsCounter-1,9));
            wPrimeBalMin(4)= min(riderData(1:tsCounter-1,13));
            wPrimeBalMin_minID = find(wPrimeBalMin==(min(wPrimeBalMin)));

            Xs = [1 2 3 4];
            Ys = [wPrimeBalEnd./1000 ; wPrimeBalMin./1000];

            % Finish time to 3rd rider
            % Interpolate to get P1 time @ 4000m
            tp_Speed_end = tp_CoMSpeed(tsCounter);
            xTime3rdRider =  (finishLengthExtra * Bike_Length) / tp_Speed_end;
            
            tp1_Distance_end1 = tp1_whlDistance(tsCounter-1);
            tp1_Distance_end2 = tp1_whlDistance(tsCounter);
            distEndDelta = 4000-tp1_Distance_end1;
            prctThru = distEndDelta /(tp1_Distance_end2-tp1_Distance_end1);

            tp_Time_end1 = tp_Time(tsCounter-1);

            tpTime4k = tp_Time_end1+dt*prctThru+xTime3rdRider;
            tpTime4kSec = seconds(tpTime4k);
            tpTime4kMs = duration(tpTime4kSec,'Format','mm:ss.SS');
            strTime = char(tpTime4kMs,'mm:ss.SS');
            

            % Report messages:
                     
            fprintf(['- Time to 4km was ',strTime,' \n']);        
            fprintf(['- Rider with lowest wPrime at the end was rider #',num2str(wPrimeBalEnd_minID),'\n']);        
            fprintf(['- Rider with lowest wPrime at any point was rider #',num2str(wPrimeBalMin_minID),'\n']);
            if min(wPrimeBalMin)<0
                fprintf(['- schedule is NOT feasible with 4 riders, min wPrime dropped to ',num2str(min(wPrimeBalMin)/1000),'KJ \n'])
                fprintf('- DEcreasing steady state pace and repeating \n')
                fprintf('\n')
                Goal_Time = Goal_Time + 0.05;
                scheduleFeasible = 0;
            elseif min(wPrimeBalMin)>0
                fprintf('- schedule IS feasible - all riders have +ve wPrime balances\n')
                fprintf('- INcreasing steady state pace and repeating \n')
                fprintf('\n')
                Goal_Time = Goal_Time - 0.01;
                scheduleFeasible = 1;
                wPrimeBalMinReport = min(wPrimeBalMin)/1000;
                if wPrimeBalMinReport > 0.1
                    scheduleFeasible = 0;
                end
            end
            if iterationCounter ==1
            % option to just do a 'what-if' on the initial settings
                prompt = 'Do you want to continue with wPrime opt loop ? [y/n]';
                strX = input(prompt,'s');
                if strcmp(strX,'y')
                    scheduleFeasible = 0;
                elseif strcmp(strX,'n')
                    scheduleFeasible = 1;
                end

                
            end
                    
            goalTimeStore(iterationCounter,1)=Goal_Time;
            goalTimeStore(iterationCounter,2)=tpTime4k;
            goalTimeStore(iterationCounter,3)=min(wPrimeBalMin);


            turnCounterStore(end)=tsCounter;
        end

        tsCounter = tsCounter+1;


    end % end 4k-distance time iteration while loop
    iterationCounter = iterationCounter+1;

    
end % end Goal-time iteration while loop

if strcmp(strX,'y')
    fprintf(['\n- Fastest 4km time with initial strategy and all 4 riders finishing is ',strTime,' \n']); 

elseif strcmp(strX,'n')
    fprintf(['\n- The 4km time with initial inputs is ',strTime,' \n']);
end



%% Figures

% wPrime balances
figure; 
b = bar(Xs,Ys);

labels1 = string(b(1).YData);
labels1shrt=[extractBetween(labels1,1,4)]';% first 4 characters i.e. 3 s.f
xtips1 = b(1).XEndPoints;
ytips1 = b(1).YEndPoints;
text(xtips1,ytips1,labels1shrt,'HorizontalAlignment','center',...
    'VerticalAlignment','bottom');
labels2 = string(b(2).YData);
labels2shrt=[extractBetween(labels2,1,4)]';% first 4 characters i.e. 3 s.f
xtips2 = b(2).XEndPoints;
ytips2 = b(2).YEndPoints;
text(xtips2,ytips2,labels2shrt,'HorizontalAlignment','center',...
    'VerticalAlignment','bottom');

legend('wPrimeBalEnd','wPrimeBalMin')
ylabel('wPrimeBal, KJ')
title('wPrime End and Min balances')

% speed figure
figure;plot(tp_Time(1:tsCounter-1),tp_CoMSpeed(1:tsCounter-1))
hold on
grid on
plot(tp_Time(1:tsCounter-1),tp_whlSpeed(1:tsCounter-1))
ylim([10 22])
legend('CoM speed','Wheel speed')
title('CoM, Wheel speed trace of lead rider')
ylabel('speed, m/sec')

% wPrime figure
figure;plot(tp_Time(1:tsCounter-1),riderData(1:tsCounter-1,1)./1000)
hold on
grid on
plot(tp_Time(1:tsCounter-1),riderData(1:tsCounter-1,5)./1000)
plot(tp_Time(1:tsCounter-1),riderData(1:tsCounter-1,9)./1000)
plot(tp_Time(1:tsCounter-1),riderData(1:tsCounter-1,13)./1000)
legend
xlabel('time,sec')
ylabel('wPrime, KJ')
title({'wPrime balance by TP start position';['turn durations: ',num2str(turnDurations)]} )

% power in figure
figure;plot(tp_Time(1:tsCounter-1),riderData(1:tsCounter-1,4))
hold on
grid on
plot(tp_Time(1:tsCounter-1),riderData(1:tsCounter-1,8))
plot(tp_Time(1:tsCounter-1),riderData(1:tsCounter-1,12))
plot(tp_Time(1:tsCounter-1),riderData(1:tsCounter-1,16))
legend
xlabel('time,sec')
ylabel('Power input, W')
title({'Power input by TP start position';['turn durations: ',num2str(turnDurations)]} )

%%
%%%%%%%%%%% End of first part  %%%%%%%%%%%%%
% Second part: choose rider to drop and optimise the strategy

%% Assumptions
% Core assumption is that fastest possible is by fully depleting 1 rider
% (i.e. only finish with 3)
% This version assumes the new number of turns is [original-1] 
% Could/should do a sweep with this varying....
% Dropped rider half-laps get evenly distributed to remaining riders last turns, with
% preference to strongest rider if not divisible by 3
if  strcmp(strX,'y')
    prompt = 'Do you wish to continue with TP optimisation? [y/n]' ;
        str = input(prompt,'s');
            if isempty(str)||strcmp(str,'y')
                cont = 1;
            elseif strcmp(str,'n')
                cont = 0;
            end
elseif strcmp(strX,'n')
    cont = 0;
end
        
if cont ~=1
    fprintf('\n ***** Finished ******\n')
else
    fprintf('\n Phase 2: optimisation of turn duration with 3 riders \n')
    
%% Select rider to drop
    prompt = 'Select rider you want to drop [1 2 3 4]?' ;
    riderDrop = input(prompt);
% After how many turns - propose only realistic opts  

    dropRiderTurnIDs_0 = find(turnLeadIDS_0(1:turnCounter)==riderDrop);
    dropRiderTurnCount_0 = length(dropRiderTurnIDs_0);
    prompt = ['After how many turns (1 to ',num2str(dropRiderTurnCount_0),')?'] ;
    riderDropTurns = input(prompt);
    if riderDropTurns == dropRiderTurnCount_0
        proceed = 0;
        while proceed ~= 1
        prompt = 'that is the same # of turns they did initially - are you sure? [y/n]';
        riderDropTurns = input(prompt);
            str = input(prompt,'s');
            if isempty(str) || strcmp(str,'y')
                fprintf('Ok - will optimise with 4 riders \n')
                proceed =1;
            elseif strcmp(str,'n')
                prompt = ['After how many turns (1 to ',num2str(dropRiderTurnCount_0),')?'] ;
                riderDropTurns = input(prompt);
                proceed = 1;
            end
        end
    end

    fprintf('\n Proceeding with optimisation.... (need to complete the code from here onwards) \n');

    % Define new turn strategy 
    turns2_0 = turnLeadIDS_0(1:turnCounter);
    turnsRemove = dropRiderTurnIDs_0(riderDropTurns+1);
    turns2_0(turnsRemove)=0;
    turns2=turns2_0(turns2_0~=0);

    % Define new initial turn durations 
    turnDurations2_0 = turnDurations(turns2_0~=0);

    % Rank remaining riders with most wPrime left at end of initial opt loop
    remRiders = [1,2,3,4];
    remRiders(riderDrop)=0;
    remRiders = remRiders(remRiders>0);
    wPrimeBalEnd(riderDrop)=0;
    wPrimeBalEnd2=wPrimeBalEnd(wPrimeBalEnd~=0);

    [~,I] = sort(wPrimeBalEnd2,'descend');
    strngRiderRank = 1:length(wPrimeBalEnd2);
    strngRiderRank(I) = strngRiderRank;

    strngRider1 = remRiders(strngRiderRank==1);
    strngRider2 = remRiders(strngRiderRank==2);
    strngRider3 = remRiders(strngRiderRank==3);



    % if the dropped rider was originally the finisher, add the 1/4 lap to the
    % last turn:
    if turnsRemove == turnCounter
        turnDurations2_0(end) = turnDurations2_0(end)+0.25;
    end
    turns2_0_checkSum = sum(turnDurations2_0);
    turns2_to_add = 16-turns2_0_checkSum;
    turns2_halfLaps_to_add = turns2_to_add * 2;

    % Re-distributing half laps
    turnDurations2_1 = turnDurations2_0;

    if turns2_halfLaps_to_add > 0
        if turns2_halfLaps_to_add == 1
            strngRider1_turns=find(turns2==strngRider1);
            turnDurations2_1(strngRider1_turns(end))=turnDurations2_1(strngRider1_turns(end))+0.5;
        elseif turns2_halfLaps_to_add == 2
            strngRider1_turns=find(turns2==strngRider1);
            strngRider2_turns=find(turns2==strngRider2);
            turnDurations2_1(strngRider1_turns(end))=turnDurations2_1(strngRider1_turns(end))+0.5;
            turnDurations2_1(strngRider2_turns(end))=turnDurations2_1(strngRider2_turns(end))+0.5;
        elseif turns2_halfLaps_to_add == 3
            strngRider1_turns=find(turns2==strngRider1);
            strngRider2_turns=find(turns2==strngRider2);
            strngRider3_turns=find(turns2==strngRider3);
            turnDurations2_1(strngRider1_turns(end))=turnDurations2_1(strngRider1_turns(end))+0.5;
            turnDurations2_1(strngRider2_turns(end))=turnDurations2_1(strngRider2_turns(end))+0.5;
            turnDurations2_1(strngRider3_turns(end))=turnDurations2_1(strngRider3_turns(end))+0.5;
        elseif turns2_halfLaps_to_add == 4
            strngRider1_turns=find(turns2==strngRider1);
            strngRider2_turns=find(turns2==strngRider2);
            strngRider3_turns=find(turns2==strngRider3);
            turnDurations2_1(strngRider1_turns(end))=turnDurations2_1(strngRider1_turns(end))+0.5;
            turnDurations2_1(strngRider1_turns(end-1))=turnDurations2_1(strngRider1_turns(end-1))+0.5;
            turnDurations2_1(strngRider2_turns(end))=turnDurations2_1(strngRider2_turns(end))+0.5;
            turnDurations2_1(strngRider3_turns(end))=turnDurations2_1(strngRider3_turns(end))+0.5;
        elseif turns2_halfLaps_to_add == 5
            strngRider1_turns=find(turns2==strngRider1);
            strngRider2_turns=find(turns2==strngRider2);
            strngRider3_turns=find(turns2==strngRider3);
            turnDurations2_1(strngRider1_turns(end))=turnDurations2_1(strngRider1_turns(end))+0.5;
            turnDurations2_1(strngRider1_turns(end-1))=turnDurations2_1(strngRider1_turns(end-1))+0.5;
            turnDurations2_1(strngRider2_turns(end))=turnDurations2_1(strngRider2_turns(end))+0.5;
            turnDurations2_1(strngRider2_turns(end-1))=turnDurations2_1(strngRider2_turns(end-1))+0.5;
            turnDurations2_1(strngRider3_turns(end))=turnDurations2_1(strngRider3_turns(end))+0.5;
        elseif turns2_halfLaps_to_add == 6
            strngRider1_turns=find(turns2==strngRider1);
            strngRider2_turns=find(turns2==strngRider2);
            strngRider3_turns=find(turns2==strngRider3);
            turnDurations2_1(strngRider1_turns(end))=turnDurations2_1(strngRider1_turns(end))+0.5;
            turnDurations2_1(strngRider1_turns(end-1))=turnDurations2_1(strngRider1_turns(end-1))+0.5;
            turnDurations2_1(strngRider2_turns(end))=turnDurations2_1(strngRider2_turns(end))+0.5;
            turnDurations2_1(strngRider2_turns(end-1))=turnDurations2_1(strngRider2_turns(end-1))+0.5;
            turnDurations2_1(strngRider3_turns(end))=turnDurations2_1(strngRider3_turns(end))+0.5;
            turnDurations2_1(strngRider3_turns(end-1))=turnDurations2_1(strngRider3_turns(end-1))+0.5;
        elseif turns2_halfLaps_to_add == 7
            strngRider1_turns=find(turns2==strngRider1);
            strngRider2_turns=find(turns2==strngRider2);
            strngRider3_turns=find(turns2==strngRider3);
            turnDurations2_1(strngRider1_turns(end))=turnDurations2_1(strngRider1_turns(end))+1;
            turnDurations2_1(strngRider1_turns(end-1))=turnDurations2_1(strngRider1_turns(end-1))+0.5;
            turnDurations2_1(strngRider2_turns(end))=turnDurations2_1(strngRider2_turns(end))+0.5;
            turnDurations2_1(strngRider2_turns(end-1))=turnDurations2_1(strngRider2_turns(end-1))+0.5;
            turnDurations2_1(strngRider3_turns(end))=turnDurations2_1(strngRider3_turns(end))+0.5;
            turnDurations2_1(strngRider3_turns(end-1))=turnDurations2_1(strngRider3_turns(end-1))+0.5;
        elseif turns2_halfLaps_to_add == 8
            strngRider1_turns=find(turns2==strngRider1);
            strngRider2_turns=find(turns2==strngRider2);
            strngRider3_turns=find(turns2==strngRider3);
            turnDurations2_1(strngRider1_turns(end))=turnDurations2_1(strngRider1_turns(end))+1;
            turnDurations2_1(strngRider1_turns(end-1))=turnDurations2_1(strngRider1_turns(end-1))+0.5;
            turnDurations2_1(strngRider2_turns(end))=turnDurations2_1(strngRider2_turns(end))+1;
            turnDurations2_1(strngRider2_turns(end-1))=turnDurations2_1(strngRider2_turns(end-1))+0.5;
            turnDurations2_1(strngRider3_turns(end))=turnDurations2_1(strngRider3_turns(end))+0.5;
            turnDurations2_1(strngRider3_turns(end-1))=turnDurations2_1(strngRider3_turns(end-1))+0.5;
        elseif turns2_halfLaps_to_add == 9
            strngRider1_turns=find(turns2==strngRider1);
            strngRider2_turns=find(turns2==strngRider2);
            strngRider3_turns=find(turns2==strngRider3);
            turnDurations2_1(strngRider1_turns(end))=turnDurations2_1(strngRider1_turns(end))+1;
            turnDurations2_1(strngRider1_turns(end-1))=turnDurations2_1(strngRider1_turns(end-1))+0.5;
            turnDurations2_1(strngRider2_turns(end))=turnDurations2_1(strngRider2_turns(end))+1;
            turnDurations2_1(strngRider2_turns(end-1))=turnDurations2_1(strngRider2_turns(end-1))+0.5;
            turnDurations2_1(strngRider3_turns(end))=turnDurations2_1(strngRider3_turns(end))+1;
            turnDurations2_1(strngRider3_turns(end-1))=turnDurations2_1(strngRider3_turns(end-1))+0.5;   
        elseif turns2_halfLaps_to_add == 10
            strngRider1_turns=find(turns2==strngRider1);
            strngRider2_turns=find(turns2==strngRider2);
            strngRider3_turns=find(turns2==strngRider3);
            turnDurations2_1(strngRider1_turns(end))=turnDurations2_1(strngRider1_turns(end))+1;
            turnDurations2_1(strngRider1_turns(end-1))=turnDurations2_1(strngRider1_turns(end-1))+1;
            turnDurations2_1(strngRider2_turns(end))=turnDurations2_1(strngRider2_turns(end))+1;
            turnDurations2_1(strngRider2_turns(end-1))=turnDurations2_1(strngRider2_turns(end-1))+0.5;
            turnDurations2_1(strngRider3_turns(end))=turnDurations2_1(strngRider3_turns(end))+1;
            turnDurations2_1(strngRider3_turns(end-1))=turnDurations2_1(strngRider3_turns(end-1))+0.5; 
        end

        checkSum16td2 = sum(turnDurations2_1);
        if checkSum16td2 ~= 16
            error('checkSum16td2')
        end

    end
end