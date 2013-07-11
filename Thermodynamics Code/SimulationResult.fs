namespace Simulator

[<AutoOpenAttribute()>]
module SimulationResult =
    open UnitsOfMeasure

    type Result = 
        {
        data: float[]
        duration: float<s>
        equilibriumReached: bool
        }

