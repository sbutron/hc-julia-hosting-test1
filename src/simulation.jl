##

## Abstract representation of the ArbMatrix as information
# module Simulation
# using Distributions
# using SparseArrays
# using StaticArrays
# include("./geometry.jl")
# include("./math_ops.jl")
# include("./matrix_functions.jl")
# include("./temporal.jl")
# include("./arbmatrix.jl")
# using .ArbMatrix
# export Detector, LightSource, Environment, Photon, PMT, SiPM, FocusedSource
##
"""Base abstract class of Detector"""
abstract type Detector
end
abstract type LightSource
end
abstract type OpticalComponent
end
abstract type OpticalFilter <: OpticalComponent
end
abstract type NonOpticalDevice
end
abstract type ElectricalComponent
end
abstract type ElectricalSubCkt <: ElectricalComponent
end
abstract type ElectricalSource <: ElectricalComponent
end

mutable struct Photon
    x::Float64
    y::Float64
    λ::Float64
    function Photon(x::Real, y::Real, λ::Real)
        new(x, y, λ)
    end
end

mutable struct Schematic
    circuit::ACME.Circuit
    model_runner::Union{Nothing, ACME.ModelRunner{ACME.DiscreteModel{Tuple{}},false}}
    inputs::Array{Float64}
    sources::Vector{Any}
    probes::Vector{Any}
    sample_interval::Float64
    probe_labels::Array{String}
    stats_probe_outputs::Array{Float64}
    plot::Any
    function Schematic(simulation_length::Integer, sample_interval::Float64)
        circuit = ACME.Circuit()
        model_runner = nothing
        inputs =  Array{Float64}(undef, simulation_length,0)
        probe_labels = Array{String}(undef,1,0)
        stats_probe_outputs =  Array{Float64}(undef, 0, simulation_length)
        sources = []
        probes = []
        plot = nothing
        new(circuit::ACME.Circuit,
        model_runner::Union{Nothing, ACME.ModelRunner{ACME.DiscreteModel{Tuple{}},false}},
        inputs::Array{Float64},
        sources::Array{Any},
        probes::Array{Any},
        sample_interval::Float64,
        probe_labels::Array{String},
        stats_probe_outputs::Array{Float64},
        plot::Any)
    end
end

mutable struct Environment
    time_start::Float64
    time_end::Float64
    time_step::Float64
    time_now::Float64
    step_index::Int64
    step_total::Int64
    photons::Array{Float64}
    detectors::Vector{Union{Nothing, Detector}}
    light_sources::Vector{Union{Nothing, LightSource}}
    optical_components::Vector{Union{Nothing, OpticalComponent}}
    ports::Vector{Union{Nothing, NonOpticalDevice}}
    data_loggers::Vector{Union{Nothing, NonOpticalDevice}}
    schematic::Schematic
    temperature::Float64
    extent_left::Float64
    extent_right::Float64
    extent_top::Float64
    extent_bottom::Float64
    extent_wavelength_min::Float64
    extent_wavelength_max::Float64
    stats_time::Vector{Float64}
    stats_photons::Vector{Integer}
    option_verbose::Bool
    option_plot::Bool
    save_path::String
    function Environment(;time_start::Real, time_end::Real, time_step::Real, verbose::Bool = true, plot::Bool = true, save_path::String)
        time_start = convert(Float64, time_start)
        time_end = convert(Float64, time_end)
        time_step = convert(Float64, time_step)
        time_now::Float64 = time_start
        step_index = 1
        step_total = time_span_to_steps(time_start, time_end, time_step)
        detectors = Vector{Union{Nothing, Detector}}(nothing,0)
        light_sources = Vector{Union{Nothing, LightSource}}(nothing,0)
        optical_components = Vector{Union{Nothing, OpticalComponent}}(nothing,0)
        ports = Vector{Union{Nothing, NonOpticalDevice}}(nothing,0)
        data_loggers = Vector{Union{Nothing, NonOpticalDevice}}(nothing,0)
        schematic = Schematic(step_total, time_step)
        temperature = 25.0
        extent_left = Inf
        extent_right = -Inf
        extent_top = -Inf
        extent_bottom = Inf
        extent_wavelength_min = Inf
        extent_wavelength_max = -Inf
        photons = Array{Float64}(undef,3,0)
        stats_time = Vector{Float64}(undef,0)
        stats_photons = Vector{Integer}(undef,0)
        #photon_map = PlaneSpace(x_dims, y_dims,)
        verbose && println("\n<--Initializing simulation environment-->")
        _environment = new(time_start::Float64,
        time_end::Float64,
        time_step::Float64,
        time_now::Float64,
        step_index::Integer,
        step_total::Integer,
        photons::Array{Float64},
        detectors::Vector{Union{Nothing, Detector}},
        light_sources::Vector{Union{Nothing, LightSource}},
        optical_components::Vector{Union{Nothing, OpticalComponent}},
        ports::Vector{Union{Nothing, NonOpticalDevice}},
        data_loggers::Vector{Union{Nothing, NonOpticalDevice}},
        schematic::Schematic,
        temperature::Float64,
        extent_left::Float64,
        extent_right::Float64,
        extent_top::Float64,
        extent_bottom::Float64,
        extent_wavelength_min::Float64,
        extent_wavelength_max::Float64,
        stats_time::Vector{Float64},
        stats_photons::Vector{Integer},
        verbose::Bool,
        plot::Bool,
        save_path::String)
        return _environment
    end
