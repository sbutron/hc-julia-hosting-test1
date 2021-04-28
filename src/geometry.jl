abstract type PrimitiveShape
end
mutable struct Coordinate <: PrimitiveShape
    x::Float64
    y::Float64
    function Coordinate(x::Real, y::Real)
        x::Float64 = x
        y::Float64 = y
        new(x, y)
    end
end
pt(x, y) = Coordinate(x, y)

mutable struct Square <: PrimitiveShape
    center::Coordinate
    length::Real
    ll::Coordinate
    lr::Coordinate
    ur::Coordinate
    ul::Coordinate
    function Square(;center::Coordinate, length::Real)
        length::Float64 = length
        _halflength = length / 2
        ll = Coordinate(center.x - _halflength, center.y - _halflength)
        lr = Coordinate(center.x + _halflength, center.y - _halflength)
        ur = Coordinate(center.x + _halflength, center.y + _halflength)
        ul = Coordinate(center.x - _halflength, center.y + _halflength)
        new(center, length, ll, lr, ur, ul)
    end
end

mutable struct Rectangle <: PrimitiveShape
    center::Coordinate
    length::Float64
    width::Float64
    ll::Coordinate
    lr::Coordinate
    ur::Coordinate
    ul::Coordinate
    function Rectangle(;center::Coordinate, length::Real, width::Real)
        length::Float64 = length
        width::Float64 = width
        _halflength = length / 2
        _halfwidth = width / 2
        ll = Coordinate(center.x - _halflength, center.y - _halfwidth)
        lr = Coordinate(center.x + _halflength, center.y - _halfwidth)
        ur = Coordinate(center.x + _halflength, center.y + _halfwidth)
        ul = Coordinate(center.x - _halflength, center.y + _halfwidth)
        new(center, length, width, ll, lr, ur, ul)
    end
end
mutable struct Circle <: PrimitiveShape
    center::Coordinate
    radius::Float64
end
function Circle(;center::Coordinate, diameter::Real = 0.0,radius::Real = 0.0)
    diameter::Float64 = diameter
    radius::Float64 = radius
    if diameter > 0
        radius = diameter / 2
    end
    return Circle(center, radius)
end



## returns x, y tuple of randomly sampled position of a normally distributed beam
function distribute_beam(center_x, center_y, spread_x, spread_y)
    x = rand(PRNGs[Threads.threadid()], Normal(center_x, spread_x))
    y = rand(PRNGs[Threads.threadid()], Normal(center_y, spread_y))
    return x, y
end #function distribute_beam

## returns a lattice matrix[x, y] position of pixel center
function make_circle_lattice(number_of_pixels::Integer)
    max_pixels = number_of_pixels*2
    lattice_points = zeros(Float64,max_pixels,3)
    #lattice_points = zeros(SMatrix{max_pixels,3})
    lattice_points[1,1] = 0
    lattice_points[1,2] = 0
    pixel_count = 1
    r = 1
    while pixel_count < max_pixels
        x = r
        y = 0
        while x > 0 # right to center
            distance = sqrt( (x^2) + (y^2) )
            pixel_count += 1
            lattice_points[pixel_count,1] = x
            lattice_points[pixel_count,2] = y
            lattice_points[pixel_count,3] = distance
            if pixel_count == max_pixels
                @goto all_pixels_assigned
            end
            x -= 1
            y -= 1
        end
        while x > -r # center to left
            distance = sqrt( (x^2) + (y^2) )
            pixel_count += 1
            lattice_points[pixel_count,1] = x
            lattice_points[pixel_count,2] = y
            lattice_points[pixel_count,3] = distance
            if pixel_count == max_pixels
                @goto all_pixels_assigned
            end
            x -= 1
            y += 1
        end
        while x < 0 # left to center
            distance = sqrt( (x^2) + (y^2) )
            pixel_count += 1
            lattice_points[pixel_count,1] = x
            lattice_points[pixel_count,2] = y
            lattice_points[pixel_count,3] = distance
            if pixel_count == max_pixels
                @goto all_pixels_assigned
            end
            x += 1
            y += 1
        end
        while x < r # center to right
            distance = sqrt( (x^2) + (y^2) )
            pixel_count += 1
            lattice_points[pixel_count,1] = x
            lattice_points[pixel_count,2] = y
            lattice_points[pixel_count,3] = distance
            if pixel_count == max_pixels
                @goto all_pixels_assigned
            end
            x += 1
            y -= 1
        end
        r += 1
    end
    @label all_pixels_assigned
    # sort the lattice positions by distance
    lattice_sorting_index = sorting_index(lattice_points,3)

    # form a new lattice array with x, y positions
    sorted_lattice_points = zeros(Float64,number_of_pixels,2)
    for p = 1:number_of_pixels
        p_index = lattice_sorting_index[p]
        sorted_lattice_points[p,1] = lattice_points[p_index,1]
        sorted_lattice_points[p,2] = lattice_points[p_index,2]
    end
    return sorted_lattice_points
