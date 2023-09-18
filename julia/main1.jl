using JuMP, Random, PyCall, Profile, Plots

include("./genetic_algorithm.jl")
include("RelaxAndFix _ FixAndOptimize.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 35
t = 25
println("p = ", p)
println("t = ", t)

version = 1
println("\nEssai pour compilation\n")
file_p = "instances/instances_alpha0.8/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
instance = init.gen_instance(p,t, fp=file_p); 
instance["P"] = 1:p;
instance["T"] = 1:t;
instance["t"] = t
instance["p"] = p 
@time result2 =  genetic_algorithm(instance, 10, 20)   

for version in 1:10
	println("\n------------------------------INSTANCE ", version, "----------------------------\n")
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


	println("ALGORITHME GÉNÉTIQUE")

	len_pop = 30
	nbr_iteration = 3000
	println("len_pop = ", len_pop)
	println("Nbr_iteration = ", nbr_iteration)
	for i in 1:2
		println("---------RUN ", i, "----------")
		@time result =  genetic_algorithm(instance_dict, len_pop,nbr_iteration)   

		objectives = result["objectives"]
		best_sol = result["best_sol"]
		
		println("best_sol = ", best_sol.obj)
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
		objectives = result["objectives"]
		len = length(objectives)
		gr()
		plt = plot(1:len, objectives, label = "", xlabelfontsize=8, ylabelfontsize=8, title="Evolution de la fonction objectif ", titlefontsize=10, lw=1, size=(700, 400))
		xlabel!("Nombre d'itération")
		ylabel!("Valeur de la fonction objectif")
		#savefig("img35-25-1.png")
		display(plt)  # Affiche le graphique
	end
end