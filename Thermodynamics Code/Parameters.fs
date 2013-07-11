namespace Simulator

module Parameters = 
    open Simulator.UnitsOfMeasure
    open Simulator.Material
    open Simulator.PhysicalConstants

    /// The initial cylinder element temperature
    let mutable InitialTemperature = RoomTemperature

    /// The ambient temperature of the environment
    let mutable EnvironmentTemperature = RoomTemperature

    /// The number of elements to simulate
    let mutable ElementQuantity = 30

    /// The length of the metal rod
    let mutable CylinderLength = 0.3<m>

    /// The radius of the metal rod
    let mutable CylinderRadius = 0.01<m>

    /// The heat output of the power resistor
    let mutable PowerSource = 20.0<W>

    /// Round to n decimal places when determining equilibrium states
    let mutable EquilibriumCutoffDigits = 5

    /// The amount of time to run the simulation for
    let mutable SimulationDuration = 2000.0<s>

    /// Proportionality coefficient between heat flow per unit area, q/A, and the thermodynamic driving force for the flow of heat
    let mutable HeatTransferCoefficient = 5.7<W m^-2 K^-1>

    /// The amount of time that should elapse between computations; Δt
    let mutable Step = 0.01<s>

    /// The material of the rod
    let mutable CylinderMaterial = 
        new Material(
            900.0<C>,
            200.0<k>,
            2700.0<kg/m^3>,
            0.11
            )

