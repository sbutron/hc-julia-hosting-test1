function LowPassRC(sim_environment::Environment; resistance::Real, capacitance::Real)::SubCircuitAB
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    resistance::Float64 = resistance
    capacitance::Float64 = capacitance
    res = Resistor_Noisy(sim_environment, resistance, "$resistance resistor")
    cap = Capacitor(sim_environment, capacitance, "$capacitance capacitance")
    connect!(sim_environment, res.pin_2, cap.pin_1)
    connect!(sim_environment, cap.pin_2, :gnd)

    SubCircuitAB(sim_environment;
    info = "$resistance Ω * $capacitance F RC Filter",
    components = [res, cap],
    pin_input = res.pin_1,
    pin_output = cap.pin_1
    )
end
function LowPassFilter(sim_environment::Environment; freq_cutoff::Real)::SubCircuitAB
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    freq_cutoff::Float64 = freq_cutoff
    res = 1 / (2 * pi * freq_cutoff * 1e-9)
    LowPassRC(sim_environment; resistance = res, capacitance = 1e-9)
end
function LowPassRC_15kHz(sim_environment::Environment)::SubCircuitAB
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    LowPassRC(sim_environment; resistance = 1e3, capacitance = 1e-9)
end

function LowPassButterworth3(sim_environment::Environment; freq_cutoff::Real)::SubCircuitAB
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    freq_cutoff::Float64 = freq_cutoff
    r = 10e3
    c = 1/(2 * pi * freq_cutoff * r)
    r1 = Resistor_Noisy(sim_environment, r, "$r resistor")
    r2 = Resistor_Noisy(sim_environment, r, "$r resistor")
    r3 = Resistor_Noisy(sim_environment, 1e3, "1k resistor")
    r4 = Resistor_Noisy(sim_environment, 1e3, "1k resistor")
    r5 = Resistor_Noisy(sim_environment, r, "$r resistor")
    c1 = Capacitor(sim_environment, c, "$c resistor")
    c2 = Capacitor(sim_environment, c, "$c resistor")
    c3 = Capacitor(sim_environment, c, "$c resistor")
    u1 = IdealOpAmp(sim_environment)
    connect!(sim_environment, r1.pin_2, r2.pin_1, c1.pin_1)
    connect!(sim_environment, r2.pin_2, c2.pin_1, u1.pin_in_pos)
    connect!(sim_environment, c1.pin_2, u1.pin_out_pos, r3.pin_1, r5.pin_1)
    connect!(sim_environment, r3.pin_2, u1.pin_in_neg, r4.pin_1)
    connect!(sim_environment, r5.pin_2, c3.pin_1)
    connect!(sim_environment, :gnd, c2.pin_2, r4.pin_2, c3.pin_2, u1.pin_out_neg)
    SubCircuitAB(sim_environment;
    info = "$freq_cutoff Third-Order Butterwork Low Pass Filter",
    components = [],
    pin_input = r1.pin_1,
    pin_output = r5.pin_2
    )
end