end #function generate_circular_pixel_grid

## returns a lattice matrix[x, y] position of pixel center
function make_square_lattice(number_of_pixels::Integer)
    lattice_points = zeros(Float64,number_of_pixels,2)
    lattice_points[1,1] = 0
    lattice_points[1,2] = 0
    pixel_count = 1
    layer = 1
    while pixel_count < number_of_pixels
        x = layer
        y = layer
        while y > -layer # right to bottom-right
            y -= 1
            pixel_count += 1
            lattice_points[pixel_count,1] = x
            lattice_points[pixel_count,2] = y
            if pixel_count == number_of_pixels
                @goto all_pixels_assigned
            end
        end
        while x > -layer # bottom-right to bottom-left
            x -= 1
            pixel_count += 1
            lattice_points[pixel_count,1] = x
            lattice_points[pixel_count,2] = y
            if pixel_count == number_of_pixels
                @goto all_pixels_assigned
            end
        end
        while y < layer # bottem-left to top-left
            y += 1
            pixel_count += 1
            lattice_points[pixel_count,1] = x
            lattice_points[pixel_count,2] = y
            if pixel_count == number_of_pixels
                @goto all_pixels_assigned
            end
        end
        while x < layer #top-left to top-right
            x += 1
            pixel_count += 1
            lattice_points[pixel_count,1] = x
            lattice_points[pixel_count,2] = y
            if pixel_count == number_of_pixels
                @goto all_pixels_assigned
            end
        end
        layer += 1
    end
    @label all_pixels_assigned
    return lattice_points
end

## returns SMatrix[x1 x2 x3 x4 ; y1 y2 y3 x4]
function make_square(center_x, center_y, length)
    mid_length = length / 2
    x_1 = center_x - mid_length
    y_1 = center_y - mid_length

    x_2 = center_x + mid_length
    y_2 = center_y - mid_length

    x_3 = center_x + mid_length
    y_3 = center_y + mid_length

    x_4 = center_x - mid_length
    y_4 = center_y + mid_length
    square = @SMatrix[
                x_1 x_2 x_3 x_4;
                y_1 y_2 y_3 y_4
                ]
    return square
end

