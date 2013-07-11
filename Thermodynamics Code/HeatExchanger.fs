namespace Simulator

/// Contains type definitions for the simulation
module HeatExchanger =  

    open System
    open Simulator.UnitsOfMeasure
    open Simulator.PhysicalConstants
    open Simulator.Material

    /// An object capable of thermal transfer
    type HeatExchanger (material:Material, temperature:float<K>, radius:float<m>, length) = 
        let mutable temperature = temperature
        /// The temperature of the cylinder section
        member this.Temperature 
            with get() = temperature 
            and set (value) = temperature <- value
        /// The cross sectional area of the cylinder section
        member this.Area:float<m^2> = radius * radius * Math.PI
        /// The surface area of the cylinder section. This does not include cylinder bases
        member this.SurfaceArea:float<m^2> = 2.0 * Math.PI * radius * length
        /// The mass of the cylinder section
        member this.Mass:float<kg> = length * this.Area * material.Density 
        /// The cylinder section material
        member this.Material = material
        /// The length of the cylinder section
        member this.Length:float<m> = length
        /// Adds the specified number of joules and adjusts the temperature accordingly
        member this.AddJoules (joules:float<J>) = this.Temperature <- this.Temperature + joules / (this.Material.SpecificHeat * this.Mass)
        /// Convects heat to the surrounding air
        member this.Convect(convectionTime:float<s>) =
            let watts = Parameters.HeatTransferCoefficient * this.SurfaceArea * (temperature - Parameters.EnvironmentTemperature)
            let q  = -watts * convectionTime
            this.AddJoules q
        /// Radiates away heat for the specified amount of time
        member this.Radiate(radiationTime:float<s>) =
            let netT = temperature - Parameters.EnvironmentTemperature 
            let watts = this.Material.Emissivity * StefanBoltzmannConstant * netT * netT * netT * netT * this.SurfaceArea
            let q = -watts * radiationTime
            this.AddJoules q