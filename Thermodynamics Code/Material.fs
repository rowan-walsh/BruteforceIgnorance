namespace Simulator

module Material = 

    open System
    open Simulator.UnitsOfMeasure
    open Simulator.PhysicalConstants

    /// A material with thermodynamic properties
    type Material(specificHeat, conductance, density, emissivity) =
        member this.SpecificHeat : float<C> = specificHeat
        member this.Conductance : float<k> = conductance
        member this.Density : float<kg/m^3> = density
        member this.Emissivity : float = emissivity
