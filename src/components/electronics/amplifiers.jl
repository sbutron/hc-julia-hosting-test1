function Amplifier_TIA(sim_environment::Environment, opamp::OpAmp, feedback_resistance::Float64)
    rf = Resistor_Noisy(sim_environment, feedback_resistance, "Rf")
    connect!(sim_environment, opamp.pin_in_neg, rf.pin_1)
    connect!(sim_environment, opamp.pin_in_pos, opamp.pin_out_neg, :gnd)
    connect!(sim_environment, rf.pin_2, opamp.pin_out_pos)

    SubCircuitAB(sim_environment;
    info = "Transimpedance Amplifier",
    components = [opamp, rf, cf],
    pin_input = opamp.pin_in_neg,
    pin_output = rf.pin_2,
    )
end

function Comparator(sim_environment::Environment, v_low::Float64, v_high::Float64, v_cc::Float64)
    rxΩ = 100e3
    rhΩ = rxΩ * v_low / (v_high - v_low)
    ryΩ = rxΩ * v_low / (v_cc - v_high)
    vcc = VoltageSource(sim_environment, v_cc, "Vcc")
    u2 = IdealOpAmp(sim_environment, "U2")
    rh = Resistor_Ideal(sim_environment, rhΩ, "Rh")
    ry = Resistor_Ideal(sim_environment, ryΩ, "Ry")
    rx = Resistor_Ideal(sim_environment, rxΩ, "Rx")
    connect!(sim_environment, u2.pin_out_pos, rh.pin_1)
    connect!(sim_environment, rh.pin_2, ry.pin_1, rx.pin_1, u2.pin_in_pos)
    connect!(sim_environment, ry.pin_2, u2.pin_out_neg, vcc.pin_negative, :gnd)
    connect!(sim_environment, rx.pin_2, vcc.pin_positive)

    SubCircuitAB(sim_environment;
    info = "Comparator",
    components = [u2, vcc, rh, ry, rx],
    pin_input = u2.pin_in_neg,
    pin_output = u2.pin_out_pos,
    )
end

function Amplifier_Voltage_C14191_50Ω(sim_environment::Environment; PZC::Bool = false)

end

function Amplifier_Voltage_C12332_01_1kΩ(sim_environment::Environment)
    u1 = OPA846(sim_environment)
    r2 = Resistor_Noisy(sim_environment, 1e3, "R2")
    r1 = Resistor_Noisy(sim_environment, 51.0, "R1")
    r11 = Resistor_Noisy(sim_environment, 1e3, "R11")
    r5 = Resistor_Noisy(sim_environment, 51.0, "R5")
    connect!(sim_environment, u1.pin_in_pos, r11.pin_1)
    connect!(sim_environment, u1.pin_out_pos, r5.pin_1, r2.pin_1)
    connect!(sim_environment, u1.pin_in_neg, r2.pin_2, r1.pin_1)
    connect!(sim_environment, r11.pin_2, r1.pin_2, u1.pin_out_neg, :gnd)

    SubCircuitAB(sim_environment;
    info = "C12332-01 Voltage Amplifier",
    components = [u1, r1, r2, r11, r5],
    pin_input = u1.pin_in_pos,
    pin_output = r5.pin_2,
    )
end

function Amplifier_Voltage_C12332_01_50Ω(sim_environment::Environment)
    u1 = OPA846(sim_environment)
    r2 = Resistor_Noisy(sim_environment, 1e3, "R2")
    r1 = Resistor_Noisy(sim_environment, 51.0, "R1")
    r11 = Resistor_Noisy(sim_environment, 50.0, "R11")
    r5 = Resistor_Noisy(sim_environment, 51.0, "R5")
    connect!(sim_environment, u1.pin_in_pos, r11.pin_1)
    connect!(sim_environment, u1.pin_out_pos, r5.pin_1, r2.pin_1)
    connect!(sim_environment, u1.pin_in_neg, r2.pin_2, r1.pin_1)
    connect!(sim_environment, r11.pin_2, r1.pin_2, u1.pin_out_neg, :gnd)

    SubCircuitAB(sim_environment;
    info = "C12332-01 Voltage Amplifier",
    components = [u1, r1, r2, r11, r5],
    pin_input = u1.pin_in_pos,
    pin_output = r5.pin_2
    )
end

function Amplifier_TIA_OPA846_Example_20kΩ_20MHz(sim_environment::Environment)
    u1 = OPA846(sim_environment)
    r1 = Resistor_Noisy(sim_environment, 50e3, "")
    rf = Resistor_Noisy(sim_environment, 50e3, "")
    cf = Capacitor(sim_environment, 0.2e-12, "")
    c1 = Capacitor(sim_environment, 0.1e-6, "")
    c2 = Capacitor(sim_environment, 100e-12, "")
    connect!(sim_environment, rf.pin_1, u1.pin_in_neg, cf.pin_1)
    connect!(sim_environment, rf.pin_2, cf.pin_2, u1.pin_out_pos)
    connect!(sim_environment, r1.pin_1, u1.pin_in_pos, c1.pin_1, c2.pin_1)
    connect!(sim_environment, :gnd, u1.pin_out_neg, r1.pin_2, c1.pin_2, c2.pin_2)

    SubCircuitAB(sim_environment;
    info = "OPA846 20kΩ 20MHz Example TIA",
    components = [u1, r1, rf, cf, c1, c2],
    pin_input = u1.pin_in_neg,
    pin_output = u1.pin_out_pos
    )
