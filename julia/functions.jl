include("./model.jl")
using Random
mutable struct solution
    x :: Matrix{Float64}
    I :: Matrix{Float64}
    y :: Matrix{Int64}
    z :: Vector{Int}
    c :: Vector{Float64}
    u :: Vector{Float64}
    obj :: Float64
end 

#Les fonctions utilitaires
function construct_capacities(z, t, alpha, cmax)
    #Permet de construire le vecteur de capacité à partir d'un plan de maintenance
    c = zeros(Float64,t)
    for j in 1:t
        if z[j] ==1
            c[j] = cmax
        else
            c[j] = alpha*c[j-1]
        end
    end
    return c      
end 

function create_solution(model,y,z,c,instance_dict)
    #Créer un objet solution à partir de y,z et c
    mtn_cost = instance_dict["mtn_cost"]
    set_up_cost = instance_dict["set_up_cost"]
    clsp_sol = resolve_CLSP(model,y,c,instance_dict)
    model,x, I, u, clsp_obj = clsp_sol["model"], clsp_sol["x"], clsp_sol["I"],clsp_sol["u"], clsp_sol["clsp_obj"]
    set_up_mtn_costs = sum(set_up_cost .* y) + dot(mtn_cost,z)
    sol_obj = clsp_obj + set_up_mtn_costs
    fils_sol =  solution(x, I, y, z, c, u, sol_obj);
    return fils_sol, model
end


function copy_solution(sol)
    return solution(sol.x,sol.I,sol.y,sol.z,sol.c,sol.u,sol.obj)
end 

function sol_equal(sol1, sol2)
    if copy(sol1.z) == copy(sol1.z) && copy(sol1.y) == copy(sol2.y)
        return true
    else
        return false
    end 
end 

function print_pop(list_pop)
    l1 = []
    for sol in list_pop
        push!(l1,sol.obj)
    end
    println(l1)
    
end

function sol_in_list(list_pop, sol)
    for x in list_pop
        if sol.obj == x.obj
            return true
        end
    end
    return false
end 

function selection(list_pop, nbr)
    new_pop = []
    #indices = [i for i in 1:length(list_pop)]
    indices = randperm(length(list_pop))
    #println(indices)
    for i in 1:nbr
        shuffle!(indices)
        ind1, ind2 = indices[1], indices[2]
    
        if list_pop[ind1].obj < list_pop[ind2].obj
            indices = filter!(e->e!=ind1, indices)
            push!(new_pop, list_pop[ind1])
        else
            indices = filter!(e->e!=ind2, indices)
            push!(new_pop, list_pop[ind2])
        end
    end
    return new_pop
end

function verify_solution(x,I,y,z,c,instance_dict)
    P = instance_dict["P"]
    T = instance_dict["T"]
    demand = instance_dict["demand"]
    feasibility = true
    for t in T
        for i in P
            if t != 1
                println(x[i,t] + I[i,t-1] - demand[i,t] - I[i,t])
            end    
            if t!= 1 && !(x[i,t] + I[i,t-1] - demand[i,t] - I[i,t] <= 0.00005)
                return false
            end 
            if y[i,t] == 0 && x[i,t] > 0
                println("Production sans payé un coût de setup")
                return false 
            end 
        end
        if (sum(x[:,t]) - c[t]) > 0.0005 
            println("Production au-delà de la capacité ")
            return false 
        end 
    end 
    return true 
end 
 
function restart(model, best_sol, instance_dict,len_pop)
    t = instance_dict["t"]
    cmax = instance_dict["cmax"]
    alpha = instance_dict["alpha"]
    rst = true
    new_pop =[]
    #Mutation sur la meilleure solution obtenue
    list_rd = [0.2, 0.5, 0.7, 0.95]
    nbr = div(len_pop, 4)
    for i in 1:nbr
        for rd in list_rd
            fils_z, fils_y = mutation(best_sol,instance_dict,rst,rd)
            fils_c = construct_capacities(fils_z, t, alpha, cmax) 
            fils_sol, model = create_solution(model,fils_y,fils_z,fils_c,instance_dict) 
            if !sol_in_list(new_pop, fils_sol)  
                push!(new_pop, fils_sol)
            end
        end
    end
    return new_pop, model
end

function restart2(model, best_sol, instance_dict, len_pop)
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