end

abstract type ElectricalProbe <: ElectricalComponent
end

mutable struct CurrentSource <: ElectricalSource
    sim_environment::Environment
    element::Symbol
    info::String
    pin_positive::Tuple{Symbol,Any}
    pin_negative::Tuple{Symbol,Any}
    function CurrentSource(sim_environment::Environment, value::Float64, info::String)
        element = ACME.add!(sim_environment.schematic.circuit, ACME.currentsource(value))
        component = new(sim_environment::Environment,
        element::Symbol,
        info::String,
        (element, +)::Tuple{Symbol,Any},
        (element, -)::Tuple{Symbol,Any}
        )
        return component
    end
end
mutable struct VoltageSource <: ElectricalSource
    sim_environment::Environment
    element::Symbol
    info::String
    pin_positive::Tuple{Symbol,Any}
    pin_negative::Tuple{Symbol,Any}
    function VoltageSource(sim_environment::Environment, value::Float64, info::String)
        element = ACME.add!(sim_environment.schematic.circuit, ACME.voltagesource(value))

        component = new(sim_environment::Environment,
        element::Symbol,
        info::String,
        (element, +)::Tuple{Symbol,Any},
        (element, -)::Tuple{Symbol,Any}
        )
        return component
    end
end
abstract type VectorSource <: ElectricalSource
end
mutable struct VectorCurrentSource <: VectorSource
    sim_environment::Environment
    element::Symbol
    info::String
    signal_vector::Vector{Float64}
    pin_positive::Tuple{Symbol,Any}
    pin_negative::Tuple{Symbol,Any}
    function VectorCurrentSource(sim_environment::Environment, signal_vector::Vector{Float64}, info::String)
        element = ACME.add!(sim_environment.schematic.circuit, ACME.currentsource())
        #sim_environment.schematic.inputs = vcat(sim_environment.schematic.inputs, transpose(input_vector))
        component = new(sim_environment::Environment,
        element::Symbol,
        info::String,
        signal_vector::Vector{Float64},
        (element, +)::Tuple{Symbol,Any},
        (element, -)::Tuple{Symbol,Any}
        )
        push!(sim_environment.schematic.sources, component)
        return component
    end
