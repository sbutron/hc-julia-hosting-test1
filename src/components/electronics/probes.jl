function Probe_Voltage(sim_environment::Environment; probe_label::String)::SubCircuitAB
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    probe = VoltageProbe(sim_environment, probe_label)
    connect!(sim_environment, probe.pin_negative, :gnd)
    SubCircuitAB(sim_environment;
    info = "Voltage Probe: $probe_label",
    components = [probe],
    pin_input = probe.pin_positive,
    pin_output =probe.pin_positive,
    )
end
function Probe_Current(sim_environment::Environment; probe_label::String)::SubCircuitAB
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    probe = CurrentProbe(sim_environment, probe_label)
    SubCircuitAB(sim_environment;
    info = "Current Probe: $probe_label",
    components = [probe],
    pin_input = probe.pin_positive,
    pin_output = probe.pin_negative,
    )
end
function Oscilloscope_1MΩ(sim_environment::Environment; probe_label::String)::SubCircuitAB
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    probe = VoltageProbe(sim_environment, probe_label)
    res = Resistor_Noisy(sim_environment, 1e6, "Scope Termination")
    cap = Capacitor(sim_environment, 50e-12, "Scope Capacitance")
    connect!(sim_environment, probe.pin_positive, res.pin_1, cap.pin_1)
    connect!(sim_environment, probe.pin_negative, res.pin_2, cap.pin_2, :gnd)
    SubCircuitAB(sim_environment;
    info = "1MΩ Oscilloscope: $probe_label",
    components = [probe, res, cap],
    pin_input = probe.pin_positive,
    pin_output =probe.pin_positive,
    )
end
function Oscilloscope_1kΩ(sim_environment::Environment; probe_label::String)::SubCircuitAB
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    probe = VoltageProbe(sim_environment, probe_label)
    res = Resistor_Noisy(sim_environment, 1e3, "Scope Termination")
    cap = Capacitor(sim_environment, 50e-12, "Scope Capacitance")
    connect!(sim_environment, probe.pin_positive, res.pin_1, cap.pin_1)
    connect!(sim_environment, probe.pin_negative, res.pin_2, cap.pin_2, :gnd)
    SubCircuitAB(sim_environment;
    info = "1kΩ Oscilloscope: $probe_label",
    components = [probe, res, cap],
    pin_input = probe.pin_positive,
    pin_output =probe.pin_positive,
    )
end
function Oscilloscope_50Ω(sim_environment::Environment; probe_label::String)::SubCircuitAB
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    probe = VoltageProbe(sim_environment, probe_label)
    res = Resistor_Noisy(sim_environment, 50.0, "Scope Termination")
    cap = Capacitor(sim_environment, 50e-12, "Scope Capacitance")
    connect!(sim_environment, probe.pin_positive, res.pin_1, cap.pin_1)
    connect!(sim_environment, probe.pin_negative, res.pin_2, cap.pin_2, :gnd)
    SubCircuitAB(sim_environment;
    info = "50Ω Oscilloscope: $probe_label",
    components = [probe, res, cap],
    pin_input = probe.pin_positive,
    pin_output =probe.pin_positive,
    )
end
