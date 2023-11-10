using JuMP, Random, PyCall, Profile, Statistics

include("methods.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 20
t = 25
cst = 2500  #COÛT DE PÉNÉLISATION DES SOLUTIONS INFAISABLES
version = 1
println("p = ", p)
println("t = ", t)

println("\nEssai pour compilation\n")
file_p = "instances/instances_alpha0.8/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
instance = init.gen_instance(p,t, fp=file_p); 
instance["P"] = 1:p;
instance["T"] = 1:t;
instance["t"] = t
instance["p"] = p 
instance["cst"] = cst
lpop = 10
niter = 15
size = 7
step = 1

@time result2 = AG_FO(lpop, niter, size, step, instance)


all_milp_obj = Dict("5_5" => [15460.0, 20440.0, 19552.0, 18307.0, 20538.4, 17449.0, 18948.48, 21885.0, 22656.4, 19269.88],
                "5_10" => [34436.85, 38259.34, 41255.23, 35847.0, 39499.0, 37237.66, 36087.56, 35852.42, 36894.1, 41932.44],
                "5_25" => [92401.67, 99333.12, 93637.56, 100558.76, 88732.32, 85800.5, 92300.99, 88980.42, 89422.03, 95953.45],
                "20_5" => [65821.0, 71523.0, 72914.0, 77234.8, 64474.0, 74472.0, 64012.0, 67394.0, 66733.0, 69388.0],
                "20_10" => [131695.0, 132328.0, 132119.0, 130755.0, 126487.0, 131454.76, 135600.0, 129495.0, 132536.0, 130459.41],
                "20_25" => [332225.78, 312747.79, 329088.83, 338021.59, 324334.15, 334620.0, 338631.0, 330110.68, 338707.53, 320031.27],
                "50_5" => [164257.0, 170422.0, 177472.0, 173467.0, 165798.0, 171770.0, 180896.0, 161965.0, 172486.0, 161851.0],
                "50_10" => [325130.0, 324754.0, 329134.0, 329527.0, 328015.0, 332403.32, 331663.0, 343003.0, 311613.0, 333907.0],
                "50_25" => [818459.77, 818381.56, 807283.88, 793525.6, 805575.0, 801661.9, 809611.18, 814712.0, 795287.56, 818040.84],
                "100_5" => [332011.0, 339338.6, 331254.0, 327350.0, 339097.0, 334298.0, 327358.0, 335512.0, 328290.0, 340441.0],
                "100_10" => [657875.0, 660381.0, 674392.0, 648278.0, 628996.0, 621788.0, 625850.0, 644203.0, 643854.0, 660441.0],
                "100_25" => [1.59665988e6, 1.60209204e6, 1.60952352e6, 1.57197976e6, 1.58084695e6, 1.59750359e6, 1.5840202e6, 1.59290364e6, 1.58795656e6, 1.6108116e6] )

key = string(p)*"_"*string(t)
milp_obj = all_milp_obj[key]

nbr_instance = 10

gap_value = []
time_value = []
ag_time_value = []
fo_time_value = []
objectifs = []
for version in 1:nbr_instance
	println("\n--------------------INSTANCE ", version, "------------------------\n")
	
	file_path = "instances/instances_alpha0.8/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
	instance_dict = init.gen_instance(p,t, fp=file_path); 
	instance_dict["P"] = 1:p;
	instance_dict["T"] = 1:t;
	instance_dict["t"] = t
	instance_dict["p"] = p 
	instance_dict["cst"] = cst
	alpha = instance_dict["alpha"]
	cmax = instance_dict["cmax"]
	mtn_cost = instance_dict["mtn_cost"]
	set_up_cost = instance_dict["set_up_cost"]


	println("\n\nALGORITHME GÉNÉTIQUE - ITERATED FIX AN OPTIMIZE")

	len_pop = 30
	nbr_iter = 50
	foSize = 7
	foStep = 2
	println("len_pop = ", len_pop)
	println("Nombre d'itération = ", nbr_iter)

	best_sol, ag_time, fo_time = AG_FO(len_pop, nbr_iter, foSize, foStep, instance_dict)
	
	agfo_time = ag_time + fo_time 
	obj = round(best_sol.obj, digits = 2)
	push!(objectifs, obj)

	gap = round((obj-milp_obj[version])/milp_obj[version]*100, digits = 2)
	push!(gap_value, gap)
	push!(time_value, agfo_time)
	push!(ag_time_value, ag_time)
	push!(fo_time_value, fo_time)
end
println("\n")
println("Moyenne des objectifs : ", (mean(objectifs)))
println("Moyenne des gaps : ", round(mean(gap_value), digits = 4))
println("Moyenne des temps de AG : ", round(mean(ag_time_value), digits = 4))
println("Moyenne des temps de FO : ", round(mean(fo_time_value), digits = 4))
println("Moyenne des temps total : ", round(mean(time_value), digits = 4))