end
abstract type VectorSource <: ElectricalSource
end
mutable struct VectorVoltageSource <: VectorSource
    sim_environment::Environment
    element::Symbol
    info::String
    signal_vector::Vector{Float64}
    pin_positive::Tuple{Symbol,Any}
    pin_negative::Tuple{Symbol,Any}
    function VectorCurrentSource(sim_environment::Environment, signal_vector::Vector{Float64}, info::String)
        element = ACME.add!(sim_environment.schematic.circuit, ACME.voltagesource())
        component = new(sim_environment::Environment,
        element::Symbol,
        info::String,
        signal_vector::Vector{Float64},
        (element, +)::Tuple{Symbol,Any},
        (element, -)::Tuple{Symbol,Any}
        )
        push!(sim_environment.schematic.sources, component)
        return component
    end
end
abstract type NoiseSource <: ElectricalSource
end
mutable struct NoiseCurrentSource <: NoiseSource
    sim_environment::Environment
    element::Symbol
    info::String
    noise_distribution::Distribution
    pin_positive::Tuple{Symbol,Any}
    pin_negative::Tuple{Symbol,Any}
    function NoiseCurrentSource(sim_environment::Environment, noise_distribution::Distribution, info::String)
        element = ACME.add!(sim_environment.schematic.circuit, ACME.currentsource())
        component = new(sim_environment::Environment,
        element::Symbol,
        info::String,
        noise_distribution::Distribution,
        (element, +)::Tuple{Symbol,Any},
        (element, -)::Tuple{Symbol,Any}
        )
        push!(sim_environment.schematic.sources, component)
        return component
    end
end
mutable struct NoiseVoltageSource <: NoiseSource
    sim_environment::Environment
    element::Symbol
    info::String
    noise_distribution::Distribution
    pin_positive::Tuple{Symbol,Any}
    pin_negative::Tuple{Symbol,Any}
    function NoiseVoltageSource(sim_environment::Environment, noise_distribution::Distribution, info::String)
        element = ACME.add!(sim_environment.schematic.circuit, ACME.currentsource())
        component = new(sim_environment::Environment,
        element::Symbol,
        info::String,
        noise_distribution::Distribution,
        (element, +)::Tuple{Symbol,Any},
        (element, -)::Tuple{Symbol,Any}
        )
        push!(sim_environment.schematic.sources, component)
        return component
    end
end
mutable struct Resistor <: ElectricalComponent
    sim_environment::Environment
    element::Symbol
    info::String
    pin_1::Tuple{Symbol,Any}
    pin_2::Tuple{Symbol,Any}
end

mutable struct Capacitor <: ElectricalComponent
    sim_environment::Environment
    element::Symbol
    info::String
    pin_1::Tuple{Symbol,Any}
    pin_2::Tuple{Symbol,Any}
    function Capacitor(sim_environment::Environment, value::Float64, info::String)
        element = ACME.add!(sim_environment.schematic.circuit, ACME.capacitor(value))

        component = new(sim_environment::Environment,
        element::Symbol,
        info::String,
        (element, 1)::Tuple{Symbol,Any},
        (element, 2)::Tuple{Symbol,Any}
        )
        return component
    end
end

mutable struct VoltageProbe <: ElectricalProbe
    sim_environment::Environment
    element::Symbol
    info::String
    stats_output::Vector{Float64}
    pin_positive::Tuple{Symbol,Any}
    pin_negative::Tuple{Symbol,Any}
    function VoltageProbe(sim_environment::Environment, info::String)
        stats_output = Vector{Float64}(undef,0)
        element = ACME.add!(sim_environment.schematic.circuit, ACME.voltageprobe())
        sim_environment.schematic.probe_labels = hcat(sim_environment.schematic.probe_labels, info)

        component = new(sim_environment::Environment,
        element::Symbol,
        info::String,
        stats_output::Vector{Float64},
        (element, +)::Tuple{Symbol,Any},
        (element, -)::Tuple{Symbol,Any}
        )
        push!(sim_environment.schematic.probes, component)
        return component
    end
