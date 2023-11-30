using PyCall, Statistics

include("model.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 20
t = 25
println("p = ", p)
println("t = ", t)
allobj = []
alltime = []
allgap = []

all_milp_obj = Dict("5_5" => [15460.0, 20440.0, 19552.0, 18307.0, 20538.4, 17449.0, 18948.48, 21885.0, 22656.4, 19269.88],
                    "5_10" => [34436.85, 38259.34, 41255.23, 35847.0, 39499.0, 37237.66, 36087.56, 35852.42, 36894.1, 41932.44],
                    "5_25" => [92401.67, 99333.12, 93637.56, 100619.96, 88732.32, 85800.5, 92300.99, 88980.42, 89422.03, 95953.45],
                    "20_5" => [65821.0, 71523.0, 72914.0, 77234.8, 64474.0, 74472.0, 64012.0, 67394.0, 66733.0, 69388.0],
                    "20_10" => [131695.0, 132328.0, 132119.0, 130755.0, 126478.0, 131454.76, 135600.0, 129495.0, 132536.0, 130459.41],
                    "20_25" => [332225.78, 312747.79, 329088.83, 338021.59, 324334.15, 334860.0, 338631.0, 330110.68, 338818.53, 320031.27],
                    "50_5" => [164257.0, 170422.0, 177460.0, 173467.0, 165798.0, 171770.0, 180896.0, 161965.0, 172486.0, 161859.0],
                    "50_10" => [325139.0, 324754.0, 329134.0, 329514.0, 328027.8, 332474.71, 331724.0, 343003.0, 311610.0, 333907.0],
                    "50_25" => [818524.33, 818439.54, 807314.8, 793584.3, 805601.0, 802656.44, 809644.18, 814724.0, 795379.94, 818108.3],
                    "100_5" => [332006.0, 339328.0, 331254.0, 327352.0, 339089.0, 334298.0, 327358.0, 335512.0, 328289.0, 340441.0],
                    "100_10" => [657901.0, 660393.0, 674809.6, 648278.0, 629050.0, 621812.4, 625846.0, 644230.0, 644185.0, 660441.0],
                    "100_25" => [1.59679632e6, 1.60249884e6, 1.60968752e6, 1.57286169e6, 1.58095643e6, 1.5975602e6, 1.5840712e6, 1.59294344e6, 1.58853132e6, 1.6112022e6]
                    )

key = string(p)*"_"*string(t)
milp_obj = all_milp_obj[key]


for version in 1:10
    println("\n--------------------------------------------------INSTANCE ", version, "-----------------------------------------------------------\n")
    file_path = "instances/instances_alpha0.8_bis/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
    instance_dict = init.gen_instance(p,t, fp=file_path); 
    instance_dict["P"] = 1:p;
    instance_dict["T"] = 1:t;
    instance_dict["t"] = t
    instance_dict["p"] = p
    alpha = instance_dict["alpha"]
    println("alpha = ", alpha)

    result = model_mip(instance_dict, milp_obj[version])

    x = result["x"]
    I = result["I"]
    z = result["z"]
    y = result["y"]
    obj = result["obj"]
    time = result["time"]
    gap = result["gap"]
    push!(allobj, round(obj, digits = 2))
    push!(alltime, round(time, digits = 4))
    push!(allgap,round(gap, digits = 4))
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
println("\nMoyenne des objectifs : ", round(mean(allobj), digits = 2))
println("\n \nListes des objectifs de chaque instance: ", allgap)
println("\nMoyenne des gaps : ", round(mean(allgap), digits = 4))
println("\n \nListes des temps de résolution de chaque instance: ", alltime)
println("\nMoyenne des temps : ", round(mean(alltime), digits = 4))

