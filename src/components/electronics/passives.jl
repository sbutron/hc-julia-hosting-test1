function Resistor_Ideal(sim_environment::Environment, value::Real, info::String)
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    element = ACME.add!(sim_environment.schematic.circuit, ACME.resistor(value))
    component = Resistor(sim_environment::Environment,
    element::Symbol,
    info::String,
    (element, 1)::Tuple{Symbol,Any},
    (element, 2)::Tuple{Symbol,Any}
    )
    return component
end

function Resistor_Noisy(sim_environment::Environment, value::Real, info::String)
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    value::Float64 = value
    resistor = Resistor_Ideal(sim_environment, value, "$value Ω resistor")# create resistor element
    johnson_noise = johnson_noise_rms(value, sim_environment.temperature, sample_interval_to_bandwidth(sim_environment.schematic.sample_interval)) # determine resistor Johnson noise rms
    current_source = NoiseCurrentSource(sim_environment, Normal(0, johnson_noise), "Noise current for $info") # create source
    connect!(sim_environment, resistor.pin_1, current_source.pin_negative) # connect noise current in parallel with resistor
    connect!(sim_environment, resistor.pin_2, current_source.pin_positive) # connect noise current in parallel with resistor
    return resistor
end
