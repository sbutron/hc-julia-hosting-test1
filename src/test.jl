

function test_all()
    println("\n Running test procedure...")
    binomial_prng_test()
    distribute_beam_test()
    make_circle_lattice_test(2876)
    make_square_lattice_test(2668)
    make_square_test(10)
    make_pulse_gaussian_test()
    make_pulse_train_gaussian_test()
    make_pulse_train_square_test()
    check_collision_test(2000,100)
    make_sensor_array_test(100,50e-6)
    return nothing
end #function test_all

function check_collision_test(sensor_size, photon_count)
    circle_mppc = make_circle_lattice(sensor_size)
    sensor_matrix = make_sensor_matrix(circle_mppc,50e-6)
    photons = map(x-> distribute_beam(0e-3,0e-3,1e-3,1e-3),1:photon_count)
    #collision_alert = ""
    collision_count = 0
    plot_output = plot(
        title = "check_collision",
        xlims = (-10e-3,10e-3),
        ylims = (-10e-3,10e-3)
        )
    println("\n Testing check_collision with $sensor_size pixels and $photon_count photons...")
    @time for photon in photons
            for pixel in sensor_matrix
                collision_found = check_collision(pixel,photon)
                if collision_found
                    collision_count += 1
                    #collision_alert = collision_alert * "\n A collision occured between photon at $photon and pixel at $pixel"
                    @goto end_pixel_scan
                end
            end
            @label end_pixel_scan
        end
    println("$collision_count collisions detected")
    return nothing
end
##
function binomial_prng_test()
    a = Integer[]
    println("\n Testing prng_binomial 10000x...")
    @time for i = 1:1e4
        push!(a,prng_binomial(20,0.5))
    end
    b = Integer[]
    println("\n Testing prng_binomial 10000x...")
    @time for i = 1:1e4
        push!(b,prng_binomial(20,0.7))
    end
    c = Integer[]
    println("\n Testing prng_binomial 10000x...")
    @time for i = 1:1e4
        push!(c,prng_binomial(40,0.5))
    end
    plot_output = histogram(a, label = "p=0.5,n=40", normalize = false,
        title = "prng_binomial",
        size = (1000,1000),
        xlabel = "Bin",
        xlims = (0,40),
        xticks = 0:10:40,
        xflip = false,
        ylabel = "Counts",
        #ylims = (0,Inf),
        #yticks = 0:1:Inf,
        yflip = false
        )

    plot_output = histogram!(b, label = "p=0.7,n=20", normalize = false)
    plot_output = histogram!(c, label = "p=0.5,n=40", normalize = false)
    display(plot_output)
    return nothing
end #end binomial

function distribute_beam_test()
    x = []
    y = []
    for i = 1:1e4
        x_pos, y_pos = distribute_beam(0e-3,0e-3,3e-3,3e-3)
        push!(x,x_pos)
        push!(y,y_pos)
    end
    plot_output = scatter(x, y, label = "x = 0+/- σ 3e-3 , y = 0+/- σ 3e-3",
        title = "distribute_beam",
        size = (1000,1000),
        xlabel = "x-pos",
        xlims = (-15e-3,15e-3),
        ylabel = "y-pos",
        ylims = (-15e-3,15e-3)
        )
    display(plot_output)
    return nothing
end

function make_circle_lattice_test(number_of_pixels)
    println("\n Testing make_circle_lattice($number_of_pixels)...")
    @time lattice = make_circle_lattice(number_of_pixels)
    plot_output = scatter(get_column(lattice,1),get_column(lattice,2), label = "$number_of_pixels pixels",
        title = "make_circle_lattice",
        size = (1000,1000),
        xlabel = "x-pos",
        ylabel = "y-pos"
        )
    display(plot_output)
    return lattice
end

function make_square_lattice_test(number_of_pixels)
    println("\n Testing make_square_lattice($number_of_pixels)...")
    @time lattice = make_square_lattice(number_of_pixels)
    plot_output = scatter(get_column(lattice,1),get_column(lattice,2), label = "$number_of_pixels pixels",
    time = "make_square_lattice",
    size = (1000,1000),
    xlabel = "x-pos",
    ylabel = "y-pos"
    )
    display(plot_output)
    return lattice
end

function make_sensor_array_test(number_of_pixels,pixel_pitch)
    circle_mppc = make_circle_lattice(number_of_pixels)
    println("\n Testing make_sensor_matrix...")
    @time sensor_matrix = make_sensor_matrix(circle_mppc,pixel_pitch)
    plot_output = plot(
        title = "make_sensor_array",
        legend = false,
        size = (1000,1000),
        xlabel = "x-pos",
        ylabel = "y-pos"
        )
    for i = 1:number_of_pixels
        plot_output = plot!(to_shape(sensor_matrix[i]), fillcolor = "green", legend=false)
    end
    display(plot_output)
    return sensor_matrix
end

function make_square_test(number_of_squares)
    plot_output = plot()
    println("\n Testing make_square $number_of_squares x...")
    @time for i = 1:number_of_squares
        center_x = rand(PRNG)
        center_y = rand(PRNG)
        length = rand(PRNG)
        square = make_square(center_x,center_y,length)
        plot_output = plot!(to_shape(square))
    end
    display(plot_output)
    return nothing
end

function make_pulse_gaussian_test()
    println("\n Testing make_pulse_gaussian...")
    @time time_pulse = make_pulse_gaussian(0,2e-9,-10e-9,10e-9,10e-12)
    photons = get_column(time_pulse,2)*1e6
    total_photons = round(sum(photons))
    plot_output = plot(get_column(time_pulse,1),photons, label="Total photons = $total_photons",
        title = "make_pulse_gaussian",
        size = (1000,1000),
        xlabel = "Time (s)",
        ylabel = "Photons")
    display(plot_output)
    return time_pulse
end

function make_pulse_train_gaussian_test()

    first_pulse_center = 0.0
    fwhm = 100e-9
    frequency = 1e6
    photons_per_pulse = 2000
    starting_time = -200e-9
    ending_time = 3e-6
    step_time = 100e-12
    println("\n Testing make_pulse_train_gaussian...")
    @time pulse_train = make_pulse_train_gaussian(first_pulse_center,fwhm,frequency,photons_per_pulse,starting_time,ending_time,step_time)
    x = get_column(pulse_train,1)
    y = get_column(pulse_train,2)
    total_photons = round(sum(y))
    plot_output = plot(x, y, label="Total photons = $total_photons",
        title = "make_pulse_train_gaussian",
        size = (1000,1000),
        xlabel = "Time (s)",
        ylabel = "Photons")
    display(plot_output)
    return pulse_train
end

function make_pulse_train_square_test()
    first_pulse_center = 0.0
    fwhm = 100e-9
    frequency = 1e6
    photons_per_pulse = 2000
    starting_time = -200e-9
    ending_time = 3e-6
    step_time = 100e-12
    println("\n Testing make_pulse_train_square...")
    @time pulse_train = make_pulse_train_square(first_pulse_center,fwhm,frequency,photons_per_pulse,starting_time,ending_time,step_time)
    x = get_column(pulse_train,1)
    y = get_column(pulse_train,2)
    total_photons = round(sum(y))
    plot_output = plot(x, y, label="Total photons = $total_photons",
        title = "make_pulse_train_gaussian",
        size = (1000,1000),
        xlabel = "Time (s)",
        ylabel = "Photons")
    display(plot_output)
    return pulse_train
end
