#=

 This file implements the functions presented in the paper

 * [1] Wexler, A. and Hyland, R. W., "Formulations for the thermodynamic properties of the saturated phases of H2O from 173.15 K to 473.15 K", ASHRAE Transactions, 1983.

=#    

"""
    ```Pws_l(Tk)```

Saturation pressure of vapor pressure over liquid water.
This implements equation 17 from [1].

 * `Tk` Temperature in K
 * Output: Pa
"""
function Pws_l(Tk)
    
    exp((g[1] + Tk*(g[2] + Tk*(g[3] + Tk*(g[4]+Tk*g[5]))))/Tk + g[6]*log(Tk))
                    
end



"""
    ```Pws_s(Tk)```

Saturation pressure of vapor pressure over ice.
This implements equation 18 from [1].

 * `Tk` Temperature in K
 * Output: Pa
"""
function Pws_s(Tk)

  
    exp( (m[1] + Tk*(m[2] + Tk*(m[3] + Tk*(m[4] + Tk*(m[5] + Tk*m[6])))))/Tk + m[7] * log(Tk) )
end


"""
    ```Pws(Tk)```

Saturation pressure of vapor pressure over liquid water or ice.
This function calls either `Pws_l` or `Pws_s`. At a temperature of 
273.16 both expressions are almost exactly the same (6 decimal figures).

 * `Tk` Temperature in K
 * Output: Pa
"""
function Pws(Tk)
    if Tk < 273.16
        Pws_s(Tk)
    else
        Pws_l(Tk)
    end
        
end
   

"""
    ```dPws_s(Tk)```

Derivative of saturation pressure of vapor pressure over ice.
This implements the derivative of equation 18 from [1].

 * `Tk` Temperature in K
 * Output: Pa/K
"""
function dPws_s(Tk)
    x1 = Pws_s(Tk)
    x2 = 1.0/Tk*(m[7] - m[1]/Tk) + m[3] + Tk*(2*m[4] + Tk*(3*m[5] +4*m[6]*Tk))
  
    return x1*x2
end

"""
    ```dPws_s(Tk)```

Derivative of saturation pressure of vapor pressure over water.
This implements the derivative of equation 17 from [1].

 * `Tk` Temperature in K
 * Output: Pa/K
"""
function dPws_l(Tk)
    x1 = Pws_l(Tk)
    x2 = 1.0/Tk*(g[6] - g[1]/Tk) + g[3] + Tk*(2*g[4] + 3*g[5]*Tk)
    return x1*x2 
end


"""
    ```dPws(Tk)```

Derivative of saturation pressure of vapor pressure over liquid water and ice.
This combines the functions `dPws_l` and `dPws_s`.

 * `Tk` Temperature in K
 * Output: Pa/K
"""
function dPws(Tk)
    if Tk < 273.16
        dPws_s(Tk)
    else
        dPws_l(Tk)
    end
end
  

const gg = (2.127925e2, 7.305398e0, 1.969953e-1, 1.103701e-2, 1.849307e-3, 5.145087e-6)

"""
    ```Tws(P)```

Calculates the saturation temperature of water vapor. 
This function is the inverse of function `Pws(T)`. 
First an approximation was obtained and then a Newton
iteration is used to obtain more accurate data.

 * `P` Saturation pressure in Pa
 * Output: Saturation temperature in K.
"""
function Tws(P)

    lnP = log(P)
    T = gg[1] + lnP * (gg[2] + lnP*(gg[3] + lnP*(gg[4] + lnP*gg[5]))) + gg[6] * P

    NMAX = 100
    EPS = 1e-11

    for i = 0:NMAX
        f = P - Pws(T)
        df = -dPws(T)
        dT = -f / df
        T += dT

        if abs(dT) < EPS
            return T
        end
    end

    return T
end

"""
    volumeice(Tk)

Specific volume of saturated ice. Equation 2 from ref. [1].

 * `Tk` Temperature in K.
 * Output: specific volume in m^3/kg
"""
volumeice(Tk) = 0.1070003e-2 + Tk*(-0.249936e-7 + 0.371611e-9*Tk)


