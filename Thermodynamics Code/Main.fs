
namespace Simulator

module Main =
    
    open System
    open Microsoft.FSharp.Math
    open System.Drawing
    open Microsoft.FSharp.Collections
    open System.Linq
    open Simulator.UnitsOfMeasure
    open Simulator.Material
    open Simulator.HeatExchanger
    open Simulator.Parameters
    open Simulator.SimulationResult
    open Simulator.PhysicalConstants
    open System.Diagnostics
    open System.IO
   
    /// Returns an array that only contains the temperature values of the input HeatExchanger[]
    /// This might be useful for writing to a file
    let GetTemperatureValues (x:HeatExchanger[]) : float[] = 
        x |> Array.map(fun i -> float i.Temperature)

    /// Runs the sink simulation, returns data as a HeatExchanger[] tupled with elasped time
    let SinkSimulation(simulateRadiation, simulateConvection) = 
        let coldSink = InitialTemperature
        let hotSink = InitialTemperature + 20.0<K>
        let crossSectionalArea = CylinderRadius * CylinderRadius * System.Math.PI
        let elements = 
            Array.init ElementQuantity 
                (fun i -> new HeatExchanger(CylinderMaterial, InitialTemperature, CylinderRadius, CylinderLength / float ElementQuantity))

        // Recursively runs the simulation and outputs the results and the elapsed time
        let rec Run (x:HeatExchanger[]) (time:float<s>) = 
            if time > SimulationDuration then
                (Array.rev x, time - Step)
            else
                let beforeTemps = Array.map(fun (el:float) -> Math.Round(el, EquilibriumCutoffDigits)) (GetTemperatureValues x)
                System.Threading.Tasks.Parallel.For(0, x.Length - 1, (fun i ->
                    if simulateRadiation then x.[i].Radiate Step
                    if simulateConvection then x.[i].Convect Step
                    if i = 0 then
                        let Qin = (hotSink - x.[i].Temperature) * Step * x.[i].Material.Conductance * (x.[i].Area / x.[i].Length)
                        let Qout = (x.[i].Temperature - x.[i+1].Temperature) * Step * x.[i].Material.Conductance * (x.[i].Area / x.[i].Length)
                        let netQ = Qin - Qout
                        x.[i].AddJoules netQ
                    else if i = x.Length - 1 then
                        let Qin = (x.[i-1].Temperature - x.[i].Temperature) * Step * x.[i].Material.Conductance * (x.[i].Area / x.[i].Length)
                        let Qout = (x.[i].Temperature - coldSink) * Step * x.[i].Material.Conductance * (x.[i].Area / x.[i].Length)
                        let netQ = Qin - Qout
                        x.[i].AddJoules netQ
                    else
                        let Qin = (x.[i-1].Temperature - x.[i].Temperature) * Step * x.[i].Material.Conductance * (x.[i].Area / x.[i].Length)
                        let Qout = (x.[i].Temperature - x.[i+1].Temperature) * Step * x.[i].Material.Conductance * (x.[i].Area / x.[i].Length)
                        let netQ = Qin - Qout
                        x.[i].AddJoules netQ)) |> ignore
                let afterTemps = Array.map(fun (el:float) -> Math.Round(el, EquilibriumCutoffDigits)) (GetTemperatureValues x)
                if time <> 0.0<s> && Enumerable.SequenceEqual(beforeTemps, afterTemps) then
                    (Array.rev x, time)
                else
                    Run x (time + Step)
        Run elements 0.0<s>
    
    let TimeSimulation(simulateRadiation, simulateConvection) = 
        let element =  new HeatExchanger(CylinderMaterial, InitialTemperature, CylinderRadius, CylinderLength / float ElementQuantity)
        let mutable times:float[] = [|float InitialTemperature|]
        for i in 0 .. int SimulationDuration do
            if simulateRadiation then element.Radiate(Step)
            if simulateConvection then element.Convect(Step)
            times <- (Array.append times [| float element.Temperature |])
        { data = times; duration = SimulationDuration; equilibriumReached = true}

    /// Runs the power source simulation, returns data as a HeatExchanger[] tupled with elapsed time
    let PowerSourceSimulation(simulateRadiation, simulateConvection) = 
        let elements = 
            Array.init ElementQuantity 
                (fun i -> new HeatExchanger(CylinderMaterial, InitialTemperature, CylinderRadius, CylinderLength / float ElementQuantity))

        // Recursively runs the simulation and outputs the results
        let rec Run (x:HeatExchanger[]) (time:float<s>) = 
            if time > SimulationDuration then
                (Array.rev x, time - Step)
            else
                let beforeTemps = Array.map(fun (el:float) -> Math.Round(el, EquilibriumCutoffDigits)) (GetTemperatureValues x)
                System.Threading.Tasks.Parallel.For(0, x.Length - 1, (fun i ->
                    if simulateRadiation then x.[i].Radiate Step
                    if simulateConvection then x.[i].Convect Step
                    if i = 0 then
                        let Qin = PowerSource * Step
                        let Qout = (x.[i].Temperature - x.[i+1].Temperature) * Step * x.[i].Material.Conductance * (x.[i].Area / x.[i].Length)
                        let netQ = Qin - Qout
                        x.[i].AddJoules netQ
                    else if i = x.Length - 1 then
                        let Qin = (x.[i-1].Temperature - x.[i].Temperature) * Step * x.[i].Material.Conductance * (x.[i].Area / x.[i].Length)
                        let Qout = (x.[i].Temperature - InitialTemperature) * Step * x.[i].Material.Conductance * (x.[i].Area / x.[i].Length)
                        let netQ = Qin - Qout
                        x.[i].AddJoules netQ
                    else
                        let Qin = (x.[i-1].Temperature - x.[i].Temperature) * Step * x.[i].Material.Conductance * (x.[i].Area / x.[i].Length)
                        let Qout = (x.[i].Temperature - x.[i+1].Temperature) * Step * x.[i].Material.Conductance * (x.[i].Area / x.[i].Length)
                        let netQ = Qin - Qout
                        x.[i].AddJoules netQ
                        )) |> ignore
                let afterTemps = Array.map(fun (el:float) -> Math.Round(el, EquilibriumCutoffDigits)) (GetTemperatureValues x)
                if time <> 0.0<s> && Enumerable.SequenceEqual(beforeTemps, afterTemps) then
                    (Array.rev x, time)
                else
                    Run x (time + Step)
        Run elements 0.0<s>

    /// Simulates a power source and returns the results
    let SimulatePowerSource(simulateRadiation, simulateConvection) = 
        let simulationResults = PowerSourceSimulation(simulateRadiation, simulateConvection)
        let dataPoints = GetTemperatureValues(fst simulationResults)
        let elapsedTime = snd simulationResults
        { data = dataPoints; duration = elapsedTime; equilibriumReached = (elapsedTime < SimulationDuration)}

    /// Simulates fixed temperature sinks and returns the results
    let SimulateSink(simulateRadiation, simulateConvection) = 
        let simulationResults = SinkSimulation(simulateRadiation, simulateConvection)
        let dataPoints = GetTemperatureValues(fst simulationResults)
        let elapsedTime = snd simulationResults
        { data = dataPoints; duration = elapsedTime; equilibriumReached = (elapsedTime < SimulationDuration)}

    /// Writes the results to a file
    let export (powerTemperatures:HeatExchanger[], powerTime:float<s>) powerFilename (sinkTemperatures:HeatExchanger[], sinkTime:float<s>) sinkFilename = 
        let mutable powerText = powerTime.ToString()
        for temperature in powerTemperatures do
            powerText <- powerText + "\t" + (temperature.Temperature.ToString())
        
        let mutable sinkText = sinkTime.ToString()
        for temperature in sinkTemperatures do 
            sinkText <- sinkText + "\t" + (temperature.Temperature.ToString())

        File.AppendAllText(powerFilename, powerText)
        File.AppendAllText(sinkFilename, sinkText)  

    let exportFinalValues (temperatures:float[]) (directory:string) = 
        let filename = Path.Combine(directory, DateTime.Today.ToString("yyyy-mm-dd") + " Simulation Data.txt")
        let mutable data = ""
        for temperature in temperatures do
            data <- data + temperature.ToString() + "\t"
        File.AppendAllText(filename, data)


//    [<EntryPoint>]
//    let main args =
//        let powerData = PowerSourceSimulation()
//        let sinkData = SinkSimulation()
//        export powerData "power.txt" sinkData "sink.txt"
//
//        let sinkEquilibriumTemperatures = fst sinkData
//        let sinkEquilibriumTime = snd sinkData
//
//        let powerEquilibriumTemperatures = fst powerData
//        let powerEquilibriumTime = snd powerData
//        0
//
//
//    