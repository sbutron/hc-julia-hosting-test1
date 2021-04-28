mutable struct SiPM <: Detector
    sim_environment::Environment
    photon_detection_efficiency::Float64
    gain::Float64
    dark_count_rate::Float64
    dcr_λ::Float64
    crosstalk_probability::Float64
    afterpulse_probability::Float64
    relative_pde_vs_overvoltage::Polynomial{Float64}
    relative_crosstalk_vs_overvoltage::Polynomial{Float64}
    relative_gain_vs_overvoltage::Polynomial{Float64}
    relative_dcr_vs_overvoltage::Polynomial{Float64}
    pde_vs_wavelength::Array{Float64,2}
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
    Rq::Float64
    Cq::Float64
    Cd::Float64
    Cg::Float64
    fast_pulse_ratio::Float64
    slow_pulse_ratio::Float64
    number_of_microcells::Integer
    microcell_capacitance::Float64
    min_overvoltage::Float64
    overvoltage::Float64
    max_overvoltage::Float64
    pixel_pitch::Float64
    map_width::Float64
    shape::Symbol
    position::Coordinate
    pixels_x::Vector{Float64}
    pixels_y::Vector{Float64}
    update_vector_all_pe::Vector{Bool}
    update_vector_charge_out::Vector{Bool}
    microcell_map::PlaneSpace
    identity_map::PlaneSpace
    photon_map::PlaneSpace
    pxt_incident_photons::SparseMatrixCSC{Integer,Int64} # zeros(Integer,number_of_microcells)
    pxt_photon_pe::SparseMatrixCSC{Integer,Int64} # zeros(Integer,number_of_microcells)
    pxt_dark_pe::SparseMatrixCSC{Integer,Int64} # zeros(Integer,number_of_microcells)
    pxt_primary_pe::SparseMatrixCSC{Integer,Int64} # zeros(Integer,number_of_microcells)
    pxt_crosstalk_pe::SparseMatrixCSC{Integer,Int64} # zeros(Integer,number_of_microcells)
    pxt_afterpulse_pe::SparseMatrixCSC{Integer,Int64}
    pxt_all_pe::SparseMatrixCSC{Integer,Int64} # zeros(Integer,number_of_microcells)
    px_new_charge_buffer::Vector{Float64} # zeros(Float64,number_of_microcells)
    px_fast_charge_buffer::Vector{Float64} # zeros(Float64,number_of_microcells)
    px_slow_charge_buffer::Vector{Float64} # zeros(Float64,number_of_microcells)
    px_overvoltage::Vector{Float64}
    px_carrier_out::Vector{Float64}
    enf_distribution::DistributionDefinition
    stats_incident_photons::Vector{Integer}
    stats_photon_pe::Vector{Float64}
    stats_dark_pe::Vector{Float64}
    stats_crosstalk_pe::Vector{Float64}
    stats_afterpulse_pe::Vector{Float64}
    stats_all_pe::Vector{Float64}
    stats_charge_buffer::Vector{Float64}
    stats_anode_current::Vector{Float64}
    port_anode::Port
    pin_anode::Tuple{Symbol,Any}
    current_source::VectorCurrentSource
    info::String
end # struct SiPM