##
"""
    make_sensor_matrix(lattice_matrix, pixel_pitch)

    Returns a vector of square pixels represented by four points of SMatrix[x1 x2 x3 x4 ; y1 y2 y3 x4]
    The lattice_matrix provides the center of each pixels, and the four corners are calculated from the pixel_pitch

    #Examples
    julia> circle_mppc = make_square_lattice(4)
    4×2 Array{Float64,2}:
      0.0   0.0
      1.0   1.0
      1.0   0.0
      1.0  -1.0
    julia> sensor_matrix = make_sensor_matrix(circle_mppc,25e-6)
    4-element Array{Any,1}:
     [-1.25e-5 1.25e-5 1.25e-5 -1.25e-5; -1.25e-5 -1.25e-5 1.25e-5 1.25e-5]
     [1.25e-5 3.7500000000000003e-5 3.7500000000000003e-5 1.25e-5; 1.25e-5 1.25e-5 3.7500000000000003e-5 3.7500000000000003e-5]
     [1.25e-5 3.7500000000000003e-5 3.7500000000000003e-5 1.25e-5; -1.25e-5 -1.25e-5 1.25e-5 1.25e-5]
     [1.25e-5 3.7500000000000003e-5 3.7500000000000003e-5 1.25e-5; -3.7500000000000003e-5 -3.7500000000000003e-5 -1.25e-5 -1.25e-5]
"""
function make_sensor_matrix(lattice_matrix, pixel_pitch)
    rows, cols = size(lattice_matrix)
    sensor_matrix = []
    for i = 1:rows
        center_x = lattice_matrix[i,1] * pixel_pitch
        center_y = lattice_matrix[i,2] * pixel_pitch
        pixel = make_square(center_x,center_y,pixel_pitch)
        push!(sensor_matrix, pixel)
    end
    return sensor_matrix
end
##
"""
    point_distance(x1, y1, x2, y2)

    Returns the distance between two points x1,y1 and x2,y2

    #Examples
    julia> point_distance(0,0,1,1)
    1.4142135623730951
"""
function point_distance(x1::Real, y1::Real, x2::Real, y2::Real)
    distance = sqrt(((x2-x1)^2) + ((y2-y1)^2))
    return distance
end
function point_distance(pt1::Coordinate, pt2::Coordinate)
    return sqrt((pt2.x - pt1.x)^2 + (pt2.y - pt1.y)^2)
end
##
"""
    check_collision(object_1::SMatrix, object_2::SMatrix)

    Returns bool true if object_1 is touching object_2
    object_1 and object_2 must by static matrix of 2 by n size

    #Examples
    julia> polyA
    2×4 SArray{Tuple{2,4},Float64,2,8} with indices SOneTo(2)×SOneTo(4):
     -1.25e-5   1.25e-5  1.25e-5  -1.25e-5
     -1.25e-5  -1.25e-5  1.25e-5   1.25e-5

    julia> polyB
    2×4 SArray{Tuple{2,4},Float64,2,8} with indices SOneTo(2)×SOneTo(4):
      0.0001125   0.0001375   0.0001375   0.0001125
     -8.75e-5    -8.75e-5    -6.25e-5    -6.25e-5

    julia> dir
    2-element SArray{Tuple{2},Float64,1,2} with indices SOneTo(2):
      0.24765840209922318
     -0.2763286184156082

    julia> collision_detection(polyA, polyB, dir)
    false
"""
function check_collision(object_1::SMatrix, object_2::SMatrix)
    dir = @SVector(rand(PRNGs[Threads.threadid()], 2)) .- 0.5
    collision_detection(object_1,object_2,dir)
end

function collision(sq::Square, pt::Coordinate)
    if pt.x <= sq.ll.x || pt.x >= sq.lr.x || pt.y <= sq.ll.y || pt.y >= sq.ul.y
        return false
    else
        return true
    end
end
collision(pt::Coordinate, sq::Square) = collision(sq, pt)

function collision(rec::Rectangle, pt::Coordinate)
    if pt.x <= rec.ll.x || pt.x >= rec.lr.x || pt.y <= rec.ll.y || pt.y >= rec.ul.y
        return false
    else
        return true
    end
end
collision(pt::Coordinate, rec::Rectangle) = collision(rec, pt)


function collision(circ::Circle, pt::Coordinate)
    if point_distance(circ.center, pt) >= circ.radius
        return false
    else
        return true
    end
end

@inline function line_vector(a::Coordinate, b::Coordinate)
    return [b.x - a.x, b.y - a.y]
end

@inline function areaof(circle::Circle)::Float64
    return pi*circle.radius^2
end

@inline function areaof(square::Square)::Float64
    return square.length^2
end

@inline function areaof(rectangle::Rectangle)::Float64
    return rectangle.length * rectangle.width
end