end
"""Current Probe"""
mutable struct CurrentProbe <: ElectricalProbe
    sim_environment::Environment
    element::Symbol
    info::String
    stats_output::Vector{Float64}
    pin_positive::Tuple{Symbol,Any}
    pin_negative::Tuple{Symbol,Any}
    function CurrentProbe(sim_environment::Environment, info::String)
        stats_output = Vector{Float64}(undef,0)
        element = ACME.add!(sim_environment.schematic.circuit, ACME.currentprobe())
        sim_environment.schematic.probe_labels = hcat(sim_environment.schematic.probe_labels, info)

        component = new(sim_environment::Environment,
        element::Symbol,
        info::String,
        stats_output::Vector{Float64},
        (element, +)::Tuple{Symbol,Any},
        (element, -)::Tuple{Symbol,Any}
        )
        push!(sim_environment.schematic.probes, component)
        return component
    end
end

"""
OpAmp

"""
mutable struct OpAmp
    sim_environment::Environment
    element::Symbol
    info::String
    pin_in_pos::Tuple{Symbol,Any}
    pin_in_neg::Tuple{Symbol,Any}
    pin_out_pos::Tuple{Symbol,Any}
    pin_out_neg::Tuple{Symbol,Any}
end
"""
    SubCircuitAB is a simple subcircuit with an input and output ex. RC filter.
    ex.
    SubCircuitAB(sim_environment; info="Simple RC filter", pin_input = (resistor, 1), pin_output = (capacitor, 1))
"""
mutable struct SubCircuitAB <: ElectricalSubCkt
    sim_environment::Environment
    components::Vector
    info::String
    pin_input::Tuple{Symbol,Any}
    pin_output::Tuple{Symbol,Any}
    function SubCircuitAB(sim_environment::Environment; components::Vector, info::String, pin_input::Tuple{Symbol,Any}, pin_output::Tuple{Symbol,Any})
        new(sim_environment::Environment,
        components::Vector,
        info::String,
        pin_input::Tuple{Symbol,Any},
        pin_output::Tuple{Symbol,Any})
    end
end

mutable struct Port <: NonOpticalDevice
    sim_environment::Environment
    signal::Float64
    units::String
    function Port(sim_environment::Environment, initial_value::Float64, units::String)
        device = new(sim_environment::Environment, initial_value::Float64, units::String)
        push!(sim_environment.ports, device)
        return device
    end
end # mutable struct Port

mutable struct PMT <: Detector
    name::String
    cathode_sensitivity_curve::SparseMatrixCSC
    gain::Float64
    number_of_dynodes::Int8
    dynode_gain::Float64
    dark_count::Float64
    rise_time_fast::Float64
    rise_time_slow::Float64
    fall_time_fast::Float64
    fall_time_slow::Float64
    # function PMT(name::String, cathode_sensitivity_curve::SMatrix, gain, number_of_dynodes, dark_count, rise_time_fast, rise_time_slow, fall_time_fast, fall_time_slow)
    #
    # end
end

mutable struct DataLogger <: NonOpticalDevice
    sim_environment::Environment
    target::Any
    field::Any
    x::Vector{Float64}
    y::Vector{Float64}
    function DataLogger(sim_environment::Environment, target::Any, field::Any)
        x = Vector{Float64}(undef,0)
        y = Vector{Float64}(undef,0)

        device = new(sim_environment::Environment,
        target::Any,
        field::Any,
        x::Vector{Float64},
        y::Vector{Float64}
        )

        push!(sim_environment.data_loggers, device)
        return device
    end
end
##

function optionverbose(option::Bool,text::String)
    if option == true
        @info text
    end
end

function count_light_sources(sim_environment::Environment)
    count_light_sources = size(sim_environment.light_sources,1)
end

function count_detectors(sim_environment::Environment)
    count_detectors = size(sim_environment.count_detectors,1)
