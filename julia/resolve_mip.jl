using PyCall

include("model.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 25
t = 20
version = 1
println("p = ", p)
println("t = ", t)

for version in 1:10
    println("\n--------------------------------------------------INSTANCE ", version, "-----------------------------------------------------------\n")
    file_path = "instances/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
    instance_dict = init.gen_instance(p,t, fp=file_path); 
    instance_dict["P"] = 1:p;
    instance_dict["T"] = 1:t;
    instance_dict["t"] = t
    instance_dict["p"] = p

    result = model_mip(instance_dict)

    z = result["z"]
    y = result["y"]
    z = Array(z)
    println("\nNombre de maintenance : ", sum(z))
    println("Plan de maintenance optimal : ")
    println(z)
    nbr_setup = []
    for i in 1:p
        push!(nbr_setup, sum(y[i,:]))
    end
    println("Nombre de setup par produit : ")
    println(nbr_setup)
end