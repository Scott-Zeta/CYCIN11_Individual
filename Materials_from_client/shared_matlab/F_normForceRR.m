function [fRR_frt, fRR_rr] = F_normForceRR(velCoM, radCoM, leanAngleDeg, mass, weightDist, bankAngle, muScrub, crrF, crrR)

fNormal = mass*(velCoM^2/radCoM*sind(leanAngleDeg))+(mass*9.81*cosd(leanAngleDeg));

fNormalFrt = fNormal *weightDist;
fNormalRr = fNormal *(1-weightDist);

bankAngleDeg = rad2deg(bankAngle);
betaDash = 90-bankAngleDeg;
leanAngleFromHorizontal = 90-leanAngleDeg;
sigma = abs(leanAngleFromHorizontal-betaDash);

fRR_frt = fNormalFrt*crrF*(1+(muScrub*sigma));
fRR_rr = fNormalRr*crrR*(1+(muScrub*sigma));
