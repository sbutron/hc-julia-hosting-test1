function postprocess_fwhm(subckt::SubCircuitAB)
    postprocess_fwhm(subckt.components[1])
end
function postprocess_fwhm(probe::ElectricalProbe)
    max = maximum(probe.stats_output)
    x2 = searchsortedfirst(probe.stats_output, max/2, rev = true)
    x1 = searchsortedfirst(probe.stats_output, max/2)
    if x1 > probe.sim_environment.step_total || x2 > probe.sim_environment.step_total
        return 0.0
    else
        return probe.sim_environment.stats_time[x2] - probe.sim_environment.stats_time[x1]
    end
end

function postprocess_time_over_threshold(subckt::SubCircuitAB; threshold_set::Float64, threshold_reset::Float64)
    postprocess_time_over_threshold(subckt.components[1], threshold_set=threshold_set, threshold_reset=threshold_reset)
end
function postprocess_time_over_threshold(probe::ElectricalProbe; threshold_set::Float64, threshold_reset::Float64)
    @assert threshold_set > threshold_reset "set threshold must be higher than reset threshold"
    t1 = 0.0
    t2 = 0.0
    i = 1
    while i < probe.sim_environment.step_total
        if probe.stats_output[i] > threshold_set
            t1 = i*probe.sim_environment.time_step
            break
        end
        i += 1
    end
    while i < probe.sim_environment.step_total
        if probe.stats_output[i] < threshold_reset
            t2 = i*probe.sim_environment.time_step
            break
        end
        i += 1
    end
    return t2 - t1
end

function postprocess_peak(subckt::SubCircuitAB)
    postprocess_peak(subckt.components[1])
end
function postprocess_peak(probe::ElectricalProbe)
    maximum(probe.stats_output)
end
