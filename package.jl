using Pkg; Pkg.activate(".")
Pkg.add("Pluto")       #Do this as many times as you need to, changing the string (containing the package name) every time.
Pkg.add("PlutoUI")
Pkg.add("Interact"
Pkg.add("Mix")
import Pluto
using Interact, Mux
b = button("Click me")
ui = hbox(b, observe(b))
port = parse(Int64, ARGS[1])
wait(WebIO.webio_serve(page("/", req -> ui), port))
