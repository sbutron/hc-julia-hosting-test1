import Pkg
Pkg.activate(".")
Pkg.instantiate()
Pkg.precompile()

using Distributed
@info "Intializing PhotoMC at Process $(myid())"

import ACME # circuit simulation
using BenchmarkTools
using Colors # names colors
using ConvexBodyProximityQueries # collision detection
using Dates # serializing simulation runs
using DataFrames
using DelimitedFiles # saving and reading CSV files
using Distributions # distributed PRNG

#using FLoops # fast loops
#import Gtk
#using Infiltrator # troublshooting
#using InspectDR
using LinearAlgebra
using Parameters
using Profile # function speed profiler

using Plots # data visualization
gr()

using Polynomials # for interpolation of detector characteristic curves
using PoissonRandom # specialized fast Poisson random sampler
using PrettyTables # for table print formatting
using ProgressMeter
using Random # native PRNG
using RandomNumbers # faster PRNG
using SparseArrays # for representing MPPC microcell matrix
using StaticArrays
import Base.Threads
using ThreadsX
using ThreadTools
import XLSX # for saving and reading MS Excel spreadsheets


PRNGs = []
for thread = 1:Threads.nthreads()
    push!(PRNGs, Xorshifts.Xoroshiro128Plus())
end

include("./data.jl")
include("./probability.jl")
include("./global_variables.jl")
include("./math_ops.jl")
include("./matrix_functions.jl")
include("./geometry.jl")
include("./temporal.jl")
include("./arbmatrix.jl")
include("./simulation.jl")
include("./components.jl")
include("./connections.jl")
include("./postprocessing.jl")
include("./visualization.jl")
#include("./test.jl")end

@info "Photo MC is ready at Process $(myid())"


import Pluto


@info "Launching Pluto"
Pluto.run(host = "0.0.0.0", port = parse(Int,ARGS[1]))
