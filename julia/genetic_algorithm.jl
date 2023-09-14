
include("./model.jl")
include("./generate_pop_initial.jl")
include("./crossover.jl")
include("./mutation.jl")
include("./functions.jl")
include("restart.jl")
include("RelaxAndFix _ FixAndOptimize.jl")


function genetic_algorithm(instance_dict,len_pop, nbr_iteration)
    begin_time = time()
    P = instance_dict["P"] 
    T = instance_dict["T"]
    t = instance_dict["t"]
    p = instance_dict["p"]
    alpha = instance_dict["alpha"]
    cmax = instance_dict["cmax"]
    mtn_cost = instance_dict["mtn_cost"]
    
    #println("--------------------------Itération 0 --------------------------")
    
    #Population initiale 
    
    current_pop, model = generate_pop_initial(len_pop,instance_dict)
    current_pop = sort(current_pop, by = x -> x.obj)
    cbest_sol = copy_solution(current_pop[1])
    best_sol = copy_solution(cbest_sol)
    

    #Les définitions
    best_sol_list, objectives, snd_objectives, trd_objectives = [], [], [], []

    stop = 50
    len_clonage = round(Int, len_pop*0.2)
    nbr_crossover = round(Int, (len_pop*0.4)/4)
    nbr_mutation = round(Int, len_pop*0.4)
    compt = 0

    push!(objectives, cbest_sol.obj)
    push!(snd_objectives, current_pop[2].obj)
    push!(trd_objectives, current_pop[3].obj)
    

    for iter in 1:nbr_iteration
        #println("--------------------------Itération ", iter, " --------------------------")
        new_pop = []
        #println("c_prime = ", c_prime)
        new_pop = current_pop[1:len_clonage] 
        
        #println("CROSSOVER")

        for i in 1:nbr_crossover
            #println("Crossover : ", i)
            ind = randperm(len_clonage)[1:2]
            shuffle!(ind)
            sol1 = new_pop[ind[1]]
            sol2 = new_pop[ind[2]]
            
            if !sol_equal(sol1,sol2)
                list_fils_z, list_fils_y = crossover(sol1, sol2, instance_dict)
                for fils_z in list_fils_z
                    fils_c = construct_capacities(fils_z, t, alpha, cmax)  
                    for fils_y in list_fils_y
                        result_sol, model =  evaluation(model,fils_y,fils_z,fils_c,instance_dict)
                        fils_sol = create_solution(result_sol)
                        if !sol_in_list(new_pop, fils_sol)
                            push!(new_pop, fils_sol)
                        end
                    end
                end
            end
        end
    
        #println("MUTATION")
        indices = randperm(len_clonage)
        for i in 1: nbr_mutation
            shuffle!(indices)
            if length(indices) != 0
                ind = indices[1]
                sol = new_pop[ind]
                fils_z, fils_y = mutation(sol,instance_dict)
                fils_c = construct_capacities(fils_z, t, alpha, cmax) 
                result_sol, model = evaluation(model,fils_y,fils_z,fils_c,instance_dict)
                fils_sol = create_solution(result_sol)
                if !sol_in_list(new_pop, fils_sol)
                    push!(new_pop, fils_sol)
                end
            end
        end


        #Mise à jour et trie de la population
        current_pop = new_pop
        current_pop = sort(current_pop, by = x -> x.obj)
        
        #Vérification et mise à jour de la meilleure solution
        if current_pop[1].obj < cbest_sol.obj
            compt = 0
            cbest_sol = copy_solution(current_pop[1])
        else
            compt += 1
        end

        if cbest_sol.obj < best_sol.obj
            best_sol = copy_solution(cbest_sol)
        end 

        push!(objectives, cbest_sol.obj)
        push!(snd_objectives, current_pop[2].obj)
        push!(trd_objectives, current_pop[3].obj)

        #Restart
        if compt == stop
            #println("COMPT = ", compt)
            #println("RESTART")
            current_pop, model = generate_pop_initial(len_pop,instance_dict)
            #print_pop(current_pop)
            current_pop = sort(current_pop, by = x -> x.obj)
            cbest_sol = copy_solution(current_pop[1])
    
            compt = 0
        end
        
        #println()
        #println("cbest_sol = ", cbest_sol.obj)
        #println("best_sol = ", best_sol.obj)
        #println("mtn = ", sum(best_sol.z))


        #println()
        #println("POPULATION")
        #print_pop(current_pop)
        #println(len_new_pop)
        #println(length(current_pop))

    end
    
    return Dict("objectives" => objectives, "snd_objectives" => snd_objectives, "trd_objectives" => trd_objectives, "best_sol" => best_sol)
end