function SiPM(sim_environment::Environment;
                photon_detection_efficiency::Float64,
                dark_count_rate::Float64,
                crosstalk_probability::Float64,
                afterpulse_probability::Float64,
                relative_pde_vs_overvoltage::Polynomial{Float64},
                relative_crosstalk_vs_overvoltage::Polynomial{Float64},
                relative_gain_vs_overvoltage::Polynomial{Float64},
                relative_dcr_vs_overvoltage::Polynomial{Float64},
                pde_vs_wavelength::Array{Float64,2},
                number_of_microcells::Integer,
                rise_time_fast::Float64,
                Cd::Float64,
                Cq::Float64,
                Cg::Float64,
                Rq::Float64,
                Rs::Float64,
                pixel_pitch::Float64,
                breakdown_voltage::Float64,
                min_overvoltage::Float64,
                overvoltage::Float64,
                max_overvoltage::Float64,
                shape::Symbol,
                position::Coordinate,
                ignore_error::Bool = false,
                info::String = "SiPM"
                )

    sensor_matrix = sim_environment.schematic.model_runner == nothing ? Vector{Float64}(undef, number_of_microcells) : error("cannot modify a compiled Environment, start a new instance of Environment")
    if shape == :circle
        sensor_matrix = make_circle_lattice(number_of_microcells) * pixel_pitch
    else
        sensor_matrix = make_square_lattice(number_of_microcells) * pixel_pitch
    end
    x_offset = position.x
    y_offset = position.y
    map_width = round( sqrt(number_of_microcells) ) * pixel_pitch * 1.5
    microcell_map = PlaneSpace(map_width, map_width, x_offset, y_offset, pixel_pitch, Integer)
    photon_map = PlaneSpace(map_width, map_width, x_offset, y_offset, pixel_pitch, Integer)
    identity_map = PlaneSpace(map_width, map_width, x_offset, y_offset, pixel_pitch, Integer)
    pixels_x = fill(0.0,number_of_microcells)
    pixels_y = fill(0.0,number_of_microcells)

    update_vector_all_pe = fill(false,number_of_microcells)
    update_vector_charge_out = fill(false,number_of_microcells)

    extrema_x = extrema(get_column(sensor_matrix, 1))
    center_x = extrema_x[1]
    extrema_y = extrema(get_column(sensor_matrix, 1))
    center_y = extrema_y[1]
    #display(scatter(sensor_matrix[:,1],sensor_matrix[:,2]))
    for pixel = 1:number_of_microcells
        x = sensor_matrix[pixel,1] + x_offset
        y = sensor_matrix[pixel,2] + y_offset
        if microcell_map[x, y] > 0
            _prevval = microcell_map[x, y]
            @warn "overwriting $_prevval at [$x,$y] with $pixel"
        end
        microcell_map[x, y] = pixel
        identity_map[x, y] = 1
        pixels_x[pixel] = x
        pixels_y[pixel] = y
    end

    _mmapsize = size(nonzeros(microcell_map.space),1)
    !ignore_error && @assert size(nonzeros(microcell_map.space),1) == number_of_microcells "SiPM build error: size of microcell_map indices $_mmapsize does not match number_of_microcells" # check if the microcell map has enough indexes to cover the number of microcells

    # https://indico.cern.ch/event/644232/attachments/1482152/2307090/Musienko-SiPMs-CERN-seminar_30.06.2017.pdf slide 11
    gain = overvoltage * (Cq + Cd) / Constants.q
    fast_pulse_ratio = Cq / (Cq + Cd)
    slow_pulse_ratio = 1 - fast_pulse_ratio
    τ_rise_fast = time_response_to_time_constant(rise_time_fast)
    Rd = τ_rise_fast / (Cq + Cd)
    τ_rise_slow = Rd * (Cq + Cd)
    τ_fall_fast = Rs * Cd * Cq / (Cq + Cd)
    τ_fall_slow = Rq * (Cq + Cd)

    # parameter checking
    !ignore_error && @assert Rq > 0 "SiPM build error: negative Rq"
    !ignore_error && @assert Cd > 0 "SiPM build error: negative Rs"
    !ignore_error && @assert Cq > 0 "SiPM build error: negative Cq"
    !ignore_error && @assert Cd > 0 "SiPM build error: negative Cd"
    !ignore_error && @assert Cg > 0 "SiPM build error: negative Cg"
    !ignore_error && @assert τ_fall_slow > τ_fall_fast "SiPM build error: fast pulse > slow pulse"

    Δ_rise_fast = decay_value(1.0, sim_environment.time_step, τ_rise_fast)
    Δ_fall_fast = decay_value(1.0, sim_environment.time_step, τ_fall_fast)
    Δ_rise_slow = decay_value(1.0, sim_environment.time_step, τ_rise_slow)
    Δ_fall_slow = decay_value(1.0, sim_environment.time_step, τ_fall_slow)
    microcell_capacitance = Cq + Cd

    pxt_incident_photons = spzeros(Integer, number_of_microcells, sim_environment.step_total)
    pxt_photon_pe = spzeros(Integer, number_of_microcells, sim_environment.step_total)
    pxt_dark_pe = spzeros(Integer, number_of_microcells, sim_environment.step_total)
    pxt_primary_pe = spzeros(Integer, number_of_microcells, sim_environment.step_total)
    pxt_crosstalk_pe = spzeros(Integer, number_of_microcells, sim_environment.step_total)
    pxt_afterpulse_pe = spzeros(Integer, number_of_microcells, sim_environment.step_total)
    pxt_all_pe = spzeros(Integer, number_of_microcells, sim_environment.step_total)
    px_new_charge_buffer = zeros(Float64,number_of_microcells)
    px_fast_charge_buffer = zeros(Float64,number_of_microcells)
    px_slow_charge_buffer = zeros(Float64,number_of_microcells)
    px_overvoltage = fill(overvoltage, number_of_microcells)
    px_carrier_out = zeros(Float64,number_of_microcells)


    enf_distribution = Borel(crosstalk_probability)

    stats_incident_photons = Vector{Float64}(undef,0)
    stats_photon_pe = Vector{Float64}(undef,0)
    stats_dark_pe = Vector{Float64}(undef,0)
    stats_crosstalk_pe = Vector{Float64}(undef,0)
    stats_afterpulse_pe = Vector{Float64}(undef,0)
    stats_all_pe = Vector{Float64}(undef,0)
    stats_charge_buffer = Vector{Float64}(undef,0)
    stats_anode_current = Vector{Float64}(undef,0)
    port_anode = Port(sim_environment, 0.0, "electrons")
    pde_vs_wavelength[:,1] = pde_vs_wavelength[:,1] * 1e-9 # convert wavelength to nanometers

    dcr_λ = dark_count_rate * sim_environment.time_step

    ## Electrical model

    quenching_resistor = Resistor_Ideal(sim_environment, Rq/number_of_microcells, "Rq/N")
    quenching_capacitance = Capacitor(sim_environment, Cq*number_of_microcells, "Cq*N")
    discharge_capacitance = Capacitor(sim_environment, Cd*number_of_microcells, "Cq*N")
    grid_capacitance = Capacitor(sim_environment, Cg, "Cg")
    current_source = VectorCurrentSource(sim_environment, Vector{Float64}(undef,0), "Detector Output")
    # vbias = VoltageSource(sim_environment, 56.0, "Vbias")
    #
    connect!(sim_environment,
        discharge_capacitance.pin_1,
        grid_capacitance.pin_1,
        current_source.pin_negative,
        :gnd)
    connect!(sim_environment,
        discharge_capacitance.pin_2,
        quenching_resistor.pin_1,
        quenching_capacitance.pin_1)
    connect!(sim_environment,
        quenching_resistor.pin_2,
        quenching_capacitance.pin_2,
        grid_capacitance.pin_2,
        current_source.pin_positive)

    # connect!(sim_environment, grid_capacitance.pin_1, current_source.pin_negative, :gnd)
    # connect!(sim_environment, grid_capacitance.pin_2, current_source.pin_positive)
    pin_anode = current_source.pin_positive

    wavelength_min = pde_vs_wavelength[1,2]
    wavelength_max = pde_vs_wavelength[end,2]
    device = SiPM(sim_environment::Environment,
        photon_detection_efficiency::Float64,
        gain::Float64,
        dark_count_rate::Float64,
        dcr_λ::Float64,
        crosstalk_probability::Float64,
        afterpulse_probability::Float64,
        relative_pde_vs_overvoltage::Polynomial{Float64},
        relative_crosstalk_vs_overvoltage::Polynomial{Float64},
        relative_gain_vs_overvoltage::Polynomial{Float64},
        relative_dcr_vs_overvoltage::Polynomial{Float64},
        pde_vs_wavelength::Array{Float64,2},
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
        Rq::Float64,
        Cq::Float64,
        Cd::Float64,
        Cg::Float64,
        fast_pulse_ratio::Float64,
        slow_pulse_ratio::Float64,
        number_of_microcells::Integer,
        microcell_capacitance::Float64,
        min_overvoltage::Float64,
        overvoltage::Float64,
        max_overvoltage::Float64,
        pixel_pitch::Float64,
        map_width::Float64,
        shape::Symbol,
        position::Coordinate,
        pixels_x::Vector{Float64},
        pixels_y::Vector{Float64},
        update_vector_all_pe::Vector{Bool},
        update_vector_charge_out::Vector{Bool},
        microcell_map::PlaneSpace,
        identity_map::PlaneSpace,
        photon_map::PlaneSpace,
        pxt_incident_photons::SparseMatrixCSC{Integer,Int64},
        pxt_photon_pe::SparseMatrixCSC{Integer,Int64},
        pxt_dark_pe::SparseMatrixCSC{Integer,Int64},
        pxt_primary_pe::SparseMatrixCSC{Integer,Int64},
        pxt_crosstalk_pe::SparseMatrixCSC{Integer,Int64},
        pxt_afterpulse_pe::SparseMatrixCSC{Integer,Int64},
        pxt_all_pe::SparseMatrixCSC{Integer,Int64},
        px_new_charge_buffer::Vector{Float64},
        px_fast_charge_buffer::Vector{Float64},
        px_slow_charge_buffer::Vector{Float64},
        px_overvoltage::Vector{Float64},
        px_carrier_out::Vector{Float64},
        enf_distribution::DistributionDefinition,
        stats_incident_photons::Vector{Float64},
        stats_photon_pe::Vector{Float64},
        stats_dark_pe::Vector{Float64},
        stats_crosstalk_pe::Vector{Float64},
        stats_afterpulse_pe::Vector{Float64},
        stats_all_pe::Vector{Float64},
        stats_charge_buffer::Vector{Float64},
        stats_anode_current::Vector{Float64},
        port_anode::Port,
        pin_anode::Tuple{Symbol,Any},
        current_source::VectorCurrentSource,
        info::String
        )
    push!(sim_environment.detectors, device)
    update_extents(sim_environment,
        extent_left = device.microcell_map.extrema_x[1],
        extent_right = device.microcell_map.extrema_x[2],
        extent_top = device.microcell_map.extrema_y[2],
        extent_bottom = device.microcell_map.extrema_y[1],
        extent_wavelength_min = device.pde_vs_wavelength[begin,1],
        extent_wavelength_max = device.pde_vs_wavelength[end,1]
        )
    sim_environment.option_verbose && @info "$info added to the Environment at $position."
    return device
