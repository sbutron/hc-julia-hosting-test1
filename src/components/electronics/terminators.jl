function Terminator_Ω(sim_environment::Environment; resistance::Float64)::SubCircuitAB
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    res = Resistor_Noisy(sim_environment, resistance, "$resistance Ω resistor")
    connect!(sim_environment, res.pin_1, :gnd)
    SubCircuitAB(sim_environment;
    info = "$resistance Ω terminator",
    components = [res],
    pin_input = res.pin_2,
    pin_output = res.pin_2
    )
end

function Terminator_50Ω(sim_environment::Environment)::SubCircuitAB
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    res = Resistor_Noisy(sim_environment, 50.0, "50Ω resistor")
    connect!(sim_environment, res.pin_1, :gnd)
    SubCircuitAB(sim_environment;
    info = "50Ω terminator",
    components = [res],
    pin_input = res.pin_2,
    pin_output = res.pin_2
    )
end

function Terminator_1kΩ(sim_environment::Environment)::SubCircuitAB
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    res = Resistor_Noisy(sim_environment, 1e3, "1kΩ resistor")
    connect!(sim_environment, res.pin_1, :gnd)
    SubCircuitAB(sim_environment;
    info = "50Ω terminator",
    components = [res],
    pin_input = res.pin_2,
    pin_output = res.pin_2
    )
end

function Terminator_1MΩ(sim_environment::Environment)::SubCircuitAB
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    res = Resistor_Noisy(sim_environment, 1e6, "50Ω resistor")
    connect!(sim_environment, res.pin_1, :gnd)
    SubCircuitAB(sim_environment;
    info = "50Ω terminator",
    components = [res],
    pin_input = res.pin_2,
    pin_output = res.pin_2
    )
end
