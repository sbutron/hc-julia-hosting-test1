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
	using Distributions
	using PlutoUI
	gr()
	md"""Loading dependencies"""
end

# ╔═╡ 6627f622-6842-4c5d-9eaa-b73f4bbd0ab8
md"""# Building the Simulation
In this example we're simulating an MPPC with an amplifier circuit."""

# ╔═╡ dbb01168-bb36-4706-85eb-4b83862058f7
md"""# Plotting the results
Try changing the parameters.

Light levels:
$(@bind photon_input Slider(1:10000, default=2000))

Pulse Width:
$(@bind pw_input Slider(1:5000, default=2000))
"""


# ╔═╡ 86a10170-a8f3-11eb-0abf-5d38a978a61d
begin
	photons_per_pulse = photon_input
	pulse_width = pw_input * 1e-9
	env = Environment(
		time_start = 0,
		time_end = 5e-6,
		time_step = 100e-12,
		verbose = false,
		plot = true,
		save_path = @__DIR__
		)
	md"""Initialize the simulation environment."""
end

# ╔═╡ bef78c74-ae9e-437e-b850-4c64a883268d
begin
	mppc = S13360_3050CS(
							env, 
							position = Coordinate(0,0)
						)
md"""Add S13360-3050CS (MPPC) to the environment"""
end

# ╔═╡ 22da75b2-498e-4233-831e-fe2a28c4d9c2
begin
	ls = FocusedSource(
						env,
						pulse_shape = :square,
						photons_per_pulse = photons_per_pulse,
						pulse_width = pulse_width,
						delay = 2.5e-6,
						frequency = 1,
						wavelength_distribution = Normal(470e-9,1e-9),
						distribution_x = Normal(0, 0.5e-3),
						distribution_y = Normal(0, 0.5e-3),
						info="200pW light source"
					)
md"""We add a light source to the environment to the environment"""
end

# ╔═╡ 43f4d5c0-1704-4ac0-967d-ca44e2248ed3
begin
	r11 = Resistor_Noisy(env, 50, "R11")
	u1 = OPA846(env)
	r5 = Resistor_Noisy(env, 51, "R5") 
	r2 = Resistor_Noisy(env, 1e3, "R2") 
	r1 = Resistor_Noisy(env, 51, "R51")
	current_probe = Probe_Current(env, probe_label = "Anode Current")
	voltage_probe = Oscilloscope_1MΩ(env, probe_label = "Amplifier Voltage")
	connect!(env, mppc.pin_anode, current_probe.pin_input)
	connect!(env, current_probe.pin_output, r11.pin_1, u1.pin_in_pos)
	connect!(env, u1.pin_out_pos, r5.pin_1, r2.pin_1)
	connect!(env, r2.pin_2, r1.pin_1, u1.pin_in_neg)
	connect!(env, r5.pin_2, voltage_probe. pin_input)
	connect!(env, :gnd, r11.pin_2, r1.pin_2, u1.pin_out_neg)
md"""We add a readout circuit"""
end

# ╔═╡ e62b2af5-acf4-44ea-8ed9-263b7c957da1
begin
	simulate!(env)
	md"""Run the simulation environment"""
end

# ╔═╡ db6f19dc-f632-45ec-9651-396a58c47a70
begin
	p = plot(env.stats_time, 
		env.schematic.stats_probe_outputs[:,2], 
		label = env.schematic.probe_labels[2],
		xlabel = "Time(s)",
		ylabel = "Voltage (V)"
	)
end

# ╔═╡ a74fcb64-db7c-47f4-a5ed-f44595dfd54c
md"""
## Simulation parameters:

Photons per pulse: $photons_per_pulse photons

Pulse width: $pw_input ns
"""

# ╔═╡ Cell order:
# ╟─6627f622-6842-4c5d-9eaa-b73f4bbd0ab8
# ╠═0bd27af6-e419-4bff-86ff-fba46de2c0ba
# ╠═86a10170-a8f3-11eb-0abf-5d38a978a61d
# ╠═bef78c74-ae9e-437e-b850-4c64a883268d
# ╠═22da75b2-498e-4233-831e-fe2a28c4d9c2
# ╠═43f4d5c0-1704-4ac0-967d-ca44e2248ed3
# ╠═e62b2af5-acf4-44ea-8ed9-263b7c957da1
# ╠═dbb01168-bb36-4706-85eb-4b83862058f7
# ╟─db6f19dc-f632-45ec-9651-396a58c47a70
# ╠═a74fcb64-db7c-47f4-a5ed-f44595dfd54c
