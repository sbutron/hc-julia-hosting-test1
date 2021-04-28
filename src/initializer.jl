using Distributed
@info "Initializing PhotoMC Version 0.0.8 (2021-03-18)"

@everywhere begin
    import Pkg
    Pkg.activate(".")
end
for processor in procs()
    @sync @spawnat processor include("src/main.jl")
end

function sysinfo()
    _nprocs = Distributed.nprocs()
    @info "Cores: $_nprocs"
    for processor in procs()
        _threads =  @spawnat processor Threads.nthreads()
        _threads = fetch(_threads)
        @info "Core $processor: $_threads threads available."
    end
end
sysinfo()
