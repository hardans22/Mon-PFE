
include("./genetic_algorithm.jl")
include("RelaxAndFix _ FixAndOptimize3.jl")

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

function RF_IFO(rfSize, rfOverlap, foSize, foStep,instance_dict )    p = instance_dict["p"]
    t = instance_dict["t"]

    println("\nRELAX AND FIX ")
    rfmodel = buildM(instance_dict,"RF")
    windowType = 0
    @time result_rf = RelaxAndFix(rfmodel, rfSize, windowType,  rfOverlap, instance_dict)
    sol = create_solution(result_rf)
    sx = sol.x
	sI = sol.I
	sy = sol.y
	su = sol.u
	sz = sol.z
    sc = sol.c
    println(sum(sz))
	println("OBJECTIF =  ", sol.obj)
	println("Feasibility of solution : ", verify_solution(sx, sI, sy, sz, sc, instance_dict))
	println("Maintenance : ",sz)
	println("Surplus : ",su) 
    l = []
	for i in 1:p
		push!(l, sum(sy[i,:]))
	end
	println(l)
    
    println("\nITERATED FIX AND OPTIMIZE ")

    sol = IFO(sol, foSize, foStep, instance_dict )
    
    sx = sol.x
	sI = sol.I
	sy = sol.y
	su = sol.u
	sz = sol.z
    sc = sol.c
    obj = sol.obj
    println(sum(sz))
	println("OBJECTIF =  ", obj)
	println("Feasibility of solution : ", verify_solution(sx, sI, sy, sz, sc, instance_dict))
	println("Maintenance : ",sz)
	println("Surplus : ",su) 
    l = []
	for i in 1:p
		push!(l, sum(sy[i,:]))
	end
	println(l)
    
    println("OBJECTIF = ", obj)
    
    return sol
end