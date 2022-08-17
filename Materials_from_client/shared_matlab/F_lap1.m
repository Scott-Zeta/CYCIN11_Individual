function [v250, energyLap1, powerIn250,splitb2bHl]  = F_lap1(timeLap1,mass,CDAStand,CDASit,crr,mechEff,startPos,rho,timeStand)
% v1 John Pitman 9/08/2022
% iteratively scales a prescribed lap 1 power profile to give target lap 1 time
% v2 additions 12/08/2022:
    % report out final timestep power input 
% inputs:
%   timeLap1 = target lap time, sec
%   mass = total mass, kg
%   CDAStand = standing CDA, m^2
%   CDASit = seated CDA, m^2
%   crr = tyre rolling resistance coefficient
%   mechEff = mechanical efficiency
%   startPos = 1(gate)/2/3/4
%   rho = air density, kg/m^3
%   timeStand = time after start to seated position
% outputs: 
%   v250 = terminal velocity, m/sec
%   energyLap1 = energy requirement, J

draftVals = [0.96 0.8 0.7 0.6];% empirical drafting factors / start position
lap1ScrubbingFactor = 1.05; %lap 1 tyre scrubbing factor

distUpTrack = startPos -1;
straightSlopeAngle = 12; %degrees
run25m = sqrt(distUpTrack^2+25^2);
rise25m = -distUpTrack * sin(deg2rad(straightSlopeAngle));
slope25m = rise25m/run25m;
typicalLap1Dist = 250.5;
nomQtrLap = typicalLap1Dist/4;
actualQtrLapforPos = nomQtrLap - 25 + run25m;
actualLapforPos = typicalLap1Dist - 25 + run25m;

dtime = 0.1;
First_Lap_Poly = @(x) -0.00000209*x.^6 + 0.00046936*x.^5 - 0.04095257*x.^4+ 1.75290819*x.^3 - 37.78916029*x.^2 + 353.56482552*x + 0.56673857 ; 
powerScale = 1; % Will be used to subsequently scale the value from polynomial to get the target time
stopper = 1;

% 'Outer' while loop that scales the power profile up or down in order to
% match the target lap 1 time

while stopper == 1 

    %pre-allocate vectors
    fnTime = zeros(10000,1);
    fnSpeed = zeros(10000,1);
    fnSlopePower = zeros(10000,1);
    fnAeroPower = zeros(10000,1);
    fnRollPower = zeros(10000,1);
    fnPowerIn = zeros(10000,1);
    fnNetPower = zeros(10000,1);
    fnPropForce = zeros(10000,1);
    fnAccel = zeros(10000,1);
    fnDistance = zeros(10000,1);
    fnEnergy = zeros(10000,1);


    %initial values at first timestep

    fnSpeed(1) = 0.1;
    fnSlopePower(1)= mass*slope25m*9.81*fnSpeed(1);
    fnAeroPower(1)=0.5*rho*fnSpeed(1)^3*CDAStand;
    fnRollPower(1)=crr*mass*9.81*fnSpeed(1);
    fnPowerIn(1) = powerScale*First_Lap_Poly(0);
    fnNetPower(1) = fnPowerIn(1)*mechEff - fnSlopePower(1) - fnAeroPower(1)...
        - fnRollPower(1);
    fnPropForce(1) = fnNetPower(1)/fnSpeed(1);
    fnAccel(1) = fnPropForce(1)/mass;
    fnDistance(1)=fnSpeed(1)*dtime;
    fnEnergy(1)=fnPowerIn(1)*dtime;

    % subsequent timesteps in 'inner' while loop till > 250m
    counter =2;

        while max(fnDistance)<250

            fnTime(counter)=fnTime(counter-1)+dtime;
            fnSpeed(counter)=fnSpeed(counter-1)+fnAccel(counter-1)*dtime;
            fnDistance(counter) = fnDistance(counter-1)+fnSpeed(counter)*dtime;

            % Slope power for first 25m

            if fnDistance(counter) < run25m            
                fnSlopePower(counter)= mass*slope25m*9.81*fnSpeed(counter);
            else fnSlopePower(counter) = 0;
            end

            % Aero power standing/seated - time dependent, with pos-dependent drafting factor 
            if fnTime(counter)<timeStand
                fnAeroPower(counter)= 0.5*rho*fnSpeed(counter)^3*CDAStand*draftVals(startPos);
            else 
                fnAeroPower(counter)= 0.5*rho*fnSpeed(counter)^3*CDASit*draftVals(startPos);
            end

            % Rolling resistance power. No lean angle effects. Applies
            % multiplier to account for average lap 1 scrubbing effect

            fnRollPower(counter)=lap1ScrubbingFactor*crr*mass*9.81*fnSpeed(counter);

            % Lookup power input value
            fnPowerIn(counter)=powerScale*First_Lap_Poly(fnTime(counter));

            % Power balance
            fnNetPower(counter)= fnPowerIn(counter)*mechEff -...
                fnSlopePower(counter) - fnAeroPower(counter)- fnRollPower(1);

            % Propulsive force
            fnPropForce(counter) = fnNetPower(counter)/fnSpeed(counter);

            % Acceleration
            fnAccel(counter) = fnPropForce(counter)/mass;

            % Energy (cumulative)
            fnEnergy(counter)=fnEnergy(counter-1)+ fnPowerIn(counter)*dtime;

            counter = counter+1;
        end


    timeDiff = fnTime(counter-1)-timeLap1;

    if timeDiff < 0.01 && timeDiff > -0.01
        stopper = 2;
    end

    if timeDiff > 0 %if too slow
        powerScale = powerScale+0.001;
    elseif timeDiff < 0 %if too fast
        powerScale = powerScale-0.001;
    end

time625=fnTime(find(fnDistance > 62.5, 1));
time1875 = fnTime(find(fnDistance > 187.5, 1));
splitb2bHl = time1875-time625;
v250 = fnSpeed(counter-1);
energyLap1 = fnEnergy(counter-1);
powerIn250 = fnPowerIn(counter-1);
    
end
            
            
            
            
            
            
            
            
            
   