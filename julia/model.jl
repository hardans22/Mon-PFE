using JuMP, CPLEX, Gurobi

function model_mip(instance_dict, pl = false)
    P = instance_dict["P"]
    T = instance_dict["T"]
    len_T = instance_dict["t"]
    len_P = instance_dict["p"]
    set_up_cost = instance_dict["set_up_cost"]
    variable_prod_cost = instance_dict["variable_prod_cost"]
    holding_cost = instance_dict["holding_cost"]
    mtn_cost = instance_dict["mtn_cost"]
    demand = instance_dict["demand"]
    alpha = instance_dict["alpha"]
    cmax = instance_dict["cmax"]
    
    model = Model(Gurobi.Optimizer)
    @variable(model, 0 <= x[P,T])
    @variable(model, 0 <= I[P,T])
    @variable(model, 0 <= c[T])
    if pl
        @variable(model, 0 <= y[P,T] <= 1)
        @variable(model, 0 <= z[T] <=1)
    else
        @variable(model, 0 <= y[P,T] <= 1, Bin)
        #@variable(model, 0 <= z[T] <=1, Bin)
        @variable(model, 0 <= z[i in T, j in i:len_T] <=1, Bin)
    end
    
    @constraint(model, c1[i in P], x[i,1] - I[i,1] == demand[i,1])
    
    @constraint(model, c2[i in P, t in 2:len_T], x[i,t] + I[i,t-1] - I[i,t] == demand[i,t])
    
    @constraint(model, c3[i in P, t in T], x[i,t] <= (sum(demand[i,s] for s in t:len_T))*y[i,t])
    
    @constraint(model, c4[t in T], sum(x[i,t] for i in P) <= c[t])
    
    #@constraint(model, c5[t in T], c[t] <= cmax)
    #@constraint(model, z[1] == 1)
    #@constraint(model, c6[t in 2:len_T], c[t] <= alpha*c[t-1] + cmax*z[t])
   
    @constraint(model, c5[k in T, t in k+1:len_T], z[k,t] <= z[k,k])
    @constraint(model, c6[t in T], c[t] <= cmax*(sum(alpha^(t-k)*z[k,t] for k in 1:t)))
    @constraint(model, c7[t in T], sum(z[k,t] for k in 1:t) <= 1)
    
    
    @objective(model, Min, sum(set_up_cost[i,t]*y[i,t] + variable_prod_cost[i,t]*x[i,t] + holding_cost[i,t]*I[i,t] for i in P, t in T) + sum(mtn_cost[t]*z[t,t] for t in T))
    #set_silent(model)
    set_time_limit_sec(model, 3600.0)
    JuMP.optimize!(model)
    obj = objective_value(model)
    sx = JuMP.value.(x)
    sI = JuMP.value.(I)
    sy = JuMP.value.(y)
    sz = JuMP.value.(z)
    sc = JuMP.value.(c)
     #=
    for i in P
        println(sum(sy[i,:]))
    end
    =# 
    nbr_set_up = []
    println("\nMILP_obj = ", obj)
    println("Temps de résolution MILP = ", solve_time(model), "s")
    
    return Dict("obj" => obj, "z" => sz, "c" => sc, "y" => sy, "x" => sx, "I" => sI)
end


function build_model(instance_dict)
    P = instance_dict["P"]
    T = instance_dict["T"]
    len_T = instance_dict["t"]
    len_P = instance_dict["p"]
    demand = instance_dict["demand"]
    variable_prod_cost = instance_dict["variable_prod_cost"]
    holding_cost = instance_dict["holding_cost"]
    mtn_cost = instance_dict["mtn_cost"]
    model = Model(CPLEX.Optimizer)
    cmax = instance_dict["cmax"]
    #=
    c_prime = 0
    coeff = maximum(mtn_cost)/(len_T)
    beta = coeff
    alpha = coeff/2
    model[:z_prime] = @variable(model, 0 <= z_prime)
    model[:z] = @variable(model, 0 <= z)
    =#
    model[:x] = @variable(model, 0 <= x[P,T])

    model[:I] = @variable(model, 0 <= I[P,T])
    
    model[:u] = @variable(model, 0<= u[T])
    
    @constraint(model, c1[i in P], x[i,1] - I[i,1] == demand[i,1])
    
    @constraint(model, c2[i in P, t in 2:len_T], x[i,t] + I[i,t-1] - I[i,t] == demand[i,t])

    model[:c3] = @constraint(model, c3[i in P, t in T], x[i,t] <= 1)

    model[:c4] = @constraint(model, c4[t in T], sum(x[i,t] for i in P) - u[t] <= 1)
    #=
    model[:c5] = @constraint(model, c5, sum(u[t] for t in T) -  z_prime  <= c_prime)
    
    @constraint(model, c6, z >= alpha*(sum(u[t] for t in T)) + beta*z_prime)
    =#

    obj = sum(variable_prod_cost[i,t]*x[i,t] + holding_cost[i,t]*I[i,t] for i in P, t in T)

    
    #coef = maximum(mtn_cost)/(len_T^2)
    coef = minimum([minimum(variable_prod_cost), minimum(holding_cost)])
    
    obj += sum(coef*u[t] for t in T)
    
    #obj += z

    @objective(model, Min, obj)
    
    return model
    
end

function resolve_CLSP(model,sy,sc,instance_dict)
    P = instance_dict["P"]
    T = instance_dict["T"]
    len_T = instance_dict["t"]
    variable_prod_cost = instance_dict["variable_prod_cost"]
    holding_cost = instance_dict["holding_cost"]
    demand = instance_dict["demand"]
    #Variables
    x = model[:x]
    I = model[:I]
    u = model[:u]
    #=
    z = model[:z]
    z_prime = model[:z_prime]
    c5 = model[:c5]
    =#
    #Contraintes
    c3 = model[:c3]
    c4 = model[:c4]
    #=
    for i in P
        temp = sum(demand[i,:])
        for t in T
            set_normalized_rhs(c3[i,t], temp*sy[i,t])
            temp -= demand[i,t]
        end 
    end

    for t in T 
        set_normalized_rhs(c4[t], sc[t])
    end
    =#
    for t in T
        for i in P
            temp = (sum(demand[i,s] for s in t:len_T))*sy[i,t]
            set_normalized_rhs(c3[i,t], temp)
        end 
        set_normalized_rhs(c4[t], sc[t])
    end 
    
    #set_normalized_rhs(c5, c_prime)
    
    #print(model)
    set_silent(model)
    JuMP.optimize!(model)

    su = JuMP.value.(u)
    sx = JuMP.value.(x)
    sI = JuMP.value.(I)
    #=
    z = JuMP.value(z)
    z_prime = JuMP.value(z_prime)
    =#
    clsp_obj = objective_value(model)
    return Dict("x" => sx, "I" => sI, "u" => su, "clsp_obj" => clsp_obj, "model" => model) 
    

end
