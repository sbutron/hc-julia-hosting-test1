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
html"""<style>
main {
    max-width: 1000px;
"""
end

# ╔═╡ 6627f622-6842-4c5d-9eaa-b73f4bbd0ab8
md"""# Building the Simulation
In this example we're simulating an MPPC with an amplifier circuit."""

# ╔═╡ 9d029b7b-f7ae-4125-81e9-f843d542edec
md"""## How it Works """

# ╔═╡ dbb01168-bb36-4706-85eb-4b83862058f7
md"""## Running the Simulation
Try changing the parameters.

### Light Source
Light levels:
$(@bind photon_input Slider(1:10000, default = 2000, show_value = true)) ph/pulse |
Pulse width:
$(@bind pw_input Slider(1:5000, default = 2000, show_value = true)) ns |
Pulse delay:
$(@bind p_delay Slider(1:10000, default = 5000, show_value = true)) ns 

Frequency:
$(@bind p_freq Slider(1:10_000, default = 1, show_value = true)) kHz |
Wavelength:
$(@bind p_wavelength Slider(300:900, default = 470, show_value = true)) nm |
Pulse shape:
$(@bind p_shape Select(["Square", "Gaussian"]))


### Readout Circuit
Feedback resistance:
$(@bind rf_input Slider(1:10000, default = 1000, show_value = true)) ohms |

$(@bind go Button("Run Simulation"))

"""


# ╔═╡ 86a10170-a8f3-11eb-0abf-5d38a978a61d
begin
	photons_per_pulse = photon_input
	pulse_width = pw_input * 1e-9
	pulse_shape = p_shape == "Square" ? :square : :gaussian
	pulse_delay = p_delay * 1e-9 # p_delay is in ns
	rep_rate = p_freq * 1e3 # p_freq is in kHz
	center_wavelength = p_wavelength * 1e-9 # p_wavelength is in nm
	r2val = rf_input
	env = Environment(
		time_start = 0,
		time_end = 10e-6,
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
						pulse_shape = pulse_shape,
						photons_per_pulse = photons_per_pulse,
						pulse_width = pulse_width,
						delay = pulse_delay,
						frequency = rep_rate,
						wavelength_distribution = Normal(center_wavelength,1e-9),
						distribution_x = Normal(0, 0.5e-3),
						distribution_y = Normal(0, 0.5e-3),
						info="200pW light source"
					)
md"""We add a light source to the environment to the environment"""
end

# ╔═╡ 43f4d5c0-1704-4ac0-967d-ca44e2248ed3
begin
	r11 = Resistor_Ideal(env, 50, "R11")
	u1 = OPA846(env)
	r5 = Resistor_Ideal(env, 51, "R5") 
	r2 = Resistor_Ideal(env, r2val, "R2") 
	r1 = Resistor_Ideal(env, 51, "R51")
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
	go
	run = simulate!(env)
	md"""Run the simulation environment"""
end

# ╔═╡ db6f19dc-f632-45ec-9651-396a58c47a70
begin
	run
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
# ╠═6627f622-6842-4c5d-9eaa-b73f4bbd0ab8
# ╟─9d029b7b-f7ae-4125-81e9-f843d542edec
# ╠═0bd27af6-e419-4bff-86ff-fba46de2c0ba
# ╠═86a10170-a8f3-11eb-0abf-5d38a978a61d
# ╠═bef78c74-ae9e-437e-b850-4c64a883268d
# ╠═22da75b2-498e-4233-831e-fe2a28c4d9c2
# ╠═43f4d5c0-1704-4ac0-967d-ca44e2248ed3
# ╠═e62b2af5-acf4-44ea-8ed9-263b7c957da1
# ╟─dbb01168-bb36-4706-85eb-4b83862058f7
# ╟─db6f19dc-f632-45ec-9651-396a58c47a70
# ╠═a74fcb64-db7c-47f4-a5ed-f44595dfd54c
