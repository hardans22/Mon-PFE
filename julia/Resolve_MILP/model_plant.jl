using JuMP, CPLEX, Gurobi

function model_mip_zkt(instance_dict)
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
    
    model = Model(optimizer_with_attributes(Gurobi.Optimizer, "Threads" => 1))
    
    @variable(model, 0 <= x[i in P, k in T, t in k:len_T])
    @variable(model, 0 <= c[T])

   
    @variable(model, 0 <= c[T])

    @variable(model, 0 <= y[P,T] <= 1, Bin)
    @variable(model, 0 <= z[k in T, t in k:len_T] <=1, Bin)

    
    @constraint(model, c1[i in P, t in T], sum(x[i,k,t] for k in 1:t) == demand[i,t])
    
    @constraint(model, c2[i in P, k in T, t in k:len_T], x[i,k,t] <= demand[i,t]*y[i,k])
    
    @constraint(model, c3[t in T], sum(x[i,t,j] for i in P, j in t:len_T) <= c[t])
   
    @constraint(model, c4[k in T, t in k+1:len_T], z[k,t] <= z[k,k])
    @constraint(model, c5[t in T], c[t] <= cmax*(sum(alpha^(t-k)*z[k,t] for k in 1:t)))
    @constraint(model, c6[t in T], sum(z[k,t] for k in 1:t) <= 1)
    
    @objective(model, Min, sum(sum(holding_cost[i,j] for j in k:t-1) * x[i,k,t] for i in P, k in T, t in k:len_T) + sum(variable_prod_cost[i,k]*x[i,k,t] for i in P, k in T, t in k:len_T) + sum(set_up_cost[i,t]*y[i,t] for i in P, t in T) + sum(mtn_cost[t]*z[t,t] for t in T))
    set_silent(model)
    set_time_limit_sec(model, 7200.0)
    JuMP.optimize!(model)
    obj = objective_value(model)
    sx = JuMP.value.(x) 
    sy = JuMP.value.(y)
    sz = JuMP.value.(z)
    sc = JuMP.value.(c)
    gap = relative_gap(model)*100
    nbr_nodes =  MOI.get(model, MOI.NodeCount())
    dual_obj = objective_bound(model)
     #=
    for i in P
        println(sum(sy[i,:]))
    end
    =# 
    nbr_set_up = []
    #println("\nMILP_obj = ", obj)
    time = solve_time(model)
    #println("Temps de résolution MILP = ", time, "s")
    
    return Dict("obj" => obj, "z" => sz, "c" => sc, "y" => sy, "x" => sx, "time" => time, "gap" => gap, "nbr_nodes" => nbr_nodes, "dual_obj" => dual_obj)
end




function model_mip_zt(instance_dict, pl = false)
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
    
    model = Model(optimizer_with_attributes(Gurobi.Optimizer))
    @variable(model, 0 <= x[i in P, k in T, t in k:len_T])
    @variable(model, 0 <= c[T])

   
    @variable(model, 0 <= y[P,T] <= 1, Bin)
    @variable(model, 0 <= z[T] <=1, Bin)
    
    @constraint(model, c1[i in P, t in T], sum(x[i,k,t] for k in 1:t) == demand[i,t])
    
    @constraint(model, c2[i in P, k in T, t in k:len_T], x[i,k,t] <= demand[i,t]*y[i,k])
    
    @constraint(model, c3[t in T], sum(x[i,t,j] for i in P, j in t:len_T) <= c[t])

    
    @constraint(model, c4[t in T], c[t] <= cmax)
    @constraint(model, z[1] == 1)
    @constraint(model, c5[t in 2:len_T], c[t] <= alpha*c[t-1] + cmax*z[t])

    @objective(model, Min, sum(sum(holding_cost[i,j] for j in k:t-1) * x[i,k,t] for i in P, k in T, t in k:len_T) + sum(variable_prod_cost[i,k]*x[i,k,t] for i in P, k in T, t in k:len_T) + sum(set_up_cost[i,t]*y[i,t] for i in P, t in T) + sum(mtn_cost[t]*z[t] for t in T))
    set_silent(model)
    set_time_limit_sec(model, 7200.0)
    JuMP.optimize!(model)
    obj = objective_value(model)
    sx = JuMP.value.(x)
    sy = JuMP.value.(y)
    sz = JuMP.value.(z)
    sc = JuMP.value.(c)
    gap = relative_gap(model)*100
    nbr_nodes =  MOI.get(model, MOI.NodeCount())
    dual_obj = objective_bound(model)

     #=
    for i in P
        println(sum(sy[i,:]))
    end
    =# 
    nbr_set_up = []
    #println("\nMILP_obj = ", obj)
    time = solve_time(model)
    #println("Temps de résolution MILP = ", time, "s")
    
    return Dict("obj" => obj, "z" => sz, "c" => sc, "y" => sy, "x" => sx, "time" => time, "gap" => gap, "nbr_nodes" => nbr_nodes, "dual_obj" => dual_obj)
end
