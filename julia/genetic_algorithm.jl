
include("./model.jl")
include("./generate_pop_initial.jl")
include("./crossover.jl")
include("./mutation.jl")
include("./functions.jl")
include("restart.jl")
include("RelaxAndFix _ FixAndOptimize.jl")


function genetic_algorithm(instance_dict,len_pop, timeAG)
    begin_time = time()
    P = instance_dict["P"] 
    T = instance_dict["T"]
    t = instance_dict["t"]
    p = instance_dict["p"]
    alpha = instance_dict["alpha"]
    cmax = instance_dict["cmax"]
    #println("--------------------------Itération 0 --------------------------")
    
    #Population initiale 
    
    current_pop, model = generate_pop_initial(len_pop,instance_dict)
    current_pop = sort(current_pop, by = x -> x.obj)
    best_sol = copy_solution(current_pop[1])

    #Les définitions
    best_sol_list, objectives, snd_objectives, trd_objectives = [], [], [], []

    stop = 10
    len_clonage = div(len_pop, 5)*3
    nbr_crossover = div(len_pop, 5)
    nbr_mutation = div(len_pop, 5)
    compt = 0

    nbr_fo = div(len_pop, 40)
    
    push!(objectives, best_sol.obj)
    push!(snd_objectives, current_pop[2].obj)
    push!(trd_objectives, current_pop[3].obj)
    #println(best_sol.obj)
    iter = 1

    while true
        #println("--------------------------Itération ", iter, " --------------------------")
        new_pop = []
        #println("c_prime = ", c_prime)
        new_pop = current_pop[1:len_clonage] 
        
        len_new_pop = len_clonage
        
        #println("CROSSOVER")
    
        cpt_cross = 0
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
                            cpt_cross +=1
                            push!(new_pop, fils_sol)
                        end
                    end
                end
            end
        end
        len_new_pop += cpt_cross
    
        #println("MUTATION")
        cpt_mut = 0
        indices = randperm(len_new_pop)
        for i in 1: nbr_mutation
            shuffle!(indices)
            if length(indices) != 0
                ind = indices[1]
                sol = new_pop[ind]
                temp = sum(sol.z)
                if temp > 1 || temp != 1 
                    fils_z, fils_y = mutation(sol,instance_dict, false, 0.1)
                    fils_c = construct_capacities(fils_z, t, alpha, cmax) 
                    result_sol, model = evaluation(model,fils_y,fils_z,fils_c,instance_dict)
                    fils_sol = create_solution(result_sol)
                    if !sol_in_list(new_pop, fils_sol)
                        cpt_mut +=1
                        push!(new_pop, fils_sol)
                    end
                end
                indices = filter!(e->e!=ind, indices)
            end
        end
        len_new_pop += cpt_mut
        

        #Mise à jour et trie de la population
        current_pop = new_pop
        current_pop = sort(current_pop, by = x -> x.obj)
        
        #Vérification et mise à jour de la meilleure solution
        if current_pop[1].obj < best_sol.obj
            compt = 0
            best_sol = copy_solution(current_pop[1])
        else
            compt += 1
        end
        push!(objectives, best_sol.obj)
        push!(snd_objectives, current_pop[2].obj)
        push!(trd_objectives, current_pop[3].obj)

        #Restart
        if compt == stop
            #println("RESTART")
            push!(best_sol_list, best_sol)
            current_pop, model = restart(model, best_sol, instance_dict, len_pop)
            current_pop = sort(current_pop, by = x -> x.obj)
            best_sol = copy_solution(current_pop[1])
            #stop += 5
            #print_pop(current_pop)   
        end
        
        #println()
        #println("best_sol = ",best_sol.obj)
        #println()
        #println("POPULATION")
        #print_pop(current_pop)
        #println(len_new_pop)
        #println(length(current_pop))
        #=
        if iter % 30 == 0
            nbr_crossover = round(nbr_crossover*1.3)
            nbr_mutation = round(nbr_mutation*1.3)
        end 
        =#
        if time() - begin_time > timeAG
            break
        end 
        iter += 1 

    end 
    #println("Nombre d'itération = ", iter)
    push!(best_sol_list, best_sol)
    #print_pop(best_sol_list)
    best_sol_list = sort(best_sol_list, by = x -> x.obj)
    best_sol = best_sol_list[1]
    
    return Dict("objectives" => objectives, "snd_objectives" => snd_objectives, "trd_objectives" => trd_objectives, "best_sol" => best_sol)
end
