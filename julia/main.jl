using JuMP, Random, PyCall, Profile

include("./methods.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 25
t = 15
cst = 17  #COÛT DE PÉNÉLISATION DES SOLUTIONS INFAISABLES
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
fosize = 5
fooverlap = 0.6 
slimit = 10
increment = 5
@time result2 =  AG_IFO(lpop, niter, fosize, fooverlap, slimit, increment, instance)
#=
wSize = 15
olap = 0.4
tLimit = 15

inc = 5
bSol1 = result2["best_sol"]
result3 = general_FO(bSol1, wSize, olap, tLimit, inc, instance)
=#

#version = 1
BestSolutions = []
for version in 1:1
	println("\n--------------------INSTANCE ", version, "------------------------\n")
	LesSolutions = [] 
	for run in 1:2
		println("----------------RUN ", run, "----------------")	
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
		nbr_iter = 200
		println("len_pop = ", len_pop)
		println("Nombre d'itération = ", nbr_iter)

		@time result =  genetic_algorithm(instance_dict, len_pop,nbr_iter)   

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
		
		foSize = 55
		foOverlap = 0.6
		sizeLimit = round(Int, p*t*0.9)
		inc = 10

		
		println("\nFIX AND OPTIMIZE")
		print("increment = ", inc, "\n \n")
		print("overlap = ", foOverlap, "\n \n")

		@time best_sol1 = IFO(best_sol, foSize, foOverlap, sizeLimit, inc, instance_dict )
		sx = best_sol1.x
		sI = best_sol1.I
		sy = best_sol1.y
		su = best_sol1.u
		obj = best_sol1.obj
		push!(LesSolutions, best_sol1)
		LesSolutions = sort(LesSolutions, by = x -> x.obj)
		
		println("Best solution = ", obj)
		println(sum(best_sol1.z))
		println("Feasibility of solution : ", verify_solution(sx, sI, sy, sz, sc, instance_dict))
		println("Maintenance : ",sz)
		println("Surplus : ",su) 
		#println("Matrice des setup : ")
		#display(sy)
		for i in 1:p
			push!(l, sum(sy[i,:]))
		end
		println(l)

	end
	#push!(BestSolutions, LesSolutions[1])

end
println("\n")
#print_pop(BestSolutions)