end

function set_condition!(sipm::SiPM;
                        crosstalk_probability::Real = sipm.crosstalk_probability,
                        afterpulse_probability::Real = sipm.afterpulse_probability)
    crosstalk_probability::Float64 = crosstalk_probability
    afterpulse_probability::Float64 = afterpulse_probability

    setfield!(sipm, :crosstalk_probability, crosstalk_probability)
    setfield!(sipm, :enf_distribution, Borel(crosstalk_probability))

    setfield!(sipm, :afterpulse_probability, afterpulse_probability)

    sipm.sim_environment.option_verbose && @info "$(sipm.info): parameters were changed changed."
    return sipm
end

function initialize!(sipm::SiPM)
    sipm.stats_incident_photons = fill(0.0, sipm.sim_environment.step_total)
    sipm.stats_all_pe = fill(0.0, sipm.sim_environment.step_total)
    sipm.stats_dark_pe = fill(0.0, sipm.sim_environment.step_total)
    sipm.stats_photon_pe = fill(0.0, sipm.sim_environment.step_total)
    sipm.stats_crosstalk_pe = fill(0.0, sipm.sim_environment.step_total)
    sipm.stats_afterpulse_pe = fill(0.0, sipm.sim_environment.step_total)
    sipm.stats_charge_buffer = fill(0.0, sipm.sim_environment.step_total)
    sipm.stats_anode_current = fill(0.0, sipm.sim_environment.step_total)
    sipm.pxt_incident_photons = spzeros(Integer, sipm.number_of_microcells, sipm.sim_environment.step_total)
    sipm.pxt_dark_pe = spzeros(Integer, sipm.number_of_microcells, sipm.sim_environment.step_total)
    sipm.pxt_photon_pe = spzeros(Integer, sipm.number_of_microcells, sipm.sim_environment.step_total)
    sipm.pxt_primary_pe = spzeros(Integer, sipm.number_of_microcells, sipm.sim_environment.step_total)
    sipm.pxt_crosstalk_pe = spzeros(Integer, sipm.number_of_microcells, sipm.sim_environment.step_total)
    sipm.pxt_afterpulse_pe = spzeros(Integer, sipm.number_of_microcells, sipm.sim_environment.step_total)
    sipm.pxt_all_pe = spzeros(Integer, sipm.number_of_microcells, sipm.sim_environment.step_total)
    sipm.sim_environment.option_verbose && @info  "$(sipm.info) stats were reset."
    return nothing
