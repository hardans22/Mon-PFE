
include("./model.jl")
include("./generate_pop_initial.jl")
include("./crossover.jl")
include("./mutation.jl")
include("./functions.jl")


function genetic_algorithm(instance_dict,len_pop, nbr_iteration,rst)
    P = instance_dict["P"] 
    T = instance_dict["T"]
    t = instance_dict["t"]
    p = instance_dict["p"]
    alpha = instance_dict["alpha"]
    cmax = instance_dict["cmax"]
    println("--------------------------Itération 0 --------------------------")
    @time begin
        current_pop, model = generate_pop_initial(len_pop,instance_dict)
    end
    best_sol_list = []
    objectives = []
    snd_objectives = []
    trd_objectives = []
    current_pop = sort(current_pop, by = x -> x.obj)
     
    best_sol = copy_solution(current_pop[1])
    stop = 15
    #println("POPULATION")
    #print_pop(current_pop)
    
    push!(objectives, best_sol.obj)
    push!(snd_objectives, current_pop[2].obj)
    push!(trd_objectives, current_pop[3].obj)
    println(best_sol.obj)
    compt = 0
    it = 1

    len_clonage = div(len_pop, 3)*2
    nbr_crossover = div(len_pop, 3)
    nbr_mutation = div(len_pop, 3)
    #c_prime = nbr_iteration
    for iter in 1:nbr_iteration
        println("--------------------------Itération ", iter, " --------------------------")
        new_pop = []
        #println("c_prime = ", c_prime)
        new_pop = current_pop[1:len_clonage] 
        
        #new_pop = selection(current_pop, len_clonage) 
        
        len_new_pop = len_clonage
        
        println("CROSSOVER")
        @time begin
            compt_fils = 0
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
                            fils_sol, model = create_solution(model,fils_y,fils_z,fils_c,instance_dict)
                            if !sol_in_list(new_pop, fils_sol)
                                compt_fils +=1
                                push!(new_pop, fils_sol)
                            end
                        end
                    end
                end
            end
        end
        println("MUTATION")
        cpt = 0
        @time begin
            len_new_pop += compt_fils
            indices = randperm(len_new_pop)
            for i in 1: nbr_mutation
                shuffle!(indices)
                ind = indices[1]
                sol = new_pop[ind]
                temp = sum(sol.z)
                if temp > 1 || temp != 1 
                    fils_z, fils_y = mutation(sol,instance_dict, false, 0.1)
                    fils_c = construct_capacities(fils_z, t, alpha, cmax) 
                    fils_sol, model = create_solution(model,fils_y,fils_z,fils_c,instance_dict)
                    if !sol_in_list(new_pop, fils_sol)
                        cpt +=1
                        push!(new_pop, fils_sol)
                    end
                end
                indices = filter!(e->e!=ind, indices)
            end
        end  
        len_new_pop += cpt
        current_pop = new_pop
        #current_pop = unique(new_pop, sol_equal)
        current_pop = sort(current_pop, by = x -> x.obj)
        
        if current_pop[1].obj < best_sol.obj
            compt = 0
            best_sol = copy_solution(current_pop[1])
        else
            compt += 1
        end
        if compt == stop
            if rst
                println("RESTART")
                push!(best_sol_list, best_sol)
                #current_pop, model = generate_pop_initial2(len_pop, instance_dict)
                current_pop, model = restart(model, best_sol, instance_dict, len_pop)
                #current_pop, model = restart2(model, best_sol, instance_dict, len_pop)
                current_pop = sort(current_pop, by = x -> x.obj)
                best_sol = copy_solution(current_pop[1])
                stop += 5
                print_pop(current_pop)
                len_clonage = div(len_pop, 3)*2
                nbr_crossover = div(len_pop, 3)
                nbr_mutation = div(len_pop, 3) 
            else 
                break
            end    
        end
        it += 1 
        push!(objectives, best_sol.obj)
        push!(snd_objectives, current_pop[2].obj)
        push!(trd_objectives, current_pop[3].obj)

        #println([x.obj for x in current_pop])
        println()
        println("best_sol = ",best_sol.obj)
        println()
        #println("POPULATION")
        #print_pop(current_pop)
        #println(len_new_pop)
        #println(length(current_pop))
        
        
        if iter % 50 == 0
            nbr_crossover = round(nbr_crossover*0.9)
            nbr_mutation = round(nbr_mutation*0.9)
        end 
        
        #print(model)
        #=
        if c_prime > 0.05
            c_prime *= 0.9
        else
            c_prime = 0
        end
        =# 
    end 
    #println("Nombre d'itération = ", it)
    push!(best_sol_list, best_sol)
    print_pop(best_sol_list)
    best_sol_list = sort(best_sol_list, by = x -> x.obj)
    best_sol = best_sol_list[1]
    return Dict("objectives" => objectives, "snd_objectives" => snd_objectives, "trd_objectives" => trd_objectives, "best_sol" => best_sol)
end
