# module ArbMatrix
# using SparseArrays
# using StaticArrays
# include("./math_ops.jl")
# export PlaneSpace, setindex!, getindex, setobject!, removeobject!, getobject, plottable
"""
    make_plane(x_dims::Integer,y_dims::Integer)

    Returns a SparseMatrixCSC of x_dims by y_dims
"""
function make_plane(x_dims::Integer,y_dims::Integer, type_of::Type)
    return spzeros(type_of, x_dims, y_dims)
end

"""
    PlaneSpace(x_width::Real, y_width::Real, dim_precision::Real)
    Constructs a 2D plane with indexes corresponding to the dim_precision, for example if dim_precision is 1e-6, then [1,1] corresponds to [1e-6,1e-6]
    The size size of the plane is given by the x_width and y_width, with positions equally spaced by the dim_precision.

    # Example:
    julia> myArbMatrix = PlaneSpace(1e-6)
    PlaneSpace(10000000×10000000 SparseMatrixCSC{Float64,Integer} with 0 stored entries, 1.0e-6, 5000000, 5000000)

    Indexes can be accessed by Integer or Floating numbers of positive or negative sign
    # Example:
    julia> myArbMatrix[-1.1e-6,0] = 2
    2
    julia> myArbMatrix[-1e-6,0] = 0
    0
    julia> myArbMatrix[0,0] = 9
    9

    The sparse matrix can be accesed by PlaneSpace.space
    # Example:
    julia> myArbMatrix.space
    10000000×10000000 SparseMatrixCSC{Float64,Integer} with 2 stored entries:
    [4999999, 5000000]  =  0.0
    [5000000, 5000000]  =  9.0

    All matrix operations are valid on PlaneSpace.space
    # Examples:
    julia> dropzeros(myArbMatrix.space)
    10000000×10000000 SparseMatrixCSC{Float64,Integer} with 1 stored entry:
    [5000000, 5000000]  =  9.0

    julia> myArbMatrix.space * 2
    10000000×10000000 SparseMatrixCSC{Float64,Integer} with 1 stored entry:
    [5000000, 5000000]  =  18.0
"""
mutable struct PlaneSpace
    space::SparseMatrixCSC
    objects::Vector{Any}
    dim_precision::Float64
    x_offset::Float64
    y_offset::Float64
    center_x::Integer
    center_y::Integer
    extrema_x::Vector{Float64}
    extrema_y::Vector{Float64}
    function PlaneSpace(x_width::Float64, y_width::Float64, x_offset::Float64, y_offset::Float64, dim_precision::Float64, type_of::Type)
        x_dims::Integer = round(x_width / dim_precision)
        y_dims::Integer = round(y_width / dim_precision)
        space = spzeros(type_of, x_dims, y_dims)
        objects = []
        size_x, size_y = size(space)
        center_x::Integer = round(size_x / 2)
        center_y::Integer = round(size_y / 2)
        extrema_x = [(-center_x+1) * dim_precision, center_y * dim_precision] .+ x_offset
        extrema_y = [(-center_x+1) * dim_precision, center_y * dim_precision] .+ y_offset
        new(space::SparseMatrixCSC,
            objects::Vector{Any},
            dim_precision::Float64,
            x_offset::Float64,
            y_offset::Float64,
            center_x::Integer,
            center_y::Integer,
            extrema_x::Vector{Float64},
            extrema_y::Vector{Float64})
    end
end # mutable struct PlaneSpace
# these functions and classes are used to define the ArbMatrix space and materials which reside in the ArbMatrix
import Base.setindex!
import Base.getindex
import Base: +, -, *, /

@inline function convert_index_to_float(plane_space::PlaneSpace, x::Integer, y::Integer)::Tuple{Float64, Float64}
    x::Float64 = (x - plane_space.center_x)
    y::Float64 = (y - plane_space.center_y)
    return (x * plane_space.dim_precision + plane_space.offset_x::Float64), (y * plane_space.dim_precision + plane_space.offset_y::Float64)
end
@inline function convert_float_to_index(plane_space::PlaneSpace, x::Float64, y::Float64)::Tuple{Int64, Int64}
    x::Integer = round(round_to(x - plane_space.x_offset, plane_space.dim_precision) / plane_space.dim_precision, RoundNearestTiesAway)
    y::Integer = round(round_to(y - plane_space.y_offset, plane_space.dim_precision) / plane_space.dim_precision, RoundNearestTiesAway)
    # x::Int64 = x ÷ plane_space.dim_precision
    # y::Int64 = y ÷ plane_space.dim_precision
    return x + plane_space.center_x, y + plane_space.center_y
end
"""
    setindex!(plane_space::PlaneSpace, v , x::Real, y::Real)
    Extends the Base.setindex! function to accept PlaneSpace object and floating and negative indexes.
    Converts floating or integer indexes to nearest matching index based on the the dim_precision parameter of the PlaneSpace
"""
function setindex!(plane_space::PlaneSpace, v::Real , x::Float64, y::Float64)
    @views if plane_space.extrema_x[1] <= x <= (plane_space.extrema_x[2]) &&  plane_space.extrema_y[1] <= y <= (plane_space.extrema_y[2])
        index_x, index_y = convert_float_to_index(plane_space, x, y)
        plane_space.space[index_x, index_y] = v
    else
        @info "Out of bounds"
    end
    return nothing
