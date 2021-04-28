function S14645_02(sim_environment::Environment;
            position::Coordinate
            )
    data_source = Data.S14645_Series
    APD(sim_environment,
            active_area_shape = Circle(center = position, diameter = 0.2e-3),
            gain = 100.0,
            excess_noise_figure = 0.3,
            dark_current = 40e-12,
            terminal_capacitance = 0.5e-12,
            afterpulse_probability = 0.0,
            qe_vs_wavelength = interpolated_array(data_source["qe_vs_wavelength"]; precision = 1),
            rise_time_fast = 0.5667e-9,
            rise_time_slow = 0.5667e-9,
            fall_time_fast = 0.5667e-9,
            fall_time_slow = 0.5667e-9,
            fast_pulse_ratio = 1.0,
            min_bias_voltage = 60.0,
            bias_voltage = 150.0,
            max_bias_voltage = 175.0,
            info = "S14656-02"
            )
end
