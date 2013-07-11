namespace Simulator

/// Contains type definitions for a number of SI units.
module UnitsOfMeasure =
    /// Joule
    [<Measure>] type J
    /// Second
    [<Measure>] type s
    /// Watt
    [<Measure>] type W = J/s
    /// Meter
    [<Measure>] type m
    // Kilogram
    [<Measure>] type kg
    /// Kelvin
    [<Measure>] type K
    /// Thermal Conductivity
    [<Measure>] type k = W / (m * K)
    /// Heat Capacity
    [<Measure>] type c = J / K
    /// Specific Heat
    [<Measure>] type C = J / (kg * K)

/// Physical constants
module PhysicalConstants = 
    open UnitsOfMeasure

    /// Stefan-Boltzmann Constant for radiation
 //   let StefanBoltzmannConstant = System.Math.Pow(5.670373, -8.0) * 1.0<W m^-2 K^-4>
    let StefanBoltzmannConstant = System.Math.Pow(4.12, -7.0) * 1.0<W m^-2 K^-4>

    /// Standard room temperature (25degC)
    let RoomTemperature = 298.15<K>