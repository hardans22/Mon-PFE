
include("./genetic_algorithm.jl")
include("RelaxAndFix _ FixAndOptimize2.jl")

function AG_IFO(len_pop, nbr_iter, foSize, foOverlap,sizeLimit, inc, instance_dict)

	println("\nALGORITHME GÉNÉTIQUE")
	@time result =  genetic_algorithm(instance_dict, len_pop,nbr_iter)   

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
	
	println("\nITERATED FIX AND OPTIMIZE")
	sol = IFO(best_sol, foSize, foOverlap, sizeLimit, inc, instance_dict )
    
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

end 

function RF_IFO(rfSize, rfOverlap, foSize, foOverlap, inc, sizeLimit,instance_dict )
    p = instance_dict["p"]
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

    sol = IFO(sol, foSize, foOverlap, sizeLimit, inc, instance_dict )
    
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