"""
    enthalpyice(Tk)

Specific enthalpy of saturated ice. Equation 3 of ref. [1].

 * `Tk` Temperature in K
 * Output: J/kg

"""
function enthalpyice(Tk)

    -0.647595E6 + Tk*(0.274292e3 + Tk*(0.2910583e1 + Tk*0.1083437e-2)) + 0.107e-2*Pws_s(Tk)
    
end


const L = (-0.11411380e7, 0.41930463e4, -0.8134865e-1,
           0.1451133e-3, -0.1005230e-6, -0.563473e3, -0.036)
const M = (-0.1141837121e7, 0.4194325677e4, -0.6908894163e-1,
           0.105555302e-3, -0.7111382234e-7, 0.6059e-3)

"""
    enthalpywater(Tk)

Specific enthalpy of saturated water. Equations 6-11 of ref. [1].

 * `Tk` Temperature in K
 * Output: J/kg

"""
function enthalpywater(Tk)
    β₀ = Tk * volumewater(273.16) * dPws_l(273.16)
    β = Tk * volumewater(Tk) * dPws_l(Tk) 

    if Tk < 373.125
        α = L[1] + Tk*(L[2] + Tk*(L[3] + Tk*(L[4] + Tk*L[5]))) +
            L[6] * 10^(L[7] * (Tk - 273.16))
    else 
        α = M[1] + Tk*(M[2] + Tk*(M[3] + Tk*(M[4] + Tk*M[5])))
        if Tk > 403.128
            α = α - M[6]*(Tk - 403.128)^3.1
        end
    end
    
    return α + β - β₀
end


"""
    enthalpyvapor(Tk)

Specific enthalpy of saturated water vapor. Equation 19 of ref. [1].

 * `Tk` Temperature in K
 * Output: J/kg

"""
function enthalpyvapor(Tk)

    termo1 = 0.199798e7 + Tk*(0.18035706e4 +
                              Tk*(0.36400463e0 +
                                  Tk*(-0.14677622e-2 + Tk*(0.28726608e-5 - Tk*0.17508262e-8))))
    p = Pws(Tk)
    return termo1 - R*Tk*Tk*p*(dBlin(Tk) + 0.5*dClin(Tk)*p)
end




"""
    densitywater(Tk)

Density of saturated water. Equation 5 from ref. [1].

 * `Tk` Temperature in K.
 * Output: density kg/m^3
"""
densitywater(Tk) = ( -0.2403360201e4 +
                     Tk*(-0.140758895e1 +
                         Tk * (0.1068287657e0 +
                               Tk*(-0.2914492351e-3 + Tk*(0.373497936e-6 - Tk*0.21203787e-9))))) /
                               ( -0.3424442728e1 + 0.1619785e-1*Tk )

                               
"""
    volumewater(Tk)

Specific volume of saturated water. Inverse of equation 5 from ref. [1].

 * `Tk` Temperature in K.
 * Output: specific volume in m^3/kg
"""
volumewater(Tk) = 1.0 / densitywater(Tk)



"""
    ```Blin(Tk)```

Virial coefficient B' saturated vapor eq 15 [1]

 * `Tk` Temperature in K
 * Output: B' in Pa^(-1)
"""
Blin(Tk) = 0.70e-8 - 0.147184e-8 * exp(1734.29/Tk) # Pa^(-1)

"""
Second virial coefficient C' saturated vapor eq 16 [1]

 * `Tk` Temperature in K
 * Output: B' in Pa^(-2)
"""
Clin(Tk) = 0.104e-14 - 0.335297e-17*exp(3645.09/Tk) # Pa^(-2)


"""
    ```dBlin(Tk)```

Derivative of virial coefficient dB'/dT saturated vapor eq 15 [1]

 * `Tk` Temperature in K
 * Output: B' in Pa^(-1)/K
"""
dBlin(Tk) = 2.5525974e-6/(Tk*Tk) * exp(1734.29/Tk)


"""
    ```dClin(Tk)```

Derivative of Second virial coefficient dC'/dT saturated vapor eq 16 [1]

 * `Tk` Temperature in K
 * Output: B' in Pa^(-2)/K
"""
dClin(Tk) = 1.2221877e-14/(Tk*Tk) * exp(3645.09/Tk)
