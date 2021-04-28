function BandpassFilter_f0_1Mhz_Δ450kHz(sim_environment::Environment; center_frequency::Float64, bandwidth::Float64)::SubCircuitAB
    opa = AD8027(sim_environment)
    r1 = Resistor_Noisy(sim_environment, 316.0, "R1")
    r2 = Resistor_Noisy(sim_environment, 105.0, "R2")
    r3 = Resistor_Noisy(sim_environment, 634.0, "R3")
    r4 = Resistor_Noisy(sim_environment, 532.0, "R4")
    r5 = Resistor_Noisy(sim_environment, 532.0, "R5")
    c1 = Capacitor(sim_environment, 1000e-12, "C1")
    c2 = Capacitor(sim_environment, 500e-12, "C2")

    connect!(sim_environment, r1.pin_2, r2.pin_1, c1.pin_1)
    connect!(sim_environment, c1.pin_2, c2.pin_1, r3.pin_1, opa.pin_in_pos)
    connect!(sim_environment, r2.pin_2, r4.pin_1)
    connect!(sim_environment, r4.pin_2, r5.pin_1, opa.pin_in_neg)
    connect!(sim_environment, c2.pin_2, r3.pin_2, r5.pin_2, opa.pin_out_neg, :gnd)
    #!!! Op amp negative output pins need to be grounded !!!
    SubCircuitAB(sim_environment;
        info = "Active Bandpass Filter using AD8027",
        components = [opa, r1, r2, r3, r4, r5, c1, c2],
        pin_input = r1.pin_1,
        pin_output = r2.pin_2,
        )
end
