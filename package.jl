using Pkg; Pkg.activate(".")
Pkg.add("Pluto")       #Do this as many times as you need to, changing the string (containing the package name) every time.
Pkg.add("PlutoUI")
Pkg.add("Genie")
Pkg.add("Genie.Router")
using Genie
using Genie.Router

function launchServer(port)

    Genie.config.run_as_server = true
    Genie.config.server_host = "0.0.0.0"
    Genie.config.server_port = port

    println("port set to $(port)")

    route("/") do
        "Hi there!"
    end

    Genie.AppServer.startup()
end

launchServer(parse(Int, ARGS[1]))
