# Electronics
include("./components/electronics/passives.jl")
include("./components/electronics/coaxialcables.jl")
include("./components/electronics/opamps.jl")
include("./components/electronics/lowpassfilters.jl")
include("./components/electronics/bandpassfilters.jl")
include("./components/electronics/probes.jl")
include("./components/electronics/terminators.jl")
include("./components/electronics/amplifiers.jl")

# Detectors
include("./components/detectors/sipm.jl")
include("./components/detectors/sipm/S13360.jl")
include("./components/detectors/sipm/S13720.jl")
include("./components/detectors/sipm/S14420.jl")

include("./components/detectors/apd.jl")
include("./components/detectors/apd/S14645.jl")

#Light Sources
include("./components/lightsources/lightsource.jl")

#optics
include("./components/optics/opticalfilter.jl")
include("./components/optics/aperture.jl")
include("./components/optics/bandpass_filters/Thorlabs.jl")

#optical systems
include("./components/optical_system/lidar.jl")
