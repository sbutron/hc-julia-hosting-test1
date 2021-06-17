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

# ╔═╡ 0f8906d0-cf6f-11eb-29ba-bb68cc5e88d3
begin
	using PhotoMC
	using Distributions
	using Plots
	using PlutoUI
	md"""Loading dependencies."""
	
	# make cells wider
	html"""<style>
main {
    max-width: 1000px;
"""
end

# ╔═╡ b4f78c02-e12b-4261-a832-4f6162b5c3eb
md"""
## Simulation Parameters
Photons per pulse:
$(@bind photons_input Slider(1:100000, default = 1000, show_value=true)) ph/pulse |
Wavelength:
$(@bind wavelength_input Slider(300:900, default = 500, show_value=true)) nm 

Pulse width:
$(@bind pulse_width_input Slider(1:5000, default = 1000, show_value=true)) ns | 
Delay:
$(@bind delay_input Slider(1:5000, default = 1000, show_value=true)) ns 

Beam diameter:
$(@bind beam_dia_input Slider(100:3000, default = 500, show_value=true)) um | 
"""

# ╔═╡ b0e9b04e-c721-4c08-a427-d5febef1cc40
begin
	phs = photons_input
	pw = pulse_width_input * 1e-9
	pulse_delay = delay_input * 1e-9
	beam_dia = beam_dia_input * 1e-6
	wavelength = wavelength_input * 1e-9
	env = Environment(
		time_start = 0.0,
		time_end = 10e-6,
		time_step = 100e-12,
		verbose = true,
		plot = false,
		save_path = @__DIR__
		)
	md"""Creating the Environment"""
end

# ╔═╡ 95f384ed-fa71-4dc6-a5e1-0ac596ce19f4
begin
	apd = S14645_02(env)
	apd_probe = Oscilloscope_50Ω(env, probe_label = "S14645-02")
	apd - apd_probe
	
	mppc = S13360_3050CS(env)
	mppc_probe = Oscilloscope_50Ω(env, probe_label = "S13360-3050CS")
	mppc - mppc_probe
	
	pmt = R9880U_01(env)
	pmt_probe = Oscilloscope_50Ω(env, probe_label = "R9880U-01")
	pmt - pmt_probe
	md"""Add the detectors."""
end

# ╔═╡ 3d571da3-e556-4f3c-8d33-b91b370391f6
begin
	ls = FocusedSource(env,
            pulse_shape = :square,
            photons_per_pulse = phs,
            pulse_width = pw,
            delay = pulse_delay,
            frequency = 1,
            wavelength_distribution = Normal(wavelength,10e-9),
            distribution_x = Normal(0,beam_dia),
            distribution_y = Normal(0,beam_dia),
            info = ""
            )
	md"""Add the light source"""
end

# ╔═╡ a8b3c9b1-6179-4964-a3b6-73f8a780ad52
begin
	simulate!(env)
	md"""Simulate the environment"""
end

# ╔═╡ 668c8d7f-5454-482d-8694-07c298143151
begin
	apd_plot = plot(env.stats_time, env.schematic.stats_probe_outputs[:,1], label = env.schematic.probe_labels[1])
	mppc_plot = plot(env.stats_time, env.schematic.stats_probe_outputs[:,2], label = env.schematic.probe_labels[2])
	pmt_plot = plot(env.stats_time, env.schematic.stats_probe_outputs[:,3], label = env.schematic.probe_labels[3])
	plot(apd_plot, mppc_plot, pmt_plot, layout = (3,1), size = (1000,500))
end

# ╔═╡ 1bbdd071-2bd6-4069-94ce-f5d1bba39e15
sum(apd.stats_photon_pe)

# ╔═╡ Cell order:
# ╠═0f8906d0-cf6f-11eb-29ba-bb68cc5e88d3
# ╠═b0e9b04e-c721-4c08-a427-d5febef1cc40
# ╠═95f384ed-fa71-4dc6-a5e1-0ac596ce19f4
# ╠═3d571da3-e556-4f3c-8d33-b91b370391f6
# ╠═a8b3c9b1-6179-4964-a3b6-73f8a780ad52
# ╟─b4f78c02-e12b-4261-a832-4f6162b5c3eb
# ╠═668c8d7f-5454-482d-8694-07c298143151
# ╠═1bbdd071-2bd6-4069-94ce-f5d1bba39e15