end

# function setindex!(plane_space::PlaneSpace, v::Integer , x::Float64, y::Float64)
#     v = convert(Float64, v)
#     @views if plane_space.extrema_x[1] <= x <= (plane_space.extrema_x[2]) &&  plane_space.extrema_y[1] <= y <= (plane_space.extrema_y[2])
#         index_x, index_y = convert_float_to_index(plane_space, x, y)
#         plane_space.space[index_x, index_y] = v
#     end
#     return nothing
# end

"""
    getindex(plane_space::PlaneSpace, v , x::Real, y::Real)
    Extends the Base.getindex function to accept PlaneSpace object and floating and negative indexes.
    Converts floating or integer indexes to nearest matching index based on the the dim_precision parameter of the PlaneSpace
"""
function getindex(plane_space::PlaneSpace, x::Float64, y::Float64)
    value = 0
    @views if plane_space.extrema_x[1] <= x <= (plane_space.extrema_x[2]) &&  plane_space.extrema_y[1] <= y <= (plane_space.extrema_y[2])
        index_x, index_y = convert_float_to_index(plane_space, x, y)
        value = plane_space.space[index_x::Int64, index_y::Int64]
    end
    return value
end

"""
    setobject!(plane_space::PlaneSpace, object , x::Real, y::Real)
    Sets the object which the PlaneSpace index points to at position x, y.
"""
function setobject!(plane_space::PlaneSpace, object, x::Real, y::Real)
    pointer::Integer = round(getindex(plane_space, x, y))
    if pointer == 0 # the space current points to nothing
        first_empty = findfirst(isequal(nothing),plane_space.objects) # find first instance of nothing in the object vector
        if first_empty == nothing   # if there are zero instances of nothing in the object vector then
            push!(plane_space.objects, object) # push object to the end of the object vector
            plane_space[x, y] = length(plane_space.objects) # the length of the object vector is the index of the new object
        else # otherwise there is a nothing entry in the object vector so replace it
            plane_space.objects[first_empty] = object # replacing the nothing entry with the new object
            plane_space[x, y] = first_empty # setting the space to point to the new object
        end
    else # the case is pointing to an existing object
        plane_space.objects[pointer] = object # replace the existing object with the new one
    end
end

"""
    removeobject(plane_space::PlaneSpace, x::Real, y::Real)
    Remove the object located at x, y from the plane_space
"""
function removeobject!(plane_space::PlaneSpace, x::Real, y::Real)
    pointer::Integer = round(getindex(plane_space, x, y))
    report = "Location is already empty!"
    if pointer > 0 # if pointer is pointing to an object
        plane_space[x, y] = 0 # set the pointer to zero
        report = "Object #$pointer removed."
        plane_space.objects[pointer] = nothing # replace the entry in the object vector with nothing

    end
    dropzeros!(plane_space.space) # drop the zeros in the space sparse matrix
    return report
end

"""
    getobject(plane_space::PlaneSpace, x::Real, y::Real)
    Gets the object which the PlaneSpace index points to at position x, y.
"""
function getobject(plane_space::PlaneSpace, x::Real, y::Real)
    pointer::Integer = round(getindex(plane_space, x, y))
    object = nothing
    if pointer > 0
        object = plane_space.objects[pointer]
    end
    return object
end

function foreachnz!(plane_space::PlaneSpace, func::Function)
    c, r, v = findnz(plane_space.space)
    for i in eachindex(c)
        x = c[i]
        y = r[i]
        plane_space.space[x, y] = func(plane_space.space[x, y])
    end
    dropzeros!(plane_space.space)
    return plane_space
end
"""
    for each nonzero element in plane_space_a
"""
function foreachnz!(plane_space_a::PlaneSpace, plane_space_b::PlaneSpace, func::Function)
    c, r, v = findnz(plane_space_a.space)
    for i in eachindex(c)
        x = c[i]
        y = r[i]
        plane_space_a.space[x, y] = func(plane_space_a.space[x, y],plane_space_b.space[x, y])
    end
    dropzeros!(plane_space_a.space)
    return plane_space_a
end

function foreachnz(plane_space_a::PlaneSpace, plane_space_b::PlaneSpace, func::Function, plane_space_c::PlaneSpace)
    foreachnz!(plane_space_c, x->x*0)
    c, r, v = findnz(plane_space_a.space)
    for i in eachindex(c)
        x = c[i]
        y = r[i]
        plane_space_c.space[x, y] = func(plane_space_a.space[x, y],plane_space_b.space[x, y])
    end
    dropzeros!(plane_space_c.space)
    return plane_space_c
end

function nzindexes(plane_space::PlaneSpace)
    c, r, v = findnz(plane_space.space)
    return c, r
end

function foreachnz!(sparse_matrix::SparseMatrixCSC,func::Function)
    c, r, v = findnz(sparse_matrix)
    for i in eachindex(c)
        x = c[i]
        y = r[i]
        sparse_matrix[x, y] = func(sparse_matrix[x, y])
    end
    dropzeros!(sparse_matrix)
    return sparse_matrix
end
