using JuMP, Gurobi, CPLEX, LinearAlgebra
include("functions.jl")

function initWindow(windowType, instance_dict)
    p = instance_dict["p"] + 1
    P = 1:p
    T = instance_dict["T"]
    
    if windowType == 0
        sol_window = [(i,t) for i in P for t in T]
    elseif windowType == 1
        sol_window = [(i,t) for t in T for i in P]
    end 
    return sol_window
end 

function croissant_holding_cost(x::Tuple, y::Tuple, set_up_cost)
    x_i, x_t = x[1]-1, x[2]
    y_i, y_t = y[1]-1, y[2]
    return set_up_cost[x_i,x_t] > set_up_cost[y_i,y_t]
end

function order_variable(sol_window, instance_dict)
    t = instance_dict["t"]
    set_up_cost = instance_dict["set_up_cost"]
    temp = sol_window[1:t]
    sol_w = sort(sol_window[t+1:end], lt = (x, y) -> croissant_holding_cost(x, y, set_up_cost))
    sol_window = vcat(temp, sol_w)
    return sol_window
end 

function buildM(instance_dict,rf_or_fo)
    P = instance_dict["P"]
    T = instance_dict["T"]
    len_T = instance_dict["t"]
    len_P = instance_dict["p"]
    demand = instance_dict["demand"]
    variable_prod_cost = instance_dict["variable_prod_cost"]
    holding_cost = instance_dict["holding_cost"]
    set_up_cost = instance_dict["set_up_cost"]
    mtn_cost = instance_dict["mtn_cost"]
    alpha = instance_dict["alpha"]
    cmax = instance_dict["cmax"]

    model = Model(optimizer_with_attributes(Gurobi.Optimizer, "Threads" => 1))
    #model = Model(CPLEX.Optimizer)
    #set_optimizer_attribute(model, "CPXPARAM_Threads", 1)

    #Les vaiables

    model[:x] = @variable(model, 0 <= x[P,T])

    model[:I] = @variable(model, 0 <= I[P,T])

    model[:c] = @variable(model, 0 <= c[T])

    model[:u] = @variable(model, 0 <= u[T])


    if rf_or_fo == "RF"
        model[:y] = @variable(model, 0 <= y[P,T] <= 1)
        model[:z] = @variable(model, 0 <= z[T] <= 1)
    elseif rf_or_fo == "FO"
        model[:y] = @variable(model, 0 <= y[P,T], Bin)
        model[:z] = @variable(model, 0 <= z[T], Bin)
    end

    #Les contraintes

    @constraint(model, c1[i in P], x[i,1] - I[i,1] == demand[i,1])
    
    @constraint(model, c2[i in P, t in 2:len_T], x[i,t] + I[i,t-1] - I[i,t] == demand[i,t])
    
    @constraint(model, c3[i in P, t in T], x[i,t] <= (sum(demand[i,s] for s in t:len_T))*y[i,t])

    model[:c4] = @constraint(model, c4[t in T], sum(x[i,t] for i in P) - u[t] <= c[t])
    
    @constraint(model, c5[t in T], c[t] <= cmax)
    @constraint(model, z[1] == 1)
    
    @constraint(model, c6[t in 2:len_T], c[t] <= alpha*c[t-1] + cmax*z[t])
   
    #objective
    obj = sum(set_up_cost .* y + variable_prod_cost .*x + holding_cost .*I) + dot(mtn_cost, z) 
    coef = sum(mtn_cost)/(len_T)
    obj += sum(coef*u[t] for t in T)

    @objective(model, Min, obj)
    
    return model
end


function solve_model(model, w_fix, w_mip, sy, sz, rf_or_fo)
    x = model[:x]
    I = model[:I]
    y = model[:y]
    z = model[:z]
    c = model[:c]
    u = model[:u]

    cts = []
    for elt in w_fix
        i, t = elt[1], elt[2]
        if i == 1
            ct = @constraint(model, z[t] == sz[t])
        else
            ct = @constraint(model, y[i-1,t] == sy[i-1,t])
        end
        push!(cts,ct)
    end
    
    if rf_or_fo == "RF"
        for elt in w_mip 
            i, t = elt[1], elt[2]
            if i == 1
                set_binary(z[t])
            else
                set_binary(y[i-1,t])
            end
        end 
    end
    
    set_silent(model)
    JuMP.optimize!(model)
    
    obj = objective_value(model)

    sx = round.(JuMP.value.(x), digits = 3)
    sI = round.(JuMP.value.(I), digits = 3)
    sy = round.(JuMP.value.(y), digits = 3)
    sz = round.(JuMP.value.(z), digits = 3)
    sc = round.(JuMP.value.(c), digits = 3)
    su = round.(JuMP.value.(u), digits = 3)
    
    if rf_or_fo == "FO"
        for ct in cts
            delete(model, ct)
        end
    end 

    return Dict("obj" => obj, "sx" => sx, "sI" => sI, "sy" => sy, "sz" => sz, "sc" => sc, "su" => su, "model" => model)
end


