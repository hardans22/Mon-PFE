using LinearAlgebra
include("./functions.jl")
include("./model.jl")


function generate_pop_initial(len_pop,instance_dict)
    P = instance_dict["P"]
    T = instance_dict["T"]
    p = instance_dict["p"]
    t = instance_dict["t"]
    alpha = instance_dict["alpha"]
    cmax = instance_dict["cmax"]
    mtn_cost = instance_dict["mtn_cost"]
    set_up_cost = instance_dict["set_up_cost"]
    pop_initial_list = []

    clsp_obj = 0
    
    
    feasibility = true
    c_prime = 0
    compt = 1
    model = build_model(instance_dict)
    while feasibility
        #println(nbr_mtn)
        temp = vcat(ones(Int64, t-1-compt), zeros(Int64, compt))
        shuffle!(temp)
        z = vcat([1], temp)
        #z[1] = 1
        
        c = construct_capacities(z, t, alpha, cmax)

        y = zeros(Int64, p,t)
        for item in P
            line = vcat(ones(Int64, t-1-compt), zeros(Int64, compt))
            shuffle!(line)
            y[item, :] = vcat([1], line)
        end
        #y[:,1] = [1 for _ in P]
        compt += 1 

        clsp_sol = resolve_CLSP(model,y,c,instance_dict)
        model, x, I, u, clsp_obj = clsp_sol["model"], clsp_sol["x"], clsp_sol["I"], clsp_sol["u"], clsp_sol["clsp_obj"]
        if sum(u) > 0
            feasibility = false
        else
            feasibility = true
        end 
    end
    compt -= 1
    for i in 1:len_pop
        #println("------------------", i, "--------------------")
        temp = vcat(ones(Int64, t-1-compt), zeros(Int64, compt))
        shuffle!(temp)
        z = vcat([1], temp)
        #z[1] = 1
        
        c = construct_capacities(z, t, alpha, cmax)

        y = zeros(Int64, p,t)
        for item in P
            line = vcat(ones(Int64, t-1-compt), zeros(Int64, compt))
            shuffle!(line)
            y[item, :] = vcat([1],line)
        end
        #y[:,1] = [1 for _ in P]
        clsp_sol = resolve_CLSP(model,y,c,instance_dict)
        model, x, I, u, clsp_obj = clsp_sol["model"], clsp_sol["x"], clsp_sol["I"], clsp_sol["u"], clsp_sol["clsp_obj"]
        sol_obj = clsp_obj + sum(set_up_cost .* y) + dot(mtn_cost,z)
        push!(pop_initial_list, solution(x,I,y,z,c,u,sol_obj));
    end
    return pop_initial_list, model
end 
