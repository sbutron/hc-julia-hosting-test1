import Base.rand

abstract type AbstractDistribution
end

mutable struct DistributionDefinition <: AbstractDistribution
    pdf::Vector{Float64}
    cdf::Vector{Float64}
end
mutable struct ArbitaryDistributionDefinition <: AbstractDistribution
    values::Vector{Any}
    counts::Vector{Float64}
    pdf::Vector{Float64}
    cdf::Vector{Float64}
end

function Borel(crosstalk_probability::Float64)::DistributionDefinition
    local μ = -log(1-crosstalk_probability)
    local pdf = zeros(Float64,100)
    local cdf = zeros(Float64,100)
    for n = 1:100
        pdf[n] = borel_pmf(μ, n)
        cdf[n] = sum(pdf)
    end
    DistributionDefinition(pdf::Vector{Float64}, cdf::Vector{Float64})
end

@inline function borel_pmf(μ::Float64, n::Integer)::Float64
    return exp(-μ*n) * ((μ*n)^(n-1)) / factorial(big(n))
end

function SolarSpectrum(min_wavelength::Float64, max_wavelength::Float64, lux::Real = 109870)
    lux::Float64 = lux
    baseline_lux = 109870 # https://en.wikipedia.org/wiki/Air_mass_(solar_energy)
    scale_factor = lux / baseline_lux

    @assert min_wavelength <= max_wavelength "invalid arguments: minumum wavelength must be less than maximum wavelength."

    _solarspectrum = interpolated_array(Data.ASTMG_173["direct_circumsolar"]; precision = 1)
    @views _solarspectrum[:,1] *= 1e-9 # wavelength in nm

    @assert min_wavelength > _solarspectrum[begin,1] "data unavailable: choose a minimum wavelength >= $(_solarspectrum[begin,1])."
    @assert max_wavelength < _solarspectrum[end,1] "data unavailable: choose a maximum wavelength <= $(_solarspectrum[end,1])."

    @views _solarspectrum[:,2] = _solarspectrum[:,2] .* _solarspectrum[:,1] .* scale_factor ./ (Constants.h * Constants.c)
    @views indexlow = searchsortedfirst(_solarspectrum[:,1], min_wavelength)
    @views indexhi = searchsortedfirst(_solarspectrum[:,1], max_wavelength)
    total_emission = sum(_solarspectrum[indexlow:(indexhi-1),2])
    local values = zeros(Float64, indexhi-indexlow)
    local pdf = zeros(Float64, indexhi-indexlow)
    local cdf = zeros(Float64, indexhi-indexlow)
    i = 0
    for λ = indexlow:(indexhi-1)
        i += 1
        values[i] = _solarspectrum[λ, 1]
        pdf[i] = _solarspectrum[λ, 2] / total_emission
        cdf[i] = sum(pdf)
    end
    ArbitaryDistributionDefinition(
        values::Vector{Float64}, # wavelength in nm
        _solarspectrum[indexlow:indexhi-1,2]::Vector{Float64}, # ph/(s * sq.m * nm)
        pdf::Vector{Float64},
        cdf::Vector{Float64})
end

function McIntyre(gain::Float64, excess_noise_figure::Float64)
    excess_noise_factor = gain^excess_noise_figure
    k_eff = apd_ionization_ratio(excess_noise_factor, gain)
    local pdf = Vector{Float64}(undef,0)
    local cdf = Vector{Float64}(undef,0)
    n = 1
    while n==1 || cdf[end] < 0.999
        push!(pdf, mcintyre_pdf(n, gain, k_eff))
        push!(cdf, sum(pdf))
        n += 1
    end
    DistributionDefinition(pdf::Vector{Float64}, cdf::Vector{Float64})
end

@inline function apd_ionization_ratio(excess_noise_factor::Float64, gain::Float64)::Float64
    return ((excess_noise_factor - 2)*gain + 1) / (gain-1)^2
end

"""
    Calculated the PDF of McIntyre's distribution of multiplied_electrons resulting from an APD with parameters gain and k_eff
    Adapted from "Computer Simulation of Avalanche Photodiode and Preamplifier Output fo rLaser Altimeters", X. Sun. The John Hopkins University Revision 1, October 1994.
"""
@inline function mcintyre_pdf(multiplied_electrons::Real, gain::Real, k_eff::Real)::Float64
    y::Integer = multiplied_electrons
    G::Float64 = gain
    k::Float64 = k_eff

    k1 = 1.0 - k
    G1 = G - 1.0
    m = y - 2
    x1 = log((1 + k*G1) / G)
    x2 = 1.0 + k * y / k1
    x3 = log(G1/G)
    x4 = 0.0

    for i = 0:m
        x4 = big(x4 + log(1 + (k * i / (y - i))))
    end
    return exp(x1 * x2 + x3 * (y - 1) + x4)
end

@inline function rand(distribution_definition::AbstractDistribution)
    return searchsortedfirst(distribution_definition.cdf, rand(), rev=false)
end

@inline function rand(rng::RandomNumbers.AbstractRNG, distribution_definition::AbstractDistribution)
    return searchsortedfirst(distribution_definition.cdf, rand(rng), rev=false)
end

@inline function rand(rng::RandomNumbers.AbstractRNG, distribution_definition::ArbitaryDistributionDefinition)
    return distribution_definition.values[searchsortedfirst(distribution_definition.cdf, rand(rng), rev=false)]
end

@inline function rand(distribution_definition::ArbitaryDistributionDefinition)
    return distribution_definition.values[searchsortedfirst(distribution_definition.cdf, rand(), rev=false)]
end

@inline function rand(rng::RandomNumbers.AbstractRNG, distribution_definition::AbstractDistribution, dims::Integer)
    return map(x-> rand(rng, distribution_definition), 1:dims)
end


@inline function rand(rng::RandomNumbers.AbstractRNG, distribution_definition::AbstractDistribution, dimx::Integer, dimy::Integer)
    reduce(hcat, map(x-> map(x-> rand(rng, distribution_definition), 1:dimx), 1:dimy))
end

"""
    local_rate(total_emitted::Real, distribution_x::Distribution, distribution_y::Distribution, preicision::Real)
    Returns the local rate out of the total_emitted
"""
@inline function local_rate(distribution::Distribution, x::Real, x_precision::Real, total_emitted::Real)
    return pdf.(distribution, x) * x_precision * total_emitted
end #function local rate

@inline function local_rate(distribution_x::Distribution, distribution_y::Distribution, pos_x::Real, pos_y::Real, pos_precision::Real, total_emitted::Real)
    return pdf.(distribution_x, pos_x) * pdf.(distribution_y, pos_y) * pos_precision * pos_precision * total_emitted

end #function local rate

function johnson_noise_rms(resistance::Float64, celsius_temperature::Float64, bandwidth::Float64)
    return sqrt(4 * Constants.kB * celsius_to_kelvin(celsius_temperature) * bandwidth / resistance)
end