end

function Amplifier_Voltage_OPA858_Wideband_Example(sim_environment::Environment;
                                                    gain_shaping::Bool = false)
    u1 = OPA858(sim_environment)

    r1 = Resistor_Noisy(sim_environment, 62.0, "")
    r2 = Resistor_Noisy(sim_environment, 226.0, "")
    r3 = Resistor_Noisy(sim_environment, 453.0, "")
    r4 = Resistor_Noisy(sim_environment, 169.0, "")
    r5 = Resistor_Noisy(sim_environment, 71.5, "")

    connect!(sim_environment, r1.pin_1, r2.pin_1)
    connect!(sim_environment, r2.pin_2, u1.pin_in_neg, r3.pin_1)
    connect!(sim_environment, r3.pin_2, u1.pin_out_pos, r4.pin_1)
    connect!(sim_environment, r4.pin_2, r5.pin_1)
    connect!(sim_environment, :gnd, r1.pin_2, r5.pin_2, u1.pin_in_pos, u1.pin_out_neg)
    components = [u1, r1, r2, r3, r4, r5]

    if gain_shaping
        c1 = Capacitor(sim_environment, 2.7e-12, "")
        c2 = Capacitor(sim_environment, 0.5e-12, "")
        connect!(sim_environment, u1.pin_in_neg, c1.pin_1, c2.pin_1)
        connect!(sim_environment, u1.pin_out_pos, c2.pin_2)
        connect!(sim_environment, :gnd, c1.pin_2)
        push!(components, c1)
        push!(components, c2)
    end

    SubCircuitAB(sim_environment;
    info = "https://www.ti.com/lit/ds/symlink/opa858.pdf?ts=1618941181957&ref_url=https%253A%252F%252Fwww.google.com%252F\nFigure 60.\nNotes: Use 50 ohm output termination.",
    components = components,
    pin_input = r1.pin_1,
    pin_output = r5.pin_1
    )
end

function Amplifier_TIA_C13365(sim_environment::Environment)
    u2 = LMH6714(sim_environment)
    u3 = THS3001(sim_environment)
    r9 = Resistor_Noisy(sim_environment, 10, "R9")
    r1 = Resistor_Noisy(sim_environment, 1.33e3, "R1")
    r10 = Resistor_Noisy(sim_environment, 270.0, "R10")
    r8 = Resistor_Noisy(sim_environment, 750, "R8")
    c7 = Capacitor(sim_environment, 5e-12, "C7")
    r11 = Resistor_Noisy(sim_environment, 51.0, "R11")
    r12 = Resistor_Noisy(sim_environment, 180.0, "R12")
    r19 = Resistor_Noisy(sim_environment, 100.0, "R19")
    c14 = Capacitor(sim_environment, 0.1e-6, "C14")
    r24 = Resistor_Noisy(sim_environment, 10e3, "R24")
    r27 = Resistor_Noisy(sim_environment, 10e3, "R26")
    r26 = Resistor_Noisy(sim_environment, 10e3, "R26")
    c26 = Capacitor(sim_environment, 1e-6, "C26")
    connect!(sim_environment, r9.pin_2, u2.pin_in_neg, r1.pin_1)
    connect!(sim_environment, r1.pin_2, u2.pin_out_pos, r10.pin_1)
    connect!(sim_environment, r10.pin_2, u3.pin_in_neg, r8.pin_1, c7.pin_1)
    connect!(sim_environment, r8.pin_2, c7.pin_2, u3.pin_out_pos, r11.pin_1)
    connect!(sim_environment, u3.pin_in_pos, r12.pin_1)
    connect!(sim_environment, r12.pin_2, r19.pin_1, r24.pin_1)
    connect!(sim_environment, r24.pin_2, r27.pin_1, c26.pin_1)
    connect!(sim_environment, r26.pin_1, r27.pin_2, c26.pin_2)
    #!!! Op amp negative output pins need to be grounded !!!
    connect!(sim_environment, r19.pin_2, u2.pin_in_pos, u2.pin_out_neg, u3.pin_out_neg, r26.pin_2, :gnd)
    SubCircuitAB(sim_environment;
        info = "Transimpedance Amplifier",
        components = [u2, u3, r9, r1, r10, r8, c7, r11, r12, r19, c14],
        pin_input = r9.pin_1,
        pin_output = r11.pin_2
        )
end
