import Pluto

@info "Launching Pluto"
Pluto.run(host = "0.0.0.0", port = hostparse(Int,ARGS[1]))