end

function timestep!(sipm::SiPM)
    refresh_state!(sipm) # clear the px and update vectors, process charge output
    dark_count!(sipm) # detect dark counts
    photon_detect!(sipm) # detect photons
    sipm.stats_anode_current[sipm.sim_environment.step_index] = sipm.port_anode.signal
    return nothing
end

function refresh_state!(sipm::SiPM)
    for target_microcell in findall(sipm.update_vector_charge_out)
        chargeoutput!(sipm, target_microcell)
    end
    sipm.port_anode.signal = sum(sipm.px_carrier_out) * Constants.q::Float64 / sipm.sim_environment.time_step
    return nothing
end

function dark_count!(sipm::SiPM)
    # dark_counts = rand(Poisson(sipm.dcr_λ)) # generate number of dark counts
    dark_counts = pois_rand(PRNGs[Threads.threadid()], sipm.dcr_λ)
    @views if dark_counts > 0
        # dark_pixels = rand(DiscreteUniform(1, sipm.number_of_microcells), dark_counts) # random assignment of dark_counts
        for target_microcell in rand(PRNGs[Threads.threadid()], DiscreteUniform(1, sipm.number_of_microcells), dark_counts)
            if sipm.pxt_all_pe[target_microcell, sipm.sim_environment.step_index] == 0 # check if the microcell hasn't already fired
                sipm.pxt_dark_pe[target_microcell, sipm.sim_environment.step_index] = 1 # set dark count to 1 (>1 is not necessary since the pixel can only be occupied by one number)
                sipm.pxt_all_pe[target_microcell, sipm.sim_environment.step_index] = 1 # set this microcell to fire in general
                sipm.update_vector_all_pe[target_microcell] = true #  flag microcell for updating
                chargeinject!(sipm, target_microcell) # process the readout of this pixel
                crosstalk!(sipm, target_microcell)

                # stats
                sipm.stats_dark_pe[sipm.sim_environment.step_index] += 1
                sipm.stats_all_pe[sipm.sim_environment.step_index] += 1
            end
        end
    end
    return nothing