end
function update_extents(sim_environment::Environment; extent_left::Float64, extent_right::Float64, extent_top::Float64, extent_bottom::Float64, extent_wavelength_min::Float64, extent_wavelength_max::Float64)
    sim_environment.extent_left = extent_left < sim_environment.extent_left ? extent_left : sim_environment.extent_left
    sim_environment.extent_right = extent_right > sim_environment.extent_right ? extent_right : sim_environment.extent_right
    sim_environment.extent_top = extent_top > sim_environment.extent_top ? extent_top : sim_environment.extent_top
    sim_environment.extent_bottom = extent_bottom < sim_environment.extent_bottom ? extent_bottom : sim_environment.extent_bottom
    sim_environment.extent_wavelength_min = extent_wavelength_min < sim_environment.extent_wavelength_min ? extent_wavelength_min : sim_environment.extent_wavelength_min
    sim_environment.extent_wavelength_max = extent_wavelength_max > sim_environment.extent_wavelength_min ? extent_wavelength_max : sim_environment.extent_wavelength_max
end
function simulate!(sim_environment::Environment)
    sim_environment.time_now = sim_environment.time_start
    sim_environment.step_index = 1
    sim_environment.schematic.inputs =  Array{Float64}(undef, sim_environment.step_total,0) # clear the electrical circuit inputs

    total_steps = sim_environment.step_total

    # preallocate and reset stat vectors
    initialize!(sim_environment)
    for detector in sim_environment.detectors # do for all detectors sources
        initialize!(detector)
    end
    for light_source in sim_environment.light_sources # do for all light sources
        initialize!(light_source)
    end
    for data_logger in sim_environment.data_loggers # do for all light sources
        initialize!(data_logger)
    end

    # run the simulation loop
    _procid = myid()
    _threadid = Threads.threadid()
    @info "Running optical simulation on Process $_procid, Thread $_threadid"
    for i = 1:total_steps
    #@showprogress 1 "Simulating..." for i in 1:total_steps
        timestep!(sim_environment)
    end

    # propogate detector signal to it's current source signal vector
    for detector in sim_environment.detectors
        readout!(detector)
    end

    # add signals to the circuit input matrix
    # source_vectors = Vector(undef, length(sim_environment.schematic.sources))
    for source in sim_environment.schematic.sources
        inputsource!(source)
    end
    # sim_environment.schematic.inputs = reduce(hcat, source_vectors)
    # build and simulate electrical circuit
    simulate_schematic!(sim_environment)

    # build stats_output matrix
    for i = eachindex(sim_environment.schematic.probes)
        sim_environment.schematic.probes[i].stats_output = get_column(sim_environment.schematic.stats_probe_outputs, i)
    end
    sim_environment.option_verbose && print("<--End of simulation-->\n")
    return nothing
    # flush(stdout) # clear the io buffer
end
function build!(sim_environment::Environment)
    sim_environment.option_verbose && @info "Building circuit model.\nThis step is required only once."

    model = ACME.DiscreteModel(sim_environment.schematic.circuit, sim_environment.schematic.sample_interval, ACME.HomotopySolver{ACME.CachingSolver{ACME.SimpleSolver}})
    #steadystate!(model)
    sim_environment.option_verbose && @info "Building model runner."
    sim_environment.schematic.model_runner = ACME.ModelRunner(model, false)
end

function simulate_schematic!(sim_environment::Environment)
    if sim_environment.schematic.model_runner == nothing # if the model runner is not ready
        sim_environment.schematic.stats_probe_outputs = fill(0.0, size(sim_environment.schematic.probe_labels,2), sim_environment.step_total) # size output array
        build!(sim_environment) # build the model runner
    else # simulation was previously run so the output array needs to be transposed to original configuration
        sim_environment.schematic.stats_probe_outputs = copy(transpose(sim_environment.schematic.stats_probe_outputs))
    end

    sim_environment.option_verbose && @info "Running electrical simulation."
    ACME.run!(sim_environment.schematic.model_runner,
        sim_environment.schematic.stats_probe_outputs,
        copy(transpose(sim_environment.schematic.inputs))
        )
    sim_environment.schematic.stats_probe_outputs = copy(transpose(sim_environment.schematic.stats_probe_outputs))

    sim_environment.option_verbose && @info "Plotting results."
    if sim_environment.option_plot == true
        sim_environment.schematic.plot = plot(sim_environment.stats_time,
            sim_environment.schematic.stats_probe_outputs,
            labels = sim_environment.schematic.probe_labels,
            size = (768,576),
            )
    end
    sim_environment.option_verbose && @info "Simulation finished."
    return nothing
