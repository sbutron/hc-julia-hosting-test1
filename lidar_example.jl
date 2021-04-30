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

# ╔═╡ a5c5d7ea-a927-11eb-2d25-79ef8288a5e3
begin
	using PhotoMC
	using Distributions
	using Plots
	using PlutoUI
	md"""Loading dependencies."""
end

# ╔═╡ d28be694-3ad1-47a6-b4ac-ce14d0486838
md"""
# Simulating APD and MPPC for LIDAR
The analysis for this simulator was adapted from the following paper:

Padmanabhan P, Zhang C, Charbon E. Modeling and Analysis of a Direct Time-of-Flight Sensor Architecture for LiDAR Applications. Sensors (Basel, Switzerland). 2019 Dec;19(24). DOI: 10.3390/s19245464.


## Parameters


- Distance $d$ in meters

- Vertical static FOV $\theta_V$

- Horizontal static FOV $\theta_H$

- Laser power (emitted) $P_{laser}$

- Laser power (recieved) $P_{return}$

- Lens diameter $D_{lens}$

- Solar spectral irradiance $P_{solar}$ (from ASTM G173)

- Spectral bandwidth $\Delta_{bw}$

- Reflectivity $\eta$

- Atmospheric extinction coefficient $\gamma$

## Calculations
The size of the illumated area projected at a target plane at the distance $d$:

$A_{cov} = {4*d^2 * tan({\theta_H\over 2}) * tan({\theta_H\over 2})}$

The size of the recieving aperture:

$A_{aperture} = {\pi {D_{lens}^2} \over 4}$

The solar irradiance



"""

# ╔═╡ b13a92e9-bfdb-420a-b7c0-b7885f69fe77
md"""
## Simulation Parameters
Distance:
$(@bind distance_input Slider(10:200, show_value=true))m

Background:
$(@bind klux Slider(1:100, show_value=true))klux

Laser Power:
$(@bind lpower Slider(1:200, show_value=true))W

Laser Pulse Width:
$(@bind lwidth Slider(500:5000, show_value=true))ps
"""

# ╔═╡ c2efc74b-7878-4465-9e3d-5e481a928f85
begin
	# shared parameters
	distance = distance_input
	target_reflectivity = 0.1
	FOV_horizontal_degrees = 0.2
	FOV_vertical_degrees = 0.2
	min_wavelength = 895e-9
	max_wavelength = 915e-9
	ambient_lux = klux * 1e3
	lens_transmittance = 0.9
	extinction_coeff = 0.15
	laser_power_W = lpower * 1.0
	pulse_width = lwidth * 1e-12
	laser_wavelength_distribution = Normal(905e-9,1e-9)
	laser_rep_rate = 1.0

	# detector setup specific parameters
	mppc_position = Coordinate(10,10)
	apd_position = Coordinate(0,0)

	env = Environment(
		time_start = -200e-9,
		time_end = 2e-6,
		time_step = 100e-12,
		verbose = true,
		plot = true,
		save_path = @__DIR__
		)
	md"""Creating the simulation environment."""
end

# ╔═╡ ce868e51-7824-44bc-af50-46e8ab4c0c78
begin
	mppc_bpf = FL905_10(env, position = mppc_position)
	apd_bpf = FL905_10(env, position = apd_position)
	lidarsys_apd =  LIDARSystem(
						env,
						distance = distance,
						target_reflectivity = target_reflectivity,
						FOV_horizontal_degrees = FOV_horizontal_degrees,
						FOV_vertical_degrees = FOV_vertical_degrees,
						min_wavelength = min_wavelength,
						max_wavelength = max_wavelength,
						ambient_lux = ambient_lux,
						lens_diameter = 25e-3,
						lens_transmittance = lens_transmittance,
						BPF = FL905_10(env, position = apd_position),
						beam_center = apd_position,
						beam_width = 0.1e-3,
						atmospheric_extinction_coefficient_per_km = extinction_coeff,
						laser_power_W = laser_power_W,
						pulse_width = pulse_width,
						laser_wavelength_distribution = laser_wavelength_distribution,
						laser_rep_rate = laser_rep_rate,
						info = "APD LIDAR System"
						)
	md"""Creating a LIDAR system for the APD."""
end

# ╔═╡ 141ea126-2b24-4cfe-8247-b07f2cc1dbd3
begin
	lidarsys_mppc =  PhotoMC.LIDARSystem(
						env,
						distance = distance,
						target_reflectivity = target_reflectivity,
						FOV_horizontal_degrees = FOV_horizontal_degrees,
						FOV_vertical_degrees = FOV_vertical_degrees,
						min_wavelength = min_wavelength,
						max_wavelength = max_wavelength,
						ambient_lux = ambient_lux,
						lens_diameter = 25e-3,
						lens_transmittance = lens_transmittance,
						BPF = FL905_10(env, position = mppc_position),
						beam_center = mppc_position,
						beam_width = 0.75e-3,
						atmospheric_extinction_coefficient_per_km = extinction_coeff,
						laser_power_W = laser_power_W,
						pulse_width = pulse_width,
						laser_wavelength_distribution = laser_wavelength_distribution,
						laser_rep_rate = laser_rep_rate,
						info = "MPPC LIDAR System"
						)
	md"""Creating a LIDAR system for the MPPC."""
end

# ╔═╡ fd254609-607a-4212-98cd-3b5463378637
begin
	apd = S14645_02(env, position = apd_position)
	mppc = S13720_1325CS(env, position = mppc_position)
	md"""Creating the detectors."""
end

# ╔═╡ 62e7168a-a946-49bc-ab32-177b50014f32
begin
	apd - Oscilloscope_50Ω(env, probe_label = "MPPC Vout")
	mppc - Oscilloscope_50Ω(env, probe_label = "APD Vout")
	md"""Connecting the detectors to probes."""
end

# ╔═╡ 2f237701-8eb8-46d1-aba4-eeca4159cd8f
begin
	simulate!(env)
	md"""Simulate the circuit"""
end

# ╔═╡ 57de4a38-a85a-493e-8852-0a3f09d9c537
begin
	waveform_apd = plot(env.stats_time * Constants.c / 2, env.schematic.stats_probe_outputs[:,1], label = "S14645-02", xlims = (0, env.time_end * Constants.c / 2), xlabel = "Distance (m)", ylabel ="Output (V)")
	
	waveform_mppc = plot(env.stats_time * Constants.c / 2, env.schematic.stats_probe_outputs[:,2], label = "S13720-1325CS", xlims = (0, env.time_end * Constants.c / 2), xlabel = "Distance (m)", ylabel ="Output (V)")

    plot(waveform_apd, waveform_mppc, layout = (2,1))
   
end

# ╔═╡ Cell order:
# ╠═d28be694-3ad1-47a6-b4ac-ce14d0486838
# ╠═a5c5d7ea-a927-11eb-2d25-79ef8288a5e3
# ╠═c2efc74b-7878-4465-9e3d-5e481a928f85
# ╠═ce868e51-7824-44bc-af50-46e8ab4c0c78
# ╠═141ea126-2b24-4cfe-8247-b07f2cc1dbd3
# ╠═fd254609-607a-4212-98cd-3b5463378637
# ╠═62e7168a-a946-49bc-ab32-177b50014f32
# ╠═2f237701-8eb8-46d1-aba4-eeca4159cd8f
# ╠═b13a92e9-bfdb-420a-b7c0-b7885f69fe77
# ╟─57de4a38-a85a-493e-8852-0a3f09d9c537
