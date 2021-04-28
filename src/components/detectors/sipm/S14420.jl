function S14420_3050MG(sim_environment::Environment;
                        position::Coordinate = Coordinate(0.0, 0.0),
                        ignore_error=false::Bool
                        )::SiPM
    data_source = Data.S14420_50um_Borosilicate_Glass

    SiPM(sim_environment;
    photon_detection_efficiency = 0.40,
    dark_count_rate = 1600e3,
    crosstalk_probability = 0.05,
    afterpulse_probability = 0.002,
    relative_pde_vs_overvoltage = poly_fit(data_source["relative_pde"], 3),
    relative_crosstalk_vs_overvoltage = poly_fit(data_source["relative_crosstalk"], 3),
    relative_gain_vs_overvoltage = poly_fit(data_source["relative_gain"], 3),
    relative_dcr_vs_overvoltage = poly_fit(data_source["relative_dcr"], 3),
    pde_vs_wavelength = interpolated_array(data_source["pde_curve"]; precision = 1),
    number_of_microcells = 2836,
    rise_time_fast = 2e-9,
    Cd = 115e-15,
    Cq = 11.3e-15,
    Cg = 28e-12,
    Rq = 430e3,
    Rs = 50.0,
    pixel_pitch = 50e-6,
    breakdown_voltage = 42.0,
    min_overvoltage = 0.0,
    overvoltage = 5.0,
    max_overvoltage = 7.0,
    shape = "Circle",
    position = position,
    ignore_error = ignore_error,
    info = "S14420-3050MG"
    )
end
