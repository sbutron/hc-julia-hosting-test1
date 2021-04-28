mutable struct APD <: Detector
    sim_environment::Environment
    active_area_shape::PrimitiveShape
    position::Coordinate
    gain::Float64
    excess_noise_figure::Float64
    dark_current::Float64
    dcr_λ::Float64
    terminal_capacitance::Float64
    afterpulse_probability::Float64
    qe_vs_wavelength::Array{Float64,2}
    wavelength_min::Float64
    wavelength_max::Float64
    τ_rise_fast::Float64
    τ_fall_fast::Float64
    τ_rise_slow::Float64
    τ_fall_slow::Float64
    Δ_rise_fast::Float64
    Δ_fall_fast::Float64
    Δ_rise_slow::Float64
    Δ_fall_slow::Float64
    fast_pulse_ratio::Float64
    slow_pulse_ratio::Float64
    min_bias_voltage::Float64
    bias_voltage::Float64
    max_bias_voltage::Float64
    enf_distribution::DistributionDefinition
    stats_incident_photons::Vector{Float64}
    stats_photon_pe::Vector{Float64}
    stats_dark_pe::Vector{Float64}
    stats_afterpulse_pe::Vector{Float64}
    stats_all_pe::Vector{Float64}
    stats_charge_buffer::Vector{Float64}
    stats_anode_current::Vector{Float64}
    new_charge_buffer::Float64
    fast_charge_buffer::Float64
    slow_charge_buffer::Float64
    port_anode::Port
    pin_anode::Tuple{Symbol,Any}
    current_source::VectorCurrentSource
    info::String
end # struct apd

function APD(sim_environment::Environment;
                active_area_shape::PrimitiveShape,
                gain::Float64,
                excess_noise_figure::Float64,
                dark_current::Float64,
                terminal_capacitance::Float64,
                afterpulse_probability::Float64,
                qe_vs_wavelength::Array{Float64,2},
                rise_time_fast::Float64,
                rise_time_slow::Float64,
                fall_time_fast::Float64,
                fall_time_slow::Float64,
                fast_pulse_ratio::Float64,
                min_bias_voltage::Float64,
                bias_voltage::Float64,
                max_bias_voltage::Float64,
                info::String = "APD"
                )
    @assert sim_environment.schematic.model_runner == nothing "cannot modify a compiled Environment, start a new instance of Environment"

    τ_rise_fast = time_response_to_time_constant(rise_time_fast)
    τ_fall_fast = time_response_to_time_constant(fall_time_fast)
    τ_rise_slow = time_response_to_time_constant(rise_time_slow)
    τ_fall_slow = time_response_to_time_constant(fall_time_slow)
    slow_pulse_ratio = 1.0 - fast_pulse_ratio
    @assert slow_pulse_ratio >= 0.0 "negative slow_pulse_ratio, caused by fast_pulse_ratio > 1"
    Δ_rise_fast = decay_value(1.0, sim_environment.time_step, τ_rise_fast)
    Δ_fall_fast = decay_value(1.0, sim_environment.time_step, τ_fall_fast)
    Δ_rise_slow = decay_value(1.0, sim_environment.time_step, τ_rise_slow)
    Δ_fall_slow = decay_value(1.0, sim_environment.time_step, τ_fall_slow)

    dcr_λ = (dark_current * sim_environment.time_step) / (gain * Constants.q)

    stats_incident_photons = Vector{Float64}(undef,0)
    stats_photon_pe = Vector{Float64}(undef,0)
    stats_dark_pe = Vector{Float64}(undef,0)
    stats_afterpulse_pe = Vector{Float64}(undef,0)
    stats_all_pe = Vector{Float64}(undef,0)
    stats_charge_buffer = Vector{Float64}(undef,0)
    stats_anode_current = Vector{Float64}(undef,0)

    qe_vs_wavelength[:,1] = qe_vs_wavelength[:,1] * 1e-9  # convert wavelength to nanometers
    wavelength_min = qe_vs_wavelength[1,2]
    wavelength_max = qe_vs_wavelength[end,2]

    enf_distribution = McIntyre(gain, excess_noise_figure)

    current_source = VectorCurrentSource(sim_environment, Vector{Float64}(undef,0), "Detector Output")
    @assert terminal_capacitance > 0 "negative terminal_capacitance"
    ct = Capacitor(sim_environment, terminal_capacitance, "Ct")
    connect!(sim_environment, current_source.pin_negative, ct.pin_1, :gnd)
    connect!(sim_environment, current_source.pin_positive, ct.pin_2)

    pin_anode = current_source.pin_positive
    port_anode = Port(sim_environment, 0.0, "electrons")
    new_charge_buffer = 0.0
    fast_charge_buffer = 0.0
    slow_charge_buffer = 0.0
    position = active_area_shape.center

    device = APD(sim_environment::Environment,
                    active_area_shape::PrimitiveShape,
                    position::Coordinate,
                    gain::Float64,
                    excess_noise_figure::Float64,
                    dark_current::Float64,
                    dcr_λ::Float64,
                    terminal_capacitance::Float64,
                    afterpulse_probability::Float64,
                    qe_vs_wavelength::Array{Float64,2},
                    wavelength_min::Float64,
                    wavelength_max::Float64,
                    τ_rise_fast::Float64,
                    τ_fall_fast::Float64,
                    τ_rise_slow::Float64,
                    τ_fall_slow::Float64,
                    Δ_rise_fast::Float64,
                    Δ_fall_fast::Float64,
                    Δ_rise_slow::Float64,
                    Δ_fall_slow::Float64,
                    fast_pulse_ratio::Float64,
                    slow_pulse_ratio::Float64,
                    min_bias_voltage::Float64,
                    bias_voltage::Float64,
                    max_bias_voltage::Float64,
                    enf_distribution::DistributionDefinition,
                    stats_incident_photons::Vector{Float64},
                    stats_photon_pe::Vector{Float64},
                    stats_dark_pe::Vector{Float64},
                    stats_afterpulse_pe::Vector{Float64},
                    stats_all_pe::Vector{Float64},
                    stats_charge_buffer::Vector{Float64},
                    stats_anode_current::Vector{Float64},
                    new_charge_buffer::Float64,
                    fast_charge_buffer::Float64,
                    slow_charge_buffer::Float64,
                    port_anode::Port,
                    pin_anode::Tuple{Symbol,Any},
                    current_source::VectorCurrentSource,
                    info::String
                )
    push!(sim_environment.detectors, device)
    sim_environment.option_verbose && @info "$info added to the Environment at $position."
    return device
