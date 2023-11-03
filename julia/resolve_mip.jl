using PyCall, Statistics

include("model.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 50
t = 25
println("p = ", p)
println("t = ", t)
allobj = []
alltime = []
for version in 1:2
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

    x = result["x"]
    I = result["I"]
    z = result["z"]
    y = result["y"]
    obj = result["obj"]
    time = result["time"]
    push!(allobj, round(obj, digits = 2))
    push!(alltime, round(time, digits = 4))
    z_prime = [floor(Int, z[t,t]) for t in 1:t]
    #=
    println("Matrice x : ")
    display(x)
    println("Matrice I : ")
    display(I)
    =#
    println("\nNombre de maintenance : ", sum(z_prime))
    println("Plan de maintenance optimal : ")
    println(z_prime)
    nbr_setup = []
    for i in 1:p
        push!(nbr_setup, floor(Int,sum(y[i,:])))
    end
    println("Nombre de setup par produit : ")
    println(nbr_setup)
end
println("\n \nListes des objectifs de chaque instance: ", allobj)
println("\n \nListes des temps de résolution de chaque instance: ", alltime)
println("\nMoyenne des temps : ", round(mean(alltime), digits = 4))

