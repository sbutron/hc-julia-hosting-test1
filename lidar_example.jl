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
	
	# make cells wider
	html"""<style>
main {
    max-width: 1000px;
"""
end

# ╔═╡ 91bc1afc-f6c1-4221-b701-ec1e9502be5c
md"""# LIDAR Simulation

The analysis for this simulation is adapted from: 

	Padmanabhan P, Zhang C, Charbon E. Modeling and Analysis of a Direct Time-of-Flight Sensor Architecture for LiDAR Applications. Sensors (Basel, Switzerland). 2019 Dec;19(24). DOI: 10.3390/s19245464.

DISCLAIMER: This simulation should be regarded as a reference only, no guarantee of detector performance is implied by the results of this simulation.

"""



# ╔═╡ b13a92e9-bfdb-420a-b7c0-b7885f69fe77
md"""
## Simulation Parameters
#### Environment Conditions 
Distance:
$(@bind distance_input Slider(10:300, default = 50, show_value=true)) m |
Ambient background:
$(@bind klux Slider(1:100, default = 50, show_value=true)) klux | 

Lens Diameter:
$(@bind lens_dia Slider(1:100, default = 25, show_value=true)) mm |
Static FOV:
$(@bind fov_input Slider(0.1:0.1:1, default = 0.2, show_value=true)) deg. |

#### Laser Parameters
Laser power:
$(@bind lpower Slider(1:200, default = 100, show_value=true)) W |
Laser pulse width:
$(@bind lwidth Slider(500:30_000, default = 3000, show_value=true)) ps |

Frequency:
$(@bind lreprate Slider(1:20_000_000, default = 1, show_value=true)) Hz

#### Options
X-axis:
$(@bind xaxis_type Select(["Time", "Distance"]))
$(@bind manualrun Button("Simulate"))
"""

# ╔═╡ 66491045-52bf-4ffd-873b-bb5d4c2e136d
md"""## How it Works"""

# ╔═╡ c2efc74b-7878-4465-9e3d-5e481a928f85
begin
	# shared parameters
	distance = distance_input
	target_reflectivity = 0.1
	lens_diameter = float(lens_dia)*1e-3 # value is in mm
	FOV_horizontal_degrees = float(fov_input) 
	FOV_vertical_degrees = float(fov_input) 
	min_wavelength = 895e-9
	max_wavelength = 915e-9
	ambient_lux = klux * 1e3 # value is in k lux
	lens_transmittance = 0.9
	extinction_coeff = 0.15
	laser_power_W = lpower * 1.0
	pulse_width = lwidth * 1e-12
	laser_wavelength_distribution = Normal(905e-9,1e-9)
	laser_rep_rate = float(lreprate)

	# detector setup specific parameters
	mppc_position = Coordinate(10,10)
	apd_position = Coordinate(0,0)
	

	env = Environment(
		time_start = -200e-9,
		time_end = 2e-6,
		time_step = 100e-12,
		verbose = true,
		plot = false,
		save_path = @__DIR__
		)
	mppc_bpf = FL905_10(env, position = mppc_position, aperture = nothing)
	apd_bpf = FL905_10(env, position = apd_position, aperture = nothing)
	md"""Creating the simulation environment."""
end

# ╔═╡ ce868e51-7824-44bc-af50-46e8ab4c0c78
begin
	
	lidarsys_apd =  LIDARSystem(
						env,
						distance = distance,
						target_reflectivity = target_reflectivity,
						FOV_horizontal_degrees = FOV_horizontal_degrees,
						FOV_vertical_degrees = FOV_vertical_degrees,
						min_wavelength = min_wavelength,
						max_wavelength = max_wavelength,
						ambient_lux = ambient_lux,
						lens_diameter = lens_diameter,
						lens_transmittance = lens_transmittance,
						bpf = apd_bpf,
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
						lens_diameter = lens_diameter,
						lens_transmittance = lens_transmittance,
						bpf = mppc_bpf,
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
	manualrun

	r = simulate!(env)
	md"""Simulate the circuit"""
end

# ╔═╡ 57de4a38-a85a-493e-8852-0a3f09d9c537
begin
	r # make this cell dependent on running the simulation
	xdata = env.stats_time
	xlims = (0, env.time_end)
	xlabel = "Time (s)"
	if xaxis_type == "Distance"
		xdata *= Constants.c / 2
		xlims = (0, env.time_end * Constants.c / 2) 
		xlabel = "Distance (m)"
	end
	waveform_laser = plot(env.stats_time, env.light_sources[1].temporal_profile, label = "Laser Profile", xlims = (0,2e-6), xlabel = "Time (s)", ylabel ="Photons", widen = true)
	waveform_laser_actual = plot(env.stats_time, env.light_sources[1].stats_photons_emitted, label = "Laser Profile", xlims = (0,2e-6), xlabel = "Time (s)", ylabel ="Photons")
	waveform_apd = plot(xdata, env.schematic.stats_probe_outputs[:,1], label = "S14645-02", xlims = xlims, xlabel = xlabel, ylabel ="Output (V)")
	
	waveform_mppc = plot(xdata, env.schematic.stats_probe_outputs[:,2], label = "S13720-1325CS", xlims = xlims, xlabel = xlabel, ylabel ="Output (V)")

    plot(waveform_apd, waveform_mppc, waveform_laser_actual, layout = (3,1), size=(1000,650))
   
end

# ╔═╡ Cell order:
# ╟─91bc1afc-f6c1-4221-b701-ec1e9502be5c
# ╠═b13a92e9-bfdb-420a-b7c0-b7885f69fe77
# ╠═57de4a38-a85a-493e-8852-0a3f09d9c537
# ╟─66491045-52bf-4ffd-873b-bb5d4c2e136d
# ╠═a5c5d7ea-a927-11eb-2d25-79ef8288a5e3
# ╠═c2efc74b-7878-4465-9e3d-5e481a928f85
# ╠═ce868e51-7824-44bc-af50-46e8ab4c0c78
# ╠═141ea126-2b24-4cfe-8247-b07f2cc1dbd3
# ╠═fd254609-607a-4212-98cd-3b5463378637
# ╠═62e7168a-a946-49bc-ab32-177b50014f32
# ╠═2f237701-8eb8-46d1-aba4-eeca4159cd8f
