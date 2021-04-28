##
"""
    temporal_pulse_generic(distribution_profile::Distribution,start_time,end_time,step_time)
    Returns a 2xN matrix with time, pulse profile, distribution_profile accepts any Distribution type of
    from Distributions.jl
"""
function make_pulse_generic(distribution_profile::Distribution,start_time,end_time,step_time)
    indexes::Integer = round((end_time - start_time) / step_time)
    # pulse_profile = zeros(Float64,indexes,2)
    pulse_profile = zeros(Float64, indexes)
    Threads.@threads for i = 1:indexes
        time_now = (step_time * i ) + start_time
        # pulse_profile[i,1] = time_now
        # pulse_profile[i,2] = pdf.(distribution_object,time_now) * step_time
        pulse_profile[i] = pdf.(distribution_object,time_now) * step_time
    end
    return pulse_profile
end #function gaussian_pulse
##
"""
    gaussian_pulse(center_time,std_dev_time,start_time,end_time,step_time)

    Returns a normalized pulse in matrix format [time,probability]
    from start_time to end_time of the temporal pulse profile.
    The sum of probabilities provided the entire pulse is enclosed between start_time and end_time is
    ~1.  Multiplying the 2nd column by the number of photons per pulse will yield a temporal profile of
    photons per time yield ie gaussian_pulse(...) * total signal photons

    #Examples

    julia> time_pulse = gaussian_pulse(0,2e-9,-10e-9,10e-9,10e-12)
    2000×2 Array{Float64,2}:
     -9.99e-9  7.62168e-9
     -9.98e-9  7.81434e-9
     -9.97e-9  8.01166e-9
     -9.96e-9  8.21375e-9
     -9.95e-9  8.42074e-9
     -9.94e-9  8.63272e-9
     -9.93e-9  8.84982e-9
     -9.92e-9  9.07216e-9
     -9.91e-9  9.29984e-9
     -9.9e-9   9.533e-9
     -9.89e-9  9.77177e-9
     -9.88e-9  1.00163e-8
     -9.87e-9  1.02666e-8
     -9.86e-9  1.0523e-8
      ⋮
      9.87e-9  1.02666e-8
      9.88e-9  1.00163e-8
      9.89e-9  9.77177e-9
      9.9e-9   9.533e-9
      9.91e-9  9.29984e-9
      9.92e-9  9.07216e-9
      9.93e-9  8.84982e-9
      9.94e-9  8.63272e-9
      9.95e-9  8.42074e-9
      9.96e-9  8.21375e-9
      9.97e-9  8.01166e-9
      9.98e-9  7.81434e-9
      9.99e-9  7.62168e-9
      1.0e-8   7.4336e-9

    julia> photons = get_column(time_pulse,2)*1e6
    2000-element Array{Float64,1}:
     0.00762168472052463
     0.00781433554474645
     0.008011655646754021
     0.008213752940225383
     0.00842073769958439
     0.008632722608385365
     0.008849822808612547
     0.00907215595091015
     0.009299842245758761
     0.009533004515614053
     0.009771768248024266
     0.010016261649742498
     0.010266615701851287
     0.010522964215915646
     ⋮
     0.010266615701851323
     0.010016261649742498
     0.009771768248024301
     0.009533004515614087
     0.009299842245758845
     0.009072155950910201
     0.008849822808612623
     0.008632722608385397
     0.00842073769958439
     0.008213752940225428
     0.00801165564675405
     0.00781433554474652
     0.0076216847205246565
     0.007433597573671487

    julia> sum(photons)
    999999.426665883
"""
function make_pulse_gaussian(center_time,fwhm,start_time,end_time,step_time)
    std_dev = fwhm_to_stddev(fwhm) #conversion from fwhm to std_dev
    indexes = time_span_to_steps(start_time, end_time, step_time)
    # pulse_profile = zeros(Float64, indexes, 2)
    pulse_profile = zeros(Float64, indexes)
    distribution_object = Normal(center_time,std_dev)
    Threads.@threads for i = 1:indexes
        time_now = (step_time * (i-1) ) + start_time
        # pulse_profile[i,1] = time_now
        # pulse_profile[i,2] = pdf.(distribution_object,time_now) * step_time
        pulse_profile[i] = pdf.(distribution_object,time_now) * step_time
    end
    return pulse_profile
end #function gaussian_pulse

##
function make_pulse_square(center_time, width_time, start_time, end_time, step_time)
    indexes = time_span_to_steps(start_time, end_time, step_time)
    # pulse_profile = zeros(Float64 ,indexes, 2)
    pulse_profile = zeros(Float64, indexes)
    distribution_object = Uniform(center_time - (width_time / 2),center_time + (width_time / 2))
    Threads.@threads for i = 1:indexes
        time_now = (step_time * (i-1) ) + start_time
        # pulse_profile[i,1] = time_now
        # pulse_profile[i,2] = pdf.(distribution_object,time_now) * step_time
        pulse_profile[i] = pdf.(distribution_object,time_now) * step_time
    end
    return pulse_profile
end #function gaussian_pulse

##
"""
    make_pulse_train_gaussian
"""
function make_pulse_train_gaussian(first_pulse_center_time, pulse_fwhm, frequency, photons_per_pulse, start_time, end_time, step_time)
    indexes = time_span_to_steps(start_time, end_time, step_time)
    #pulse_train_profile = zeros(Float64, indexes, 2)
    pulse_train_profile = zeros(Float64, indexes)
    pulse_center = first_pulse_center_time
    while (pulse_center-pulse_fwhm*6) < end_time
            single_pulse = make_pulse_gaussian(pulse_center, pulse_fwhm, start_time, end_time, step_time)
            # pulse_train_profile[:,1] = get_column(single_pulse,1)
            # pulse_train_profile[:,2] += get_column(single_pulse,2) * photons_per_pulse
            pulse_train_profile = pulse_train_profile + single_pulse * photons_per_pulse
            pulse_center += (1/frequency)
    end
    return pulse_train_profile
end

##
"""
    make_pulse_train_square
"""
function make_pulse_train_square(first_pulse_center_time, pulse_fwhm, frequency, photons_per_pulse, start_time, end_time, step_time)
    indexes = time_span_to_steps(start_time, end_time, step_time)
    #pulse_train_profile = zeros(Float64, indexes, 2)
    pulse_train_profile = zeros(Float64, indexes)
    pulse_center = first_pulse_center_time
    while (pulse_center-pulse_fwhm*6) < end_time
        single_pulse = make_pulse_square(pulse_center, pulse_fwhm, start_time, end_time, step_time)
        pulse_train_profile = pulse_train_profile + single_pulse * photons_per_pulse
        pulse_center += (1/frequency)
    end
    return pulse_train_profile
end
"""
    returns the amount of decay a signal with initial_value experiences over time_step if it has a decay time_constant
"""
function decay_value(initial_value::Float64, time_step::Float64, time_constant::Float64)::Float64
     return initial_value * ( 1 - exp( -time_step/ time_constant) )
end
