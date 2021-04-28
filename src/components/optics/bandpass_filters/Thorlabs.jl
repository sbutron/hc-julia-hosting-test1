function FL905_10(sim_environment::Environment;
                position::Coordinate = Coordinate(0,0),
                optical_output::Union{Nothing, OpticalComponent} = nothing)
    data_source = Data.Thorlabs_FL905_10

    bpf = WavelengthFilter(sim_environment,
                    transmission_curve = interpolated_array(data_source["wavelength_vs_transmission"]; precision = 1),
                    info = "Thorlabs FL905-10 BPF Center Wavelength: 905nm CWL 10nm FWHM"
                    )
    aperture = Aperture(sim_environment,
                        shape = Circle(center = position, diameter = 21e-3),
                        info = "⌀21mm clear circular aperture",
                        optical_output = optical_output
                        )
    bpf - aperture
    return bpf
end

function FB1550_40(sim_environment::Environment;
                position::Coordinate = Coordinate(0,0),
                optical_output::Union{Nothing, OpticalComponent} = nothing)
    data_source = Data.Thorlabs_FB1550_40

    bpf = WavelengthFilter(sim_environment,
                    transmission_curve = interpolated_array(data_source["wavelength_vs_transmission"]; precision = 1),
                    info = "Thorlabs FL1550-40 BPF Center Wavelength: 1550nm CWL 8nm FWHM"
                    )
    aperture = Aperture(sim_environment,
                        shape = Circle(center = position, diameter = 25.4e-3),
                        info = "⌀25.4mm clear circular aperture",
                        optical_output = optical_output
                        )
    bpf - aperture
    return bpf
end