end

function initialize!(sim_environment::Environment)
    sim_environment.stats_time = Vector{Float64}(undef, sim_environment.step_total)
    for i = 1:sim_environment.step_total
        sim_environment.stats_time[i] = (i-1)*sim_environment.time_step + sim_environment.time_start
    end
    sim_environment.stats_photons = fill(0, sim_environment.step_total)
    sim_environment.option_verbose && @info "Environment stats were reset."
    return nothing
end

function initialize!(data_logger::DataLogger)
    data_logger.x = fill(0.0,data_logger.sim_environment.step_total)
    data_logger.y = fill(0.0,data_logger.sim_environment.step_total)
    data_logger.sim_environment.option_verbose && @info "DataLogger stats were reset."
    return nothing
end


"""
    timestep!(sim_environment::Simulation.Environment)
    Increments the simulation environment time one time_step. and index by 1.
    Then it timesteps each light source followed by each detector. In the order
    they were added to the simulation environment.

"""
function timestep!(sim_environment::Environment)
    # sim_environment.stats_time[sim_environment.step_index] = sim_environment.time_now
    sim_environment.photons = Array{Float64}(undef,3,0) # clear the photons
    @inbounds for light_source in sim_environment.light_sources # do for all light sources
        photons = timestep!(light_source)
        if photons != nothing # if photons exist append to sim_environment
            sim_environment.stats_photons[sim_environment.step_index] += light_source.stats_photons_emitted[sim_environment.step_index]
            sim_environment.photons = hcat(sim_environment.photons, photons)::Array{Float64}
        end
    end
    for detector in sim_environment.detectors # do for all detectors sources
        timestep!(detector)
    end

    for data_logger in sim_environment.data_loggers # do for all detectors sources in reverse, last added detector pushes input to top of stack first.
        timestep!(data_logger, data_logger.target)
    end

    # @fastmath sim_environment.time_now += sim_environment.time_step # increment the sim_environment time
    sim_environment.step_index += 1 # increment the sim_environment step
    return nothing
end

function timestep!(data_logger::DataLogger, target::Any)
    data_logger.x[data_logger.sim_environment.step_index] = data_logger.sim_environment.stats_time[data_logger.sim_environment.step_index]
    data_logger.y[data_logger.sim_environment.step_index] = getfield(data_logger.target, data_logger.field)
    return nothing
end

function timestep!(data_logger::DataLogger, target::Vector)
    data_logger.x[data_logger.sim_environment.step_index] = data_logger.sim_environment.stats_time[data_logger.sim_environment.step_index]
    data_logger.y[data_logger.sim_environment.step_index] = target[data_logger.field]
    return nothing
end

function readout!(detector::Detector)
    detector.current_source.signal_vector = detector.stats_anode_current
end

function inputsource!(noise_source::NoiseSource)
    noise_source.sim_environment.schematic.inputs = hcat(
        noise_source.sim_environment.schematic.inputs, rand(PRNGs[Threads.threadid()], noise_source.noise_distribution, noise_source.sim_environment.step_total)
        )
    #rand(PRNGs[Threads.threadid()], noise_source.noise_distribution, noise_source.sim_environment.step_total)
end
function inputsource!(vector_source::VectorSource)
    vector_source.sim_environment.schematic.inputs = hcat(vector_source.sim_environment.schematic.inputs, vector_source.signal_vector)
    #vector_source.signal_vector
end
