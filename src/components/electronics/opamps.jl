function IdealOpAmp(sim_environment::Environment)::OpAmp
    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"
    opamp = ACME.add!(sim_environment.schematic.circuit, ACME.opamp())

    component = OpAmp(sim_environment::Environment,
    opamp::Symbol,
    ""::String,
    (opamp, "in+")::Tuple{Symbol,Any},
    (opamp, "in-")::Tuple{Symbol,Any},
    (opamp, "out+")::Tuple{Symbol,Any},
    (opamp, "out-")::Tuple{Symbol,Any},
    )
    return component
end

function OpAmp(sim_environment::Environment;
    max_gain::Float64,
    gain_bw_product::Float64,
    current_noise_density::Float64 = 1.0,
    current_noise_density_positive::Float64 = current_noise_density,
    current_noise_density_negative::Float64 = current_noise_density_positive,
    voltage_noise_density::Float64,
    input_impedance::Float64,
    input_capacitance::Float64,
    output_impedance::Float64,
    info::String)::OpAmp

    !(sim_environment.schematic.model_runner == nothing) && @error "cannot modify a compiled Environment, start a new instance of Environment"

    opamp = ACME.add!(sim_environment.schematic.circuit, ACME.opamp(;maxgain = max_gain, gain_bw_prod = gain_bw_product))
    # Noise definition is same as Matlab Finite Gain OpAmp https://www.mathworks.com/help/physmod/sps/ref/finitegainopamp.html
    noise_current_source1 = NoiseCurrentSource(sim_environment, Normal(0, current_noise_density_negative * sqrt(sample_interval_to_bandwidth(sim_environment.schematic.sample_interval))), "$info Current Noise")
    noise_current_source2 = NoiseCurrentSource(sim_environment, Normal(0, current_noise_density_positive * sqrt(sample_interval_to_bandwidth(sim_environment.schematic.sample_interval))), "$info Current Noise")
    noise_voltage_source = NoiseVoltageSource(sim_environment, Normal(0, voltage_noise_density * sqrt(sample_interval_to_bandwidth(sim_environment.schematic.sample_interval))), "$info Voltage Noise")
    r_in_diff = Resistor_Noisy(sim_environment, input_impedance, "$info Input Impedance Differential-Mode")
    c_in_diff = Capacitor(sim_environment, input_capacitance, "$info Input Capacitance Differential-Mode")
    r_out = Resistor_Noisy(sim_environment, output_impedance, "$info Input Impedance Differential-Mode")


    connect!(sim_environment,
        (opamp, "in-"),
        noise_current_source1.pin_positive,
        r_in_diff.pin_1,
        c_in_diff.pin_1)

    connect!(sim_environment,
        (opamp, "in+"),
        noise_voltage_source.pin_positive,
        noise_current_source2.pin_positive,
        r_in_diff.pin_2,
        c_in_diff.pin_2)
    connect!(sim_environment,
        noise_voltage_source.pin_negative,
        noise_current_source1.pin_negative,
        noise_current_source2.pin_negative,
        :gnd)
    connect!(sim_environment,
        r_out.pin_1,
        (opamp, "out+")
        )

    component = OpAmp(sim_environment::Environment,
    opamp::Symbol,
    info::String,
    (opamp, "in+")::Tuple{Symbol,Any},
    (opamp, "in-")::Tuple{Symbol,Any},
    r_out.pin_2::Tuple{Symbol,Any},
    (opamp, "out-")::Tuple{Symbol,Any},
    )
    return component
end

function AD8001(sim_environment::Environment)::OpAmp
    return OpAmp(sim_environment;
        max_gain = 177827.941004, # 105db
        gain_bw_product = 880e6, # 880MHz
        current_noise_density_positive = 2e-12,
        current_noise_density_negative = 18e-12,
        voltage_noise_density = 2e-9,
        input_impedance = 10e6,
        input_capacitance= 1.5e-12,
        output_impedance = 100,
        info = "AD8027"
        )
end

function AD8027(sim_environment::Environment)::OpAmp
    return OpAmp(sim_environment;
        max_gain = 100, # 40db
        gain_bw_product = 190e6, #
        current_noise_density = 1.6e-12,
        voltage_noise_density = 4.3e-9,
        input_impedance = 6e6,
        input_capacitance = 2e-12,
        output_impedance = 0.5,
        info = "AD8027"
        )
end

function OPA846(sim_environment::Environment)::OpAmp
    return OpAmp(sim_environment;
        max_gain = 31622.7766, # 90db
        gain_bw_product = 1750e6, #
        current_noise_density = 2.8e-12,
        voltage_noise_density = 1.2e-9,
        input_impedance = 6.6e3,
        input_capacitance = 2e-12,
        output_impedance = 0.002,
        info = "OPA846"
        )
end

function OPA847(sim_environment::Environment)::OpAmp
    return OpAmp(sim_environment;
        max_gain = 79432.82, # 98 db
        gain_bw_product = 3.9e9, # 3.9GHz
        current_noise_density = 2.5e-12,
        voltage_noise_density = 0.85e-9,
        input_impedance = 2.7e3,
        input_capacitance = 2e-12,
        output_impedance = 0.003,
        info = "OPA847"
        )
end

function OPA858(sim_environment::Environment)::OpAmp
    return OpAmp(sim_environment;
        max_gain = 10000.0, # 80 db
        gain_bw_product = 5500e6, # 3.9GHz
        current_noise_density = 10e-12,
        voltage_noise_density = 2.5e-9,
        input_impedance = 1e9,
        input_capacitance = 0.2e-12,
        output_impedance = 0.15,
        info = "https://www.ti.com/lit/gpn/opa858"
        )
end

function LMH6714(sim_environment::Environment)::OpAmp
    return OpAmp(sim_environment;
        max_gain = 1000000.0, #120db
        gain_bw_product = 400e6, # 400MHz* 50db
        current_noise_density_positive = 10e-12,
        current_noise_density_negative = 1.2e-12,
        voltage_noise_density = 3.4e-9,
        input_impedance = 2e6,
        input_capacitance = 1e-12,
        output_impedance = 0.06,
        info = "LMH6714"
        )
end


function THS3001(sim_environment::Environment)::OpAmp
    return OpAmp(sim_environment;
        max_gain = 5623413.25, # 135db
        gain_bw_product = 420e6, # 420MHz 0db
        current_noise_density_positive = 13e-12,
        current_noise_density_negative = 16e-12,
        voltage_noise_density = 1.6e-9,
        input_impedance = 1.5e6,
        input_capacitance = 7.5e-12,
        output_impedance = 10.0,
        info = "THS3001"
        )
end

function THS3091(sim_environment::Environment)::OpAmp
    return OpAmp(sim_environment,
    max_gain = 70794.578, # 97db
    gain_bw_product = 235e6,
    current_noise_density_positive = 14e-12,
    current_noise_density_negative = 17e-12,
    voltage_noise_density = 2e-9,
    input_impedance = 1.3e6,
    input_capacitance = 1.4e-12,
    output_impedance = 0.09,
    info = "THS3091"
    )
end