end

function set_condition!(apd::APD;
                        excess_noise_figure::Real = apd.excess_noise_figure,
                        gain::Real = apd.gain,
                        dark_current::Real = apd.dark_current
                        )
    excess_noise_figure::Float64 = excess_noise_figure
    gain::Float64 = gain
    dark_current::Float64 = dark_current

    setfield!(apd, :gain, gain)
    setfield!(apd, :excess_noise_figure, excess_noise_figure)
    setfield!(apd, :enf_distribution, McIntyre(gain, excess_noise_figure))

    dcr_λ = (dark_current * apd.sim_environment.time_step) / (gain * Constants.q)
    setfield!(apd, :dark_current, dark_current)
    setfield!(apd, :dcr_λ, dcr_λ)
    apd.sim_environment.option_verbose && @info "APD: parameters were changed changed."
    return apd
end

function initialize!(apd::APD)
    apd.stats_incident_photons = fill(0.0, apd.sim_environment.step_total)
    apd.stats_all_pe = fill(0.0, apd.sim_environment.step_total)
    apd.stats_dark_pe = fill(0.0, apd.sim_environment.step_total)
    apd.stats_photon_pe = fill(0.0, apd.sim_environment.step_total)
    apd.stats_afterpulse_pe = fill(0.0, apd.sim_environment.step_total)
    apd.stats_charge_buffer = fill(0.0, apd.sim_environment.step_total)
    apd.stats_anode_current = fill(0.0, apd.sim_environment.step_total)
    apd.sim_environment.option_verbose && @info  "APD stats were reset."
    return nothing
end

function timestep!(apd::APD)
    refresh_state!(apd) # clear the px and update vectors, process charge output
    dark_count!(apd) # detect dark counts
    photon_detect!(apd) # detect photons
    apd.stats_anode_current[apd.sim_environment.step_index] = apd.port_anode.signal
    return nothing
end

function refresh_state!(apd::APD)
    fast_buffer_movement = apd.new_charge_buffer * apd.fast_pulse_ratio * apd.Δ_rise_fast
    slow_buffer_movement = apd.new_charge_buffer * apd.slow_pulse_ratio * apd.Δ_rise_slow
    apd.fast_charge_buffer += fast_buffer_movement
    apd.slow_charge_buffer += slow_buffer_movement
    apd.new_charge_buffer -= fast_buffer_movement + slow_buffer_movement

    fast_buffer_movement = apd.fast_charge_buffer * apd.Δ_fall_fast
    apd.fast_charge_buffer -= fast_buffer_movement

    slow_buffer_movement = apd.slow_charge_buffer * apd.Δ_fall_slow
    apd.slow_charge_buffer -= slow_buffer_movement

    apd.port_anode.signal = (fast_buffer_movement + slow_buffer_movement) * Constants.q / apd.sim_environment.time_step

end

function dark_count!(apd::APD)
    dark_counts = pois_rand(PRNGs[Threads.threadid()], apd.dcr_λ)
    apd.stats_dark_pe[apd.sim_environment.step_index] += dark_counts
    apd.stats_all_pe[apd.sim_environment.step_index] += dark_counts
    chargeinject!(apd, dark_counts)
end
function photon_detect!(apd::APD)
    for i = 1:size(apd.sim_environment.photons, 2)
        x = apd.sim_environment.photons[1,i]
        y = apd.sim_environment.photons[2,i]
        #Photon Detection
        @views if collision(apd.active_area_shape, Coordinate(x,y))
            apd.stats_incident_photons[apd.sim_environment.step_index] += 1
            _qe = lookup(apd.qe_vs_wavelength, apd.sim_environment.photons[3,i]) # row 3 is the wavelength
            if _qe > eps() && rand(PRNGs[Threads.threadid()], Bernoulli(_qe)) == true # check if APD detects the photons
                apd.stats_all_pe[apd.sim_environment.step_index] += 1
                apd.stats_photon_pe[apd.sim_environment.step_index] += 1
            end
        end
    end
    chargeinject!(apd, convert(Integer, apd.stats_photon_pe[apd.sim_environment.step_index]))
    return nothing
end


function chargeinject!(apd::APD, counts::Integer)
    apd.new_charge_buffer += apd.gain * counts
end
