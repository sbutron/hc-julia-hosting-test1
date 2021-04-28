# mutable struct InterpolatedTable
#     x::Vector{Float64}
#     y::Vector{Float64}
# end
# @time data = convert(Array{Float64,2},)
# data = interpolated_array(Data.S13360_50um["relative_pde"]; min=0, max=10, precision=0.1, poly_degree=5)
# @time lookup(data, 2.5)

@inline function poly_fit(data::Array{Any,2}, poly_degree::Integer)
    data = convert(Array{Float64,2}, data)
    @views Polynomials.fit(data[:,1],data[:,2], poly_degree)
end
@inline function poly_fit(data::Array{Float64,2}, poly_degree::Integer)
    @views Polynomials.fit(data[:,1],data[:,2], poly_degree)
end

@inline function lookup(data::Array{Float64,2}, x::Real)::Float64
    x = convert(Float64, x)
    if x > data[begin,1] && x < data[end,1]
        #return @views data[searchsortedfirst(data[:,1], x),2]
        return get_row_column(data, searchsortedfirst(data[:,1], x), 2)
    else
        return 0.0
    end
end

@inline function lookup(poly::Polynomial{Float64}, x::Float64)
    return poly(x)
end

@inline function lookup(distribution::Distribution, x::Float64)
    return pdf.(distribution, x)
end

function interpolated_array(data::Array{Any,2}; precision::Real)
    precision = convert(Float64, precision)
    data = convert(Array{Float64,2}, data)
    x_result = []
    y_result = []
    for x = data[1, 1] : precision : data[end, 1]
        push!(x_result, x)
        push!(y_result, interpolated(data, x))
    end
    return hcat(x_result, y_result)
end

function interpolated(data::Array{Float64,2}, x::Float64)
    @views i0 = searchsortedlast(data[:,1], x)
    @views i1 = searchsortedfirst(data[:,1], x)
    @views x0 = data[:,1][i0]
    @views x1 = data[:,1][i1]
    @views y0 = data[:,2][i0]
    @views y1 = data[:,2][i1]
    #return x0, x1, y0, y1
    return linear_interpolation(x0, x1, y0, y1, x)
end

function linear_interpolation(x0::Float64, x1::Float64, y0::Float64, y1::Float64, x::Float64)
    if x0 == x1
        return y0
    else
        return y = y0 + (x - x0) * (y1 - y0) / (x1 - x0)
    end
end


## converts FHWM to standard deviation
"""
    fwhm_to_stddev(fwhm)
    Converts FWHM to Standard Deviation using the equation FWHM / sqrt(8*log(2))

    # Examples
    julia> fwhm_to_stddev(3)
    1.2739827004320285
"""
function fwhm_to_stddev(fwhm::Float64)::Float64
    return fwhm / sqrt(8*log(2))
end

function time_response_to_time_constant(time_response::Float64)::Float64
    return time_response/log(9)
end

function time_span_to_steps(time_start::Float64, time_end::Float64, time_step::Float64)::Integer
    steps = 0
    time_now = time_start
    while time_now < time_end
        steps += 1
        time_now += time_step
    end
    return steps
end
## returns Float64 of number rounded to nearest increment
"""
    round_to(number_to_round,rounding_increment)
    Rounds real number_to_round to the nearest multiple of rounding_increment

    # Examples
    julia> round_to(3.2,6)
    6.0
"""
function round_to(number_to_round::Float64, rounding_increment::Float64)::Float64
    # return div(number_to_round, rounding_increment, RoundNearestTiesAway) * rounding_increment
    return round(number_to_round / rounding_increment, RoundNearestTiesAway) * rounding_increment
end
function celsius_to_kelvin(celsius::Float64)::Float64
    return celsius + 273.15
end
"""
    A simple extraction procedure for determining the electrical parameters in Silicon Photomultipliers. G. Giustolisi, Sept. 2013
"""
function sipm_parameter_extraction(fast_peak::Float64, slow_peak::Float64, τ_rise_fast::Float64, τ_fall_fast::Float64, τ_rise_slow::Float64, τ_fall_slow::Float64, gain::Float64, overvoltage::Float64, number_of_microcells::Int64, terminal_capacitance::Float64)
    Ve = overvoltage
    N::Float64 = number_of_microcells
    A1 = slow_peak
    A2 = fast_peak
    T1 = τ_fall_slow
    T2 = τ_fall_fast
    Tz = T1 * T2 * (1+ A1/A2) / (T2 + T1*A1/A2)
    Cf = gain * Constants.q / Ve
    Ct = terminal_capacitance
    Rq = T1 / Cf
    Cq = Tz / Rq
    Cd = Cf - Cq
    Cg = Ct - N*Cd*Cd / (Cd+Cq)

    #
    # Rd = τ_rise_fast / Cq➕Cd
    #
    # Ctot➕Cg = τ_fall_fast  / 50
    # CqCd = Ctot * Cq➕Cd
    # CqplusCd = Cq➕Cd
    # Cd = (-Cq➕Cd - sqrt((Cq➕Cd^2) - (4*(-1)*(-CqCd)))) / -2
    # Cq = Cq➕Cd - Cd

    fast_pulse_ratio = Cq / (Cd+Cq)
    slow_pulse_ratio = 1-fast_pulse_ratio

    return Rq, Cq, Cd, Cg, fast_pulse_ratio, slow_pulse_ratio
end

function sample_interval_to_bandwidth(sample_interval::Float64)
    #https://community.sw.siemens.com/s/article/digital-signal-processing-sampling-rates-bandwidth-spectral-lines-and-more#:~:text=The%20bandwidth%20is%20half%20of,the%20maximum%20frequency%20of%20interest.&text=A%20bandwidth%20of%201000%20Hertz,set%20to%202000%20samples%2Fsecond.
    Fs = 1/sample_interval
    return Fs/2
end

function wavelength_to_joules(λ::Float64)::Float64
    return Constants.h * Constants.c / λ
end

function watts_to_photon_rate(;watts::Real, wavelength::Float64)
    _joules = wavelength_to_joules(wavelength)
    return watts/_joules
end

watts_to_photon_rate(watts=1.0, wavelength=500e-9)