function RelaxAndFix(mdl, foSize, windowType, overlap, instance_dict)
    begin_time = time()
    t = instance_dict["t"]
    p = instance_dict["p"]
    #Résolution du problème linéaire avec y continue
    set_silent(mdl)
    JuMP.optimize!(mdl)
    y = mdl[:y]
    z = mdl[:z]
    sy = JuMP.value.(y)
    sz = JuMP.value.(z)
    #display(sy)

    curseur = 0
    step = overlap*foSize
    #println("step = ", step)

    #Initialisation de l'ensemble de toutes les cases de la matrices selon l'orientation choisi (windowType)
    sol_window = initWindow(windowType, instance_dict)
    #println(sol_window)
    #sol_window = order_variable(sol_window, instance_dict)
    #println(sol_window)

    window = sol_window[1:foSize]
    w_fix = [] #Ensemble de variables fixé
    w_mip = window
    w_lp = [elt for elt in sol_window if !(elt in window)]
    rf_or_fo = "RF"
    iter = 0
    while true
        #println("YYYYYYYYYYYYYYYYYYEEEEEEEEEEEEEEEEEESSSSSSSSSSSSSSS")
        iter+=1
        #println("\t\t-------------------Itération ", iter, "--------------------")
        #=
        println("window : ", length(window))
        println("w_fix : ", length(w_fix))
        println("w_mip : ", length(w_mip))
        println("w_lp : ", length(w_lp))
        =#
        result = solve_model(mdl, w_fix, w_mip, sy, sz, rf_or_fo)
        sy = result["sy"]
        sz = result["sz"]
        sc = result["sc"]
        mdl = result["model"]
        #display(sy)
        curseur += floor(Int64, step)

        if curseur + foSize <= t*p
            window = sol_window[curseur+1:(curseur+foSize)]
        else
            window = sol_window[curseur:end]
        end
            
        w_fix = vcat(w_fix, [elt for elt in w_mip if !(elt in window)])
        w_mip = window
        w_lp = [elt for elt in w_lp if !(elt in window)]
        obj = result["obj"]
        sx = result["sx"]
        sI = result["sI"]
        su = result["su"]
        #println("Objectif : ", obj)
        if all(isinteger, sy)
            return Dict("obj" => obj, "sx" => sx, "sI" => sI, "sy" => sy, "sz" => sz, "sc" => sc, "su" => su)
        end
    end
end


function FixAndOptimize(mdl, sol_y, sol_z, foSize, overlap, instance_dict)
    begin_time = time()
    t = instance_dict["t"]
    p = instance_dict["p"]
    #display(sol_y)
    sy = sol_y
    sz = sol_z
    sc = []
    sx, sI, su = [], [], []
    obj = 0
    
    step = overlap*foSize
    #println("step = ", step)

    rf_or_fo = "FO"
    windowType = 0
    for windowType in [0 1]
        #println("windowType = ", windowType)
        curseur = 0
        sol_window = initWindow(windowType, instance_dict)
        window = sol_window[1:foSize]
        w_mip = window
        w_fix = [elt for elt in sol_window if !(elt in window)]
        iter = 0
        while true
            iter+=1
            #println("\t-------------------Itération ", iter, "--------------------")
            #=
            println("window : ", window)
            println("w_fix : ", w_fix)
            println("w_mip : ", w_mip)
            =#          
            result = solve_model(mdl, w_fix, w_mip, sy, sz, rf_or_fo)
            sy = result["sy"]
            sz = result["sz"]
            sc = result["sc"]
            mdl = result["model"]
            #display(sy)
            
            curseur += floor(Int64, step)

            if curseur + foSize <= t*p
                window = sol_window[curseur+1:(curseur+foSize)]
            else
                window = sol_window[curseur:end]
            end

            w_mip = window
            w_fix = [elt for elt in sol_window if !(elt in window)]
            
            obj = result["obj"]
            sx = result["sx"]
            sI = result["sI"]
            su = result["su"]
            #println("\tObjectif : ", obj)

            if curseur + foSize >= t*p
                break
            end 
        end
        
    end
    return Dict("obj" => obj, "sx" => sx, "sI" => sI, "sy" => sy, "sz" => sz, "sc" => sc, "su" => su)
end 


function IFO(sol, foSize, foOverlap, sizeLimit, inc, instance_dict )
    p = instance_dict["p"]
    t = instance_dict["t"]
    begin_time = time()
    sz = sol.z
    sc = sol.c
    sy = sol.y
    prev_cost = sol.obj

    begin_time = time()
    fomodel = buildM(instance_dict,"FO")
    mtn_cost = instance_dict["mtn_cost"]
    
    timeElapsed = time() - begin_time 
    
    result = Dict()
    mtnCost = dot(mtn_cost, sz)
    while true 
        println("foSize = ", foSize)
        #println("Previous cost = ", prev_cost)
        
        result = FixAndOptimize(fomodel, sy, sz, foSize, foOverlap, instance_dict)
        sy = result["sy"]
        sz = result["sz"]
        sc = result["sc"]
    
        if result["obj"] < sol.obj
            sol = create_solution(result)
        end 
        println("OBJECTIF = ", sol.obj)
        
        println("Time : ", timeElapsed)
        dev = abs((sol.obj - prev_cost)/prev_cost)*100
        println("Déviation = ", dev)
        
        foSize += inc
    
        timeElapsed = time() - begin_time
        
        if foSize > sizeLimit
            break
        end 
    end
    
    println("OBJECTIF = ", result["obj"])
    
    return sol
end


