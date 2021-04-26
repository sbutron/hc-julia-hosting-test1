using Pkg; Pkg.activate(".")
Pkg.add("Pluto")       #Do this as many times as you need to, changing the string (containing the package name) every time.
import Pluto

@info "Launching Pluto"
Pluto.run(host = "0.0.0.0", port = hostparse(Int,ARGS[1]))
