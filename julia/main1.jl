using JuMP, Random, PyCall, Profile

include("./genetic_algorithm.jl")
include("RelaxAndFix _ FixAndOptimize.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 25
t = 20
println("3/5")
for version in 1:1
	println("\n--------------------------------------------------INSTANCE ", version, "-----------------------------------------------------------\n")
	file_path = "instances/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
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

	len_pop = 40
	nbr_iteration = 1000
	println("len_pop = ", len_pop)
	println("Nbr_iteration = ", nbr_iteration)

	@time result =  genetic_algorithm(instance_dict, len_pop,nbr_iteration)   

	objectives = result["objectives"]
	best_sol = result["best_sol"]
	
	println(best_sol.obj)
	println("Nombre de maintenance = ",sum(best_sol.z))
	sz = best_sol.z
	sc = best_sol.c
	sy = best_sol.y
	su = best_sol.u
	println("Feasibility of solution : ", verify_solution(best_sol.x, best_sol.I, sy, sz, sc, instance_dict))
	println("Maintenance : ",sz)
	println("Surplus : ",su) 
	#println("Matrice des setup : ")
	#display(sy)
    l = []
	for i in 1:p
		push!(l, sum(sy[i,:]))
	end
	println(l)
end