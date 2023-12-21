
include("./genetic_algorithm.jl")
include("../RFFO/RelaxAndFix _ FixAndOptimize_Zt.jl")

function AG_FO(len_pop, nbr_iter, foSize, foStep,instance_dict)

	println("\nALGORITHME GÉNÉTIQUE")
	begin_time = time()
	@time result =  genetic_algorithm(instance_dict, len_pop,nbr_iter)   
	ag_timeElapsed = round(time() - begin_time, digits = 4)

	best_sol = result["best_sol"]
	println(best_sol.obj)
	println(sum(best_sol.z))
	l = []
	sz = best_sol.z
	sc = best_sol.c
	sy = best_sol.y
	su = best_sol.u
	println("Feasibility of solution : ", verify_solution(best_sol.x, best_sol.I, sy, sz, sc, instance_dict))
	#println("Maintenance : ",sz)
	#println("Surplus : ",su) 
	#println("Matrice des setup : ")
	#display(sy)
	
	println("\nFIX AND OPTIMIZE")
	
	fomodel = buildM(instance_dict, "FO")
	begin_time = time()
	@time result_fo = FixAndOptimize(fomodel, sy, sz, foSize, foStep, instance_dict) 
	fo_timeElapsed = round(time() - begin_time, digits = 4)
    sx = result_fo["sx"]
	sI = result_fo["sI"]
	sy = result_fo["sy"]
	su = result_fo["su"]
	sz = result_fo["sz"]
	sc = result_fo["sc"]
	fo_obj = round(result_fo["obj"], digits  = 2)
	println("OBJECTIF =  ", fo_obj)
	println("Feasibility of solution : ", verify_solution(sx, sI, sy, sz, sc, instance_dict))
	#println("Maintenance : ",sz)
	#println("Surplus : ",su) 

	return create_solution(result_fo), ag_timeElapsed, fo_timeElapsed
end 

