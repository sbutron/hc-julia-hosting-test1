function LIDARSystem(sim_environment::Environment;
                        distance::Real,
                        target_reflectivity::Real,
                        FOV_horizontal_degrees::Real,
                        FOV_vertical_degrees::Real,
                        min_wavelength::Real,
                        max_wavelength::Real,
                        ambient_lux::Real,
                        lens_diameter::Real,
                        lens_transmittance::Real,
                        BPF::WavelengthFilter,
                        beam_center::Coordinate = Coordinate(0,0),
                        beam_width::Real,
                        atmospheric_extinction_coefficient_per_km::Real,
                        laser_power_W::Real,
                        pulse_width::Real,
                        laser_wavelength_distribution::Distribution,
                        laser_rep_rate::Real,
                        info::String
                        )
    distance::Float64 = distance
    lens = Circle(center = beam_center, diameter = lens_diameter)
    area = areaof(lens)
    θH = deg2rad(FOV_horizontal_degrees)
    θV = deg2rad(FOV_vertical_degrees)
    solarspectrum = SolarSpectrum(min_wavelength, max_wavelength, ambient_lux)

    # A 1 × 16 SiPM Array for Automotive 3D Imaging LiDAR Systems
    # https://www.imagesensors.org/Past%20Workshops/2017%20Workshop/2017%20Papers/P19.pdf
    θH = deg2rad(FOV_horizontal_degrees) # AoVx static angle field of view
    θV = deg2rad(FOV_vertical_degrees) # AoVy
    Afov = 4 * (distance^2) * tan(θH/2) * tan(θV/2) # area of the field of view at distance
    Aaperture = pi * (lens_diameter^2) / 4
    atmospheric_absorbance = exp(-2 * distance * atmospheric_extinction_coefficient_per_km / 1e3)

    laser_energy = laser_power_W * pulse_width
    laser_photon_mean_wavelength = mean(rand(PRNGs[Threads.threadid()], laser_wavelength_distribution, 500))
    laser_photon_energy = wavelength_to_joules(laser_photon_mean_wavelength)
    photons_per_pulse = laser_energy / laser_photon_energy

    Preturn = photons_per_pulse * (1/(2*pi*distance^2)) * target_reflectivity * Aaperture * lens_transmittance * atmospheric_absorbance
    Pbackground = sum(solarspectrum.counts) * Afov * (1/(2*pi*distance^2)) * target_reflectivity * Aaperture * lens_transmittance

    time_of_flight = (2*distance) / Constants.c



    signal_return = FocusedSource(sim_environment,
        pulse_shape = :gaussian,
        photons_per_pulse = Preturn,
        pulse_width = pulse_width,
        delay = time_of_flight,
        frequency = laser_rep_rate,
        wavelength_distribution = laser_wavelength_distribution,
        distribution_x = Normal(beam_center.x, fwhm_to_stddev(beam_width)),
        distribution_y = Normal(beam_center.y, fwhm_to_stddev(beam_width)),
        info = "LIDAR return"
    )

    sun = FocusedSource(sim_environment,
        pulse_shape = :square,
        photons_per_pulse = Pbackground * (sim_environment.time_end - sim_environment.time_start + sim_environment.time_step),
        pulse_width = sim_environment.time_end - sim_environment.time_start  + sim_environment.time_step,
        delay = (sim_environment.time_end + sim_environment.time_start  + sim_environment.time_step) / 2,
        frequency = 1,
        wavelength_distribution = solarspectrum,
        distribution_x = Normal(beam_center.x, fwhm_to_stddev(beam_width)),
        distribution_y = Normal(beam_center.y, fwhm_to_stddev(beam_width)),
        info = "Sunlight"
    )
    signal_return - BPF
    sun - BPF
end
