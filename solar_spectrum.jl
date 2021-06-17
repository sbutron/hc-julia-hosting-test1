### A Pluto.jl notebook ###
# v0.14.4

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 0bd27af6-e419-4bff-86ff-fba46de2c0ba
begin
	using PhotoMC
	using Plots
	using Plots.PlotMeasures 
	using Distributions
	using PlutoUI	
	gr()
	
md"""Loading dependencies"""
html"""<style>
main {
    max-width: 1500px;
"""
end

# ╔═╡ 6627f622-6842-4c5d-9eaa-b73f4bbd0ab8
md"""# Solar Spectrum
Calculating the estimated flux density from solar irradiance."""

# ╔═╡ faced6ce-b04a-431d-9ceb-d0e768cd99d6
md"""
### Global:
Ambient $(@bind klux NumberField(1:100, default = 100)) klux |
Lens diameter $(@bind dlens NumberField(1:100, default = 25)) mm |

Static FOV $(@bind fov NumberField(0.1:0.1:2, default = 0.5)) deg. |
Reflectivity $(@bind refl NumberField(1:1:100, default = 10)) %. 

Lens transmit $(@bind tlens NumberField(1:1:100, default = 90)) %. |
Filter transmit $(@bind tfilt NumberField(1:1:100, default = 90)) %. 

### Range 1:
Min wavelength $(@bind min_a NumberField(281:4000, default = 1540)) nm |
Max Wavelength $(@bind max_a NumberField(281:4000, default = 1560)) nm


### Range 2:
Min wavelength $(@bind min_b NumberField(281:4000, default = 895)) nm |
Max Wavelength $(@bind max_b NumberField(281:4000, default = 915)) nm
"""

# ╔═╡ 86a10170-a8f3-11eb-0abf-5d38a978a61d
begin
	d = 1
	afov = 4*(d^2)*tand(fov/2)*tand(fov/2) 
	r = refl/100
	Tl = tlens /100
	Tf = tfilt/100
	solarall = PhotoMC.SolarSpectrum(2.81e-7, 4e-6, klux * 1e3)
	solara = PhotoMC.SolarSpectrum(min_a * 1e-9, max_a * 1e-9, klux * 1e3)
	solarb = PhotoMC.SolarSpectrum(min_b * 1e-9, max_b * 1e-9, klux * 1e3)
	lensarea = pi*(dlens*1e-3/2)^2
	@info ""
end

# ╔═╡ 94940b18-8d0b-4bc6-a5bb-27cf4b78078d
#solarall.counts ph/s/sq.m
begin
	plot(solarall.values, solarall.counts * Tl * Tf * r, xlabel = "Wavelength (nm)", ylabel = "ph/(s*sq.m*nm)", label ="ASTM-G173 Direct+Circumsolar", xlims = (600e-9, 2000e-9), size = (1500,500), margin = 10mm)
	plot!(Shape([min_a*1e-9, max_a*1e-9, max_a*1e-9, min_a*1e-9], [0, 0, maximum(solara.counts) * Tl * Tf * r, maximum(solara.counts) * Tl * Tf * r]), linecolor = :red, fillcolor = :red, opacity = 0.5, label = "Range $(mean([max_a,min_a]))nm")
	plot!(Shape([min_b*1e-9, max_b*1e-9, max_b*1e-9, min_b*1e-9], [0, 0, maximum(solarb.counts) * Tl * Tf * r, maximum(solarb.counts) * Tl * Tf * r]), linecolor = :orange, fillcolor = :orange, opacity = 0.5, label = "Range $(mean([max_b,min_b]))nm")
end

# ╔═╡ 38a04573-559f-4a20-8180-a64bbbb66577
	function pbackground(ps)
		return ps * afov * r * (dlens*1e-3/(2*d))^2 * Tl * Tf * 2 /pi
	end

# ╔═╡ d1ad060e-2b0c-4869-9a40-99c2aa02769c
md"""
##### Range $(mean([max_a,min_a]))nm:
- $(sum(solara.counts)) ph/(sec*sq.mm)
 
- $(pbackground(sum(solara.counts))) ph/(sec)


##### Range $(mean([max_b,min_b]))nm:
 - $(sum(solarb.counts)) ph/(sec*sq.mm)
 
 - $(pbackground(sum(solarb.counts))) ph/(sec)


### $min_a nm to $max_a nm ( $(max_a - min_a)nm ) system sees $(round(pbackground(sum(solara.counts))/pbackground(sum(solarb.counts))*100))% as many background photons as $min_b nm to $max_b nm ( $(max_b - min_b)nm ).
""" 

# ╔═╡ Cell order:
# ╟─6627f622-6842-4c5d-9eaa-b73f4bbd0ab8
# ╠═0bd27af6-e419-4bff-86ff-fba46de2c0ba
# ╠═faced6ce-b04a-431d-9ceb-d0e768cd99d6
# ╟─d1ad060e-2b0c-4869-9a40-99c2aa02769c
# ╠═94940b18-8d0b-4bc6-a5bb-27cf4b78078d
# ╠═86a10170-a8f3-11eb-0abf-5d38a978a61d
# ╟─38a04573-559f-4a20-8180-a64bbbb66577
