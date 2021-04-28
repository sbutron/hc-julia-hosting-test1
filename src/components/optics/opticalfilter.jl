mutable struct WavelengthFilter <: OpticalFilter
    sim_environment::Environment
    transmission_curve::Array{Float64,2}
    position::Coordinate
    optical_output::Union{Nothing, OpticalComponent}
    info::String
end

function WavelengthFilter(sim_environment::Environment;
                            transmission_curve::Array{Float64,2},
                            optical_output::Union{Nothing, OpticalComponent} = nothing,
                            position::Coordinate = Coordinate(0,0),
                            info::String = "")
    transmission_curve[:,1] = transmission_curve[:,1] * 1e-9 #convert wavelength into meters

    component = WavelengthFilter(
        sim_environment::Environment,
        transmission_curve::Array{Float64,2},
        position::Coordinate,
        optical_output::Union{Nothing, OpticalComponent},
        info::String
    )

    push!(sim_environment.optical_components, component)
    return component
end

function filter_photons!(nothing::Nothing, photon_array::Array{Float64})
    return photon_array
end

function filter_photons!(wavelengthfilter::WavelengthFilter, photon_array::Array{Float64})
    validphotons = 0
    for i = 1:size(photon_array, 2)
        if rand(PRNGs[Threads.threadid()], Bernoulli(lookup(wavelengthfilter.transmission_curve, photon_array[3,i])))
            validphotons += 1
            photon_array[1,validphotons] = photon_array[1,i]
            photon_array[2,validphotons] = photon_array[2,i]
            photon_array[3,validphotons] = photon_array[3,i]
        end
    end
    if validphotons > 0
        return filter_photons!(wavelengthfilter.optical_output, photon_array[:, 1:validphotons])
    else
        return nothing
    end
end
