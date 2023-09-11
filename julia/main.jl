using JuMP, Random, PyCall, Profile

include("./genetic_algorithm.jl")
include("RelaxAndFix _ FixAndOptimize.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 30
t = 25
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
@time result2 =  genetic_algorithm(instance, 10, 50)   
wSize = 15
olap = 0.4
tLimit = 15

inc = 5
bSol1 = result2["best_sol"]
result3 = general_FO(bSol1, wSize, olap, tLimit, inc, instance)


#version = 1
for version in 1:1
	println("\n--------------------INSTANCE ", version, "------------------------\n")
	file_path = "instances/instances_alpha0.8/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
	instance_dict = init.gen_instance(p,t, fp=file_path); 
	instance_dict["P"] = 1:p;
	instance_dict["T"] = 1:t;
	instance_dict["t"] = t
	instance_dict["p"] = p 
	alpha = instance_dict["alpha"]
	cmax = instance_dict["cmax"]
	mtn_cost = instance_dict["mtn_cost"]
	set_up_cost = instance_dict["set_up_cost"]


	println("\n\nALGORITHME GÉNÉTIQUE")

	len_pop = 30
	nbr_iteration = 1500
	println("len_pop = ", len_pop)
	println("Temps d'exécution = ", nbr_iteration)

	@time result =  genetic_algorithm(instance_dict, len_pop,nbr_iteration)   

	objectives = result["objectives"]
	best_sol = result["best_sol"]
	println(best_sol.obj)
	println(sum(best_sol.z))
	l = []
	sz = best_sol.z
	sc = best_sol.c
	sy = best_sol.y
	su = best_sol.u
	println("Feasibility of solution : ", verify_solution(best_sol.x, best_sol.I, sy, sz, sc, instance_dict))
	println("Maintenance : ",sz)
	println("Surplus : ",su) 
	#println("Matrice des setup : ")
	#display(sy)
	for i in 1:p
		push!(l, sum(sy[i,:]))
	end
	println(l)

	windowSize = 20
	overlap = 0.6
	timeLimit = 180

	increment = 3

	
	println("\nFIX AND OPTIMIZE")
	print("increment = ", increment, "\n \n")
	print("overlap = ", overlap, "\n \n")

	@time best_sol1 = general_FO(best_sol, windowSize, overlap, timeLimit, increment, instance_dict)
	sx = best_sol1.x
	sI = best_sol1.I
	sy = best_sol1.y
	su = best_sol1.u

	println("Feasibility of solution : ", verify_solution(sx, sI, sy, sz, sc, instance_dict))
	
end

