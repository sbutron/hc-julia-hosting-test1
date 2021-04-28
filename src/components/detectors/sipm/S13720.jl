function S13720_1325CS(sim_environment::Environment;
                        position::Coordinate = Coordinate(0.0, 0.0),
                        ignore_error=false::Bool
                        )::SiPM
    data_source = Data.S13720_25um_Silicon

    SiPM(sim_environment;
    photon_detection_efficiency = 0.07,
    dark_count_rate = 500e3,
    crosstalk_probability = 0.06,
    afterpulse_probability = 0.38,
    relative_pde_vs_overvoltage = poly_fit(data_source["relative_pde"], 3),
    relative_crosstalk_vs_overvoltage = poly_fit(data_source["relative_crosstalk"], 3),
    relative_gain_vs_overvoltage = poly_fit(data_source["relative_gain"], 3),
    relative_dcr_vs_overvoltage = poly_fit(data_source["relative_dcr"], 3),
    pde_vs_wavelength = interpolated_array(data_source["pde_curve"]; precision = 1),
    number_of_microcells = 2668,
    rise_time_fast = 0.42e-9,
    Cd = 26.3e-15,
    Cq = 5.5e-15,
    Cg = 5e-12,
    Rq = 660e3,
    Rs = 50.0,
    pixel_pitch = 25e-6,
    breakdown_voltage = 57.0,
    min_overvoltage = 0.0,
    overvoltage = 7.0,
    max_overvoltage = 8.0,
    shape = :square,
    position = position,
    ignore_error = ignore_error,
    info = "S13720-1325CS"
    )
end
