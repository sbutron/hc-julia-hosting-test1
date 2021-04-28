function connect!(sim_environment::Environment, pins...)
    sim_environment.schematic.model_runner == nothing ? ACME.connect!(sim_environment.schematic.circuit, pins...) : error("cannot modify a compiled Environment, start a new instance of Environment")
end

import Base: -

function -(a::SubCircuitAB,  b::SubCircuitAB)
    connect!(a.sim_environment, a.pin_output, b.pin_input)
    a.sim_environment.option_verbose && @info "$(a.info) is connected to $(b.info)"
    return b
end

function -(a::Detector,  b::SubCircuitAB)
    connect!(a.sim_environment, a.pin_anode, b.pin_input)
    a.sim_environment.option_verbose && @info "$(a.info) is connected to $(b.info)"
    return b
end

function -(a::Tuple{Symbol,Any},  b::Tuple{Symbol,Any})
    connect!(a.sim_environment, a, b)
    a.sim_environment.option_verbose && @info "$(a.info) is connected to $(b.info)"
    return b
end

function -(a::SubCircuitAB,  b::Tuple{Symbol,Any})
    connect!(a.sim_environment, a.pin_output, b)
    a.sim_environment.option_verbose && @info "$(a.info) is connected to $(b.info)"
    return b
end

function -(a::Tuple{Symbol,Any},  b::SubCircuitAB)
    connect!(a.sim_environment, a, b.pin_input)
    a.sim_environment.option_verbose && @info "$(a.info) is connected to $(b.info)"
    return b
end
"""
    Connect a LightSource to an OpticalFilter
"""
function -(a::LightSource,  b::OpticalFilter)
    a.sim_environment.schematic.model_runner == nothing ? a.optical_output = b  : error("cannot modify a compiled Environment, start a new instance of Environment")
    a.sim_environment.option_verbose && @info "$(a.info) is connected to $(b.info)"
    return b
end

function -(a::OpticalFilter,  b::OpticalFilter)
    a.sim_environment.schematic.model_runner == nothing ? a.optical_output = b  : error("cannot modify a compiled Environment, start a new instance of Environment")
    a.sim_environment.option_verbose && @info "$(a.info) is connected to $(b.info)"
    return b
end