end

function photon_assign(photon_array::Array{Float64,2}, sipm::SiPM; force_parallel=false::Bool)
    #photon_count = size(photon_array, 2)
    assignment = Array{Float64}(undef, 2, size(photon_array, 2))
    validphotons = 0
    for i = 1:size(photon_array, 2)
            # x = photon_array[1,i]
            # y = photon_array[2,i]
        target_microcell = sipm.microcell_map[photon_array[1,i], photon_array[1,i]]
        if target_microcell > 0
            validphotons += 1
            assignment[1,validphotons] = target_microcell
            assignment[2,validphotons] = photon_array[3,i]
        end
    end
    return assignment[:, 1:validphotons], validphotons
end

function photon_detect!(sipm::SiPM)
    photons, photon_count = photon_assign(sipm.sim_environment.photons, sipm, force_parallel=false)
    sipm.stats_incident_photons[sipm.sim_environment.step_index] = photon_count
    for i = 1:photon_count
        target_microcell::Integer = trunc(photons[1,i])
        if sipm.pxt_all_pe[target_microcell, sipm.sim_environment.step_index] == 0
            microcell_pde = lookup(sipm.pde_vs_wavelength, photons[2,i]) * sipm.relative_pde_vs_overvoltage(sipm.px_overvoltage[target_microcell]) # row 3 is the wavelength
            if microcell_pde > eps() && rand(PRNGs[Threads.threadid()], Bernoulli(microcell_pde)) == true # if microcell hasn't fired yet, probability of firing is not zero, and it fires
                sipm.pxt_all_pe[target_microcell, sipm.sim_environment.step_index] = sipm.pxt_photon_pe[target_microcell, sipm.sim_environment.step_index] = 1 # set this microcell to fire in general
                # sipm.update_vector_all_pe[target_microcell] = true # set this microcell to update on the next timestep!
                chargeinject!(sipm, target_microcell) # process the readout of this pixel
                crosstalk!(sipm, target_microcell) # check for crosstalk
                # stats
                sipm.stats_all_pe[sipm.sim_environment.step_index] += 1
                sipm.stats_photon_pe[sipm.sim_environment.step_index] += 1
            end
        else

        end
    end
    #end
    return nothing
