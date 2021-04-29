import Pkg
Pkg.activate(".")
Pkg.instantiate()
Pkg.precompile()
using PhotoMC
using Plots
using Distributions
using Pluto
using PlutoUI
