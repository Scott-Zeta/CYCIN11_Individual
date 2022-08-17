function wPrimeBal = F_wPrimeBal(dt, powerDiff, wPrimeBalPrev, wPrime)
    if powerDiff <=0 %i.e. depletion
        wPrimeBal = wPrimeBalPrev - (-powerDiff * dt);
    elseif powerDiff > 0 %i.e. recovery
        tw = 2287.2 * powerDiff ^-0.688;
        wPrimeBal = wPrime - (wPrime-wPrimeBalPrev)*exp(-dt/tw);
    end