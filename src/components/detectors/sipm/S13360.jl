function S13360_3050CS(sim_environment::Environment;
                        position::Coordinate = Coordinate(0.0, 0.0),
                        ignore_error=false::Bool
                        )::SiPM
    data_source = Data.S13360_50um_Silicon

    SiPM(sim_environment;
        photon_detection_efficiency = 0.40,
        dark_count_rate = 500e3,
        crosstalk_probability = 0.03,
        afterpulse_probability = 0.002,
        relative_pde_vs_overvoltage = poly_fit(data_source["relative_pde"], 3),
        relative_crosstalk_vs_overvoltage = poly_fit(data_source["relative_crosstalk"], 3),
        relative_gain_vs_overvoltage = poly_fit(data_source["relative_gain"], 3),
        relative_dcr_vs_overvoltage = poly_fit(data_source["relative_dcr"], 3),
        pde_vs_wavelength = interpolated_array(data_source["pde_curve"]; precision = 1),
        number_of_microcells = 3600,
        rise_time_fast = 0.8e-9,
        Cd = 84.5e-15,
        Cq = 16.8e-15,
        Cg = 18.7e-12,
        Rq = 300e3,
        Rs = 50.0,
        pixel_pitch = 50e-6,
        breakdown_voltage = 53.0,
        min_overvoltage = 0.0,
        overvoltage = 3.0,
        max_overvoltage = 10.0,
        shape = :square,
        position = position,
        ignore_error = ignore_error,
        info = "S13360-3050CS"
        )
end
