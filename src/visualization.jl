
## converts an SMatrix[x1 x2 ; y1 y2] to Shape([x1,x2,..xn],[y1,y2,...yn]) for
# This is hack since Plots.jl plays well with type Shape to form filled polys of n sides
function plottable(shape_matrix::SMatrix)
    shape_output = Shape(shape_matrix[1,:],shape_matrix[2,:])
    return shape_output
end
"""
    plotable(plane_space::PlaneSpace)
    Returns a plottable tuple
"""
function plottable2d(sim_environment::Environment)
    data = transpose(sim_environment.photons)
    x = data[:,1]
    y = data[:,2]
    return x, y
end
function plottable3d(plane_space::PlaneSpace)
    x, y, z = findnz(plane_space.space)
    x = (-).(x, plane_space.center_x)
    y = (-).(y, plane_space.center_y)
    x *= plane_space.dim_precision
    y *= plane_space.dim_precision
    return x, y, z
end
function plottable2d(plane_space::PlaneSpace)
    x, y, z = findnz(plane_space.space)
    x = (-).(x, plane_space.center_x)
    y = (-).(y, plane_space.center_y)
    x *= plane_space.dim_precision
    y *= plane_space.dim_precision
    return x, y
end
function plottable2d(photon::Photon)
    x = photon.x
    y = photon.y
    return x, y
end
function plottable2d(photons::Vector{Photon})
    x = []
    y = []
    for photon in photons
        push!(x, photon.x)
        push!(y, photon.y)
    end
    return x, y
end
function plottable(poly::Polynomial{Float64}, min::Float64, max::Float64, step_size::Float64)
    x_s = Vector{Float64}(undef,0)
    y_s = Vector{Float64}(undef,0)
    for x = min:step_size:max
        push!(x_s, x)
        push!(y_s, poly(x))
    end
    return x_s, y_s
end

function inspect(sipm::SiPM, step_index::Integer)
    half_pitch = sipm.pixel_pitch / 2.0
    surface_x = []
    surface_y = []
    photon_x = []
    photon_y = []
    crosstalk_x = []
    crosstalk_y = []
    afterpulse_x = []
    afterpulse_y = []
    darkcount_x = []
    darkcount_y = []
    for px = 1:sipm.number_of_microcells
        center_x = sipm.pixels_x[px]
        center_y = sipm.pixels_y[px]
        half_pitch = sipm.pixel_pitch / 2
        if sipm.pxt_all_pe[px, step_index] < 1
            surface_x = vcat(surface_x, [center_x - half_pitch, center_x + half_pitch, center_x + half_pitch, center_x - half_pitch, NaN])
            surface_y = vcat(surface_y, [center_y - half_pitch, center_y - half_pitch, center_y + half_pitch, center_y + half_pitch, NaN])
        elseif sipm.pxt_photon_pe[px, step_index] > 0
            photon_x = vcat(photon_x, [center_x - half_pitch, center_x + half_pitch, center_x + half_pitch, center_x - half_pitch, NaN])
            photon_y = vcat(photon_y, [center_y - half_pitch, center_y - half_pitch, center_y + half_pitch, center_y + half_pitch, NaN])
        elseif sipm.pxt_crosstalk_pe[px, step_index] > 0
            crosstalk_x = vcat(crosstalk_x, [center_x - half_pitch, center_x + half_pitch, center_x + half_pitch, center_x - half_pitch, NaN])
            crosstalk_y = vcat(crosstalk_y, [center_y - half_pitch, center_y - half_pitch, center_y + half_pitch, center_y + half_pitch, NaN])
        elseif sipm.pxt_dark_pe[px, step_index] > 0
            darkcount_x = vcat(darkcount_x, [center_x - half_pitch, center_x + half_pitch, center_x + half_pitch, center_x - half_pitch, NaN])
            darkcount_y = vcat(darkcount_y, [center_y - half_pitch, center_y - half_pitch, center_y + half_pitch, center_y + half_pitch, NaN])
        else sipm.pxt_afterpulse_pe[px, step_index] > 0
            afterpulse_x = vcat(afterpulse_x, [center_x - half_pitch, center_x + half_pitch, center_x + half_pitch, center_x - half_pitch, NaN])
            afterpulse_y = vcat(afterpulse_y, [center_y - half_pitch, center_y - half_pitch, center_y + half_pitch, center_y + half_pitch, NaN])
        end
    end
    sipm_surface = Shape(surface_x, surface_y)
    sipm_photon_pe = Shape(photon_x, photon_y)
    sipm_crosstalk_pe = Shape(crosstalk_x, crosstalk_y)
    sipm_darkcount_pe = Shape(darkcount_x, darkcount_y)
    sipm_afterpulse_pe = Shape(afterpulse_x, afterpulse_y)
    p = plot(sipm_surface, size=(700,700), fillcolor = "yellowgreen", legend = false, show = false)
    plot!(sipm_photon_pe, fillcolor = "blue", show = false)
    plot!(sipm_crosstalk_pe, fillcolor = "red", show = false)
    plot!(sipm_darkcount_pe, fillcolor = "black", show = false)
    plot!(sipm_afterpulse_pe, fillcolor = "orange", show = false)
    return p
end
function animation(sipm::SiPM; frame_count::Integer)
    step_size::Integer = round(sipm.sim_environment.step_total/frame_count)
    @gif for i =1:step_size:sipm.sim_environment.step_total
        inspect(sipm,i)
    end
end
function inspect(light_source::LightSource)
    extent = typeof(light_source.distribution_x) == max(light_source.distribution_x.σ, light_source.distribution_y.σ) * 3
    precision = (extent/15)
    xs = []
    ys = []
    zs = []
    for x = -extent:precision:extent
        for y = -extent:precision:extent
            push!(xs, x)
            push!(ys, y)
            push!(zs, local_rate(light_source.distribution_x, light_source.distribution_y, x, y, precision, 1))
        end
    end
    println(sum(zs))
    return plot(xs, ys, zs, title="Light Source Distribution", legend=false)
end


function save_html(path::String, filename::String, data)
    open("$filename.html", "w") do f
        pretty_table(f, data, backend = :html)
    end
end

# function save_xlsx(filename, data)
#     XLSX.openxlsx("my_new_file.xlsx", mode="w") do xf
#
#         sheet_data["B1", dim=1] = data
#
#         # will add a matrix from "A7" to "C9"
#         sheet["A7:C9"] = [ 1 2 3 ; 4 5 6 ; 7 8 9 ]
#     end
# end

function save_csv(path::String, filename::String, data::Array)
    output_filename = string(filename,".csv")
    writedlm(joinpath(path, output_filename), data, ',')
    println("$output_filename saved in $path")
end
