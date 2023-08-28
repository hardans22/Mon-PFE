include("RelaxAndFix _ FixAndOptimize.jl")


function restart(model, current_pop, instance_dict,len_pop)
    #=
        On fait les quatre type de mutation sur la 
        meilleure solution obtenu jusque là. 
    =#
    t = instance_dict["t"]
    cmax = instance_dict["cmax"]
    alpha = instance_dict["alpha"]
    rst = true
    new_pop =[]
    #Mutation sur la meilleure solution obtenue
    list_rd = [0.2, 0.5, 0.7, 0.95]
    nbr = div(len_pop, 20)
    for i in 1:nbr
        for sol in current_pop[1:5]
            for rd in list_rd
                fils_z, fils_y = mutation(sol,instance_dict,rst,rd)
                fils_c = construct_capacities(fils_z, t, alpha, cmax) 
                result_sol, model = evaluation(model,fils_y,fils_z,fils_c,instance_dict)
                fils_sol = create_solution(result_sol)
                if !sol_in_list(new_pop, fils_sol)  
                    push!(new_pop, fils_sol)
                end
            end
        end
    end
    return new_pop, model
end

function restart2(model, best_sol, instance_dict, len_pop)
    #=
        Régénérer àléatoirement la matrice y et le combiner 
        avec le vecteur z de la meilleure solution
        
        Pour les tests, elle remonte tres haut pour la fonction 
        objective
    =#
    P = instance_dict["P"]
    T = instance_dict["T"]
    p = instance_dict["p"]
    t = instance_dict["t"]
    mtn_cost = instance_dict["mtn_cost"]
    set_up_cost = instance_dict["set_up_cost"]
    
    z = best_sol.z
    c = best_sol.c
    compt_y = 1
    new_pop = []
    feasibility = true
    while feasibility
        y = zeros(Int64, p,t)
        for item in P
            line = vcat(ones(Int64, t-compt_y), zeros(Int64, compt_y))
            shuffle!(line)
            y[item, :] = line
        end
        y[:,1] = [1 for _ in P]
        compt_y += 1 

        clsp_sol = resolve_CLSP(model,y,c,instance_dict)
        model, x, I, u, clsp_obj = clsp_sol["model"], clsp_sol["x"], clsp_sol["I"], clsp_sol["u"], clsp_sol["clsp_obj"]
        if sum(u) > 0
            feasibility = false
        else
            feasibility = true
        end 
    end
    compt_y -= 1
    for i in 1:len_pop
        y = zeros(Int64, p,t)
        for item in P
            line = vcat(ones(Int64, t-compt_y), zeros(Int64, compt_y))
            shuffle!(line)
            y[item, :] = line
        end
        y[:,1] = [1 for _ in P]
        clsp_sol = resolve_CLSP(model,y,c,instance_dict)
        model, x, I, u, clsp_obj = clsp_sol["model"], clsp_sol["x"], clsp_sol["I"], clsp_sol["u"], clsp_sol["clsp_obj"]
        sol_obj = clsp_obj + sum(set_up_cost .* y) + dot(mtn_cost,z)
        push!(new_pop, solution(x,I,y,z,c,u,sol_obj));
    end
    return new_pop, model
end

function new_restart(current_pop, windowSize, windowType, overlap, instance_dict)
    #=
        On utilise de du relax and fix pour le restart 
    =#
    T = instance_dict["T"]
    len = length(current_pop)
    sol = current_pop[1]
    sz = sol.z
    sc = sol.c
    model = buildM(sz, sc, instance_dict, "RF")
    new_pop = []
    for sol in current_pop
        sz = sol.z
        sc = sol.c
        mtnCost = dot(mtn_cost, sz)
        c4 = model[:c4]
        for t in T
            set_normalized_rhs(c4[t], sc[t])
        end
        result = RelaxAndFix(model, windowSize, windowType, overlap, instance_dict)
        result["obj"] += mtnCost
        result["sz"] = sz
        result["sc"] = sc 
        new_sol = create_solution(result)
        push!(new_pop, new_sol)
    end
    return new_pop
end 
