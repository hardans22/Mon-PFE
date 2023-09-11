using PyCall

include("model.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 35
t = 25
version = 1
println("p = ", p)
println("t = ", t)

for version in 1:10
    println("\n--------------------------------------------------INSTANCE ", version, "-----------------------------------------------------------\n")
    file_path = "instances/instances_alpha0.8/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
    instance_dict = init.gen_instance(p,t, fp=file_path); 
    instance_dict["P"] = 1:p;
    instance_dict["T"] = 1:t;
    instance_dict["t"] = t
    instance_dict["p"] = p
    alpha = instance_dict["alpha"]
    println("alpha = ", alpha)

    result = model_mip(instance_dict)

    z = result["z"]
    y = result["y"]
    z_prime = [z[t,t] for t in 1:t]
    println("\nNombre de maintenance : ", sum(z_prime))
    println("Plan de maintenance optimal : ")
    println(z_prime)
    nbr_setup = []
    for i in 1:p
        push!(nbr_setup, sum(y[i,:]))
    end
    println("Nombre de setup par produit : ")
    println(nbr_setup)
end