end

##DEPRECATED
# function photon_detect!(sipm::SiPM)
#     #@views if size(sipm.sim_environment.photons, 2) > 0 # if there are photons
#     for i = 1:size(sipm.sim_environment.photons, 2)
#         x = sipm.sim_environment.photons[1,i]
#         y = sipm.sim_environment.photons[2,i]
#         #Photon Detection
#         target_microcell = sipm.microcell_map[x,y]
#         @views if target_microcell > 0 # target_microcell is 0 if x,y are out of bounds or unassigned
#             sipm.stats_incident_photons[sipm.sim_environment.step_index] += 1
#             if sipm.pxt_all_pe[target_microcell, sipm.sim_environment.step_index] == 0
#                 microcell_pde = lookup(sipm.pde_vs_wavelength, sipm.sim_environment.photons[3,i]) * sipm.relative_pde_vs_overvoltage(sipm.px_overvoltage[target_microcell]) # row 3 is the wavelength
#                 if microcell_pde > eps() && rand(PRNGs[Threads.threadid()], Bernoulli(microcell_pde)) == true # if microcell hasn't fired yet, probability of firing is not zero, and it fires
#                     sipm.pxt_all_pe[target_microcell, sipm.sim_environment.step_index] = 1 # set this microcell to fire in general
#                     sipm.pxt_photon_pe[target_microcell, sipm.sim_environment.step_index] = 1 # set this microcell to fire in general
#                     sipm.update_vector_all_pe[target_microcell] = true # set this microcell to update on the next timestep!
#                     chargeinject!(sipm, target_microcell) # process the readout of this pixel
#                     crosstalk!(sipm, target_microcell) # check for crosstalk
#
#                     # stats
#                     sipm.stats_all_pe[sipm.sim_environment.step_index] += 1
#                     sipm.stats_photon_pe[sipm.sim_environment.step_index] += 1
#                 end
#             end
#         end
#     end
#     #end
#     return nothing
# end
##
function crosstalk!(sipm::SiPM, target_microcell::Integer)
    #crosstalk_count = rand(sipm.enf_distribution)
    crosstalk_count = rand(PRNGs[Threads.threadid()],
                        Binomial(8, max(0, sipm.crosstalk_probability * sipm.relative_crosstalk_vs_overvoltage(sipm.px_overvoltage[target_microcell]))
                            )
                        )
    crosstalk_assigned = 1
    @views while crosstalk_assigned < crosstalk_count
        x, y = sincosd(rand(PRNGs[Threads.threadid()])*360) .* rand(PRNGs[Threads.threadid()], Pareto(10)) .* sqrt((sipm.pixel_pitch/2)^2 + (sipm.pixel_pitch/2)^2)# generate random radius, calculate sin/cos multiply by pythagorean length
        x = sipm.pixels_x[target_microcell] + x
        y = sipm.pixels_y[target_microcell] + y

        child_microcell = sipm.microcell_map[x,y]
        @views if child_microcell > 0 && sipm.pxt_all_pe[child_microcell, sipm.sim_environment.step_index] == 0 # if microcell index is valid, then check that it hasn't already fired
            sipm.pxt_crosstalk_pe[child_microcell, sipm.sim_environment.step_index] = 1 # set this microcell to fire due to crosstalk
            sipm.pxt_all_pe[child_microcell, sipm.sim_environment.step_index] = 1 # set this microcell to fire in general
            sipm.update_vector_all_pe[child_microcell] = true # set this microcell to update on the next timestep!
            chargeinject!(sipm, child_microcell) # process the readout of this pixel
            crosstalk!(sipm, child_microcell) # check for crosstalk from this pixel
            # stats
            sipm.stats_crosstalk_pe[sipm.sim_environment.step_index] += 1
            sipm.stats_all_pe[sipm.sim_environment.step_index] += 1
        end
        crosstalk_assigned += 1
    end
    return nothing
end

function afterpulse!(sipm::SiPM, target_microcell::Integer)
    afterpulse_probability = sipm.afterpulse_probability * sipm.px_carrier_out[target_microcell] / sipm.gain
    if afterpulse_probability > eps() && rand(PRNGs[Threads.threadid()], Bernoulli(afterpulse_probability)) == true # first check if afterpulse occurs
        sipm.pxt_all_pe[target_microcell, sipm.sim_environment.step_index] = 1
        sipm.update_vector_all_pe[target_microcell] = true
        chargeinject!(sipm, target_microcell)
        crosstalk!(sipm, target_microcell)
        sipm.stats_afterpulse_pe[sipm.sim_environment.step_index] += 1
        sipm.stats_all_pe[sipm.sim_environment.step_index] += 1
    end
    return nothing
end

function chargeinject!(sipm::SiPM, target_microcell::Integer)
    sipm.px_new_charge_buffer[target_microcell] += sipm.gain * max(0, sipm.relative_gain_vs_overvoltage(sipm.px_overvoltage[target_microcell])) + 1.0
    sipm.update_vector_charge_out[target_microcell] = true
    return nothing
end

function chargeoutput!(sipm::SiPM, target_microcell::Integer)
    fast_buffer_movement = sipm.px_new_charge_buffer[target_microcell] * sipm.fast_pulse_ratio * sipm.Δ_rise_fast
    slow_buffer_movement = sipm.px_new_charge_buffer[target_microcell] * sipm.slow_pulse_ratio * sipm.Δ_rise_slow

    sipm.px_fast_charge_buffer[target_microcell] += fast_buffer_movement
    sipm.px_slow_charge_buffer[target_microcell] += slow_buffer_movement
    sipm.px_new_charge_buffer[target_microcell] -= fast_buffer_movement + slow_buffer_movement

    @fastmath fast_buffer_movement = sipm.px_fast_charge_buffer[target_microcell] * sipm.Δ_fall_fast
    @fastmath sipm.px_fast_charge_buffer[target_microcell] -= fast_buffer_movement

    @fastmath slow_buffer_movement = sipm.px_slow_charge_buffer[target_microcell] * sipm.Δ_fall_slow
    @fastmath sipm.px_slow_charge_buffer[target_microcell] -= slow_buffer_movement
    sipm.px_overvoltage[target_microcell] = max(0.0 , sipm.overvoltage - ((sipm.px_new_charge_buffer[target_microcell] + sipm.px_fast_charge_buffer[target_microcell] + sipm.px_slow_charge_buffer[target_microcell]) * Constants.q::Float64 / sipm.microcell_capacitance))
    @fastmath sipm.px_carrier_out[target_microcell] = fast_buffer_movement + slow_buffer_movement

    if (sipm.px_new_charge_buffer[target_microcell] + sipm.px_fast_charge_buffer[target_microcell] + sipm.px_slow_charge_buffer[target_microcell]) < 1.0 # if microcell recovered then reset all buffers
        sipm.px_overvoltage[target_microcell] = sipm.overvoltage
        sipm.update_vector_charge_out[target_microcell] = false
        sipm.px_new_charge_buffer[target_microcell] = 0.0
        sipm.px_fast_charge_buffer[target_microcell] = 0.0
        sipm.px_slow_charge_buffer[target_microcell] = 0.0
        sipm.px_carrier_out[target_microcell] = 0.0
    else # else check for afterpulse
        afterpulse!(sipm, target_microcell)
    end
    #@fastmath sipm.port_anode.signal += (fast_buffer_movement + slow_buffer_movement) # this is in units of electron number
    return nothing
end
