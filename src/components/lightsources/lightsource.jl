mutable struct FocusedSource <: LightSource
    sim_environment::Environment
    pulse_shape::Symbol
    photons_per_pulse::Float64
    pulse_width::Float64
    delay::Float64
    frequency::Float64
    temporal_profile::Vector{Float64}
    distribution_x::Distribution
    distribution_y::Distribution
    wavelength_distribution::Union{Distribution, AbstractDistribution}
    optical_output::Union{Nothing, OpticalComponent}
    stats_photons_emitted::Vector{Integer}
    info::String
end # mutable struct FocusedSource

function FocusedSource(sim_environment::Environment;
info::String,
pulse_shape::Symbol,
photons_per_pulse::Real,
pulse_width::Real,
delay::Real,
frequency::Real,
wavelength_distribution::Union{Distribution, AbstractDistribution},
distribution_x::Distribution,
distribution_y::Distribution,
optical_output::Union{Nothing, OpticalComponent} = nothing)
    photons_per_pulse = convert(Float64, photons_per_pulse)
    pulse_width = convert(Float64, pulse_width)
    delay = convert(Float64, delay)
    frequency = convert(Float64, frequency)
    indexes = sim_environment.schematic.model_runner == nothing ? sim_environment.step_total : error("cannot modify a compiled Environment, start a new instance of Environment")
    temporal_profile = zeros(Float64, indexes)
    if pulse_shape == :gaussian
        temporal_profile = make_pulse_train_gaussian(delay, pulse_width, frequency, photons_per_pulse, sim_environment.time_start, sim_environment.time_end, sim_environment.time_step)
    elseif pulse_shape == :square
        temporal_profile = make_pulse_train_square(delay, pulse_width, frequency, photons_per_pulse, sim_environment.time_start, sim_environment.time_end, sim_environment.time_step)
    end

    stats_photons_emitted = Integer[]
    optical_output = nothing

    device = FocusedSource(sim_environment::Environment,
        pulse_shape::Symbol,
        photons_per_pulse::Float64,
        pulse_width::Float64,
        delay::Float64,
        frequency::Float64,
        temporal_profile::Vector{Float64},
        distribution_x::Distribution,
        distribution_y::Distribution,
        wavelength_distribution::Union{Distribution, AbstractDistribution},
        optical_output::Union{Nothing, OpticalComponent},
        stats_photons_emitted::Vector{Integer},
        info::String)
    push!(sim_environment.light_sources, device)
    return device
end




function initialize!(light_source::LightSource)
    # light_source.stats_photons_emitted = [rand(Poisson(n)) for n in light_source.temporal_profile]
    light_source.stats_photons_emitted = fill(0, light_source.sim_environment.step_total)
    Threads.@threads for i = 1:light_source.sim_environment.step_total
        light_source.stats_photons_emitted[i] = pois_rand(PRNGs[Threads.threadid()], light_source.temporal_profile[i])
    end
    light_source.sim_environment.option_verbose && @info "LightSource stats were reset."
    return nothing
end

function set_condition!(light_source::FocusedSource; photons_per_pulse=light_source.photons_per_pulse::Real)
    setfield!(light_source, :photons_per_pulse, convert(Float64, photons_per_pulse))
    if light_source.pulse_shape == :gaussian
        setfield!(light_source, :temporal_profile, make_pulse_train_gaussian(light_source.delay, light_source.pulse_width, light_source.frequency, photons_per_pulse, light_source.sim_environment.time_start, light_source.sim_environment.time_end, light_source.sim_environment.time_step))
    elseif light_source.pulse_shape == :square
        setfield!(light_source, :temporal_profile, make_pulse_train_square(light_source.delay, light_source.pulse_width, light_source.frequency, photons_per_pulse, light_source.sim_environment.time_start, light_source.sim_environment.time_end, light_source.sim_environment.time_step))
    end
    light_source.sim_environment.option_verbose && @info "LightSource :photons per pulse changed to $photons_per_pulse"
    return light_source
end

function timestep!(light_source::FocusedSource)
    if light_source.stats_photons_emitted[light_source.sim_environment.step_index] > 0
        return filter_photons!(light_source.optical_output,
                            @views vcat(
                                rand(PRNGs[Threads.threadid()], light_source.distribution_x, 1, light_source.stats_photons_emitted[light_source.sim_environment.step_index]),
                                rand(PRNGs[Threads.threadid()], light_source.distribution_y, 1, light_source.stats_photons_emitted[light_source.sim_environment.step_index]),
                                rand(PRNGs[Threads.threadid()], light_source.wavelength_distribution, 1, light_source.stats_photons_emitted[light_source.sim_environment.step_index])
                            )
                        )
    else
        return nothing
    end
end
