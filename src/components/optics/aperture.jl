mutable struct Aperture <: OpticalFilter
    sim_environment::Environment
    shape::PrimitiveShape
    position::Coordinate
    optical_output::Union{Nothing, OpticalComponent}
    info::String
end

function Aperture(sim_environment::Environment;
                shape::PrimitiveShape,
                optical_output::Union{Nothing, OpticalComponent} = nothing,
                position::Coordinate = pt(0,0),
                info::String = "")

    component = Aperture(sim_environment::Environment,
                        shape::PrimitiveShape,
                        position::Coordinate,
                        optical_output::Union{Nothing, OpticalComponent},
                        info::String
                        )

    push!(sim_environment.optical_components, component)
    return component
end

function filter_photons!(aperture::Aperture, photon_array::Array{Float64})
    validphotons = 0
    for i = 1:size(photon_array, 2)
        if collision(aperture.shape, pt(photon_array[1,i], photon_array[2,i]))
            validphotons += 1
            photon_array[1,validphotons] = photon_array[1,i]
            photon_array[2,validphotons] = photon_array[2,i]
            photon_array[3,validphotons] = photon_array[3,i]
        end
    end
    if validphotons > 0
        return filter_photons!(aperture.optical_output, photon_array[:, 1:validphotons])
    else
        return nothing
    end
end
