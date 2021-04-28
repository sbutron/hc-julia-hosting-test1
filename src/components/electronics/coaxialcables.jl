function Coax_RG58(sim_environment::Environment; length::Real)::SubCircuitAB
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    length = convert(Float64, length)
    cap = Capacitor(sim_environment, 82e-12 * length, "RG58 Capacitance")
    res = Resistor_Ideal(sim_environment, 50.0, "RG58 Impedance")
    connect!(sim_environment, res.pin_2, cap.pin_1)
    connect!(sim_environment, cap.pin_2, :gnd)
    SubCircuitAB(sim_environment;
    info = "$length m RG-58 Coaxial Cable",
    components = [cap, res],
    pin_input = res.pin_1,
    pin_output = res.pin_2,
    )
end
