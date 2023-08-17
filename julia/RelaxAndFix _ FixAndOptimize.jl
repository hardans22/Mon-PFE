using JuMP, Gurobi, CPLEX, LinearAlgebra
include("functions.jl")

function initWindow(windowType, instance_dict)
    P = instance_dict["P"]
    T = instance_dict["T"]

    if windowType == 0
        sol_window = [(i,t) for i in P for t in T]
    elseif windowType == 1
        sol_window = [(i,t) for t in T for i in P]
    end 
    return sol_window
end 


function buildM(sz, sc, instance_dict,rf_or_fo)
    P = instance_dict["P"]
    T = instance_dict["T"]
    len_T = instance_dict["t"]
    len_P = instance_dict["p"]
    demand = instance_dict["demand"]
    variable_prod_cost = instance_dict["variable_prod_cost"]
    holding_cost = instance_dict["holding_cost"]
    set_up_cost = instance_dict["set_up_cost"]
    mtn_cost = instance_dict["mtn_cost"]

    model = Model(CPLEX.Optimizer)

    #Les vaiables

    model[:x] = @variable(model, 0 <= x[P,T])

    model[:I] = @variable(model, 0 <= I[P,T])

    model[:u] = @variable(model, 0<= u[T])


    if rf_or_fo == "RF"
        model[:y] = @variable(model, 0 <= y[P,T] <= 1)
    elseif rf_or_fo == "FO"
        model[:y] = @variable(model, 0 <= y[P,T], Bin)
    end

    #Les contraintes

    @constraint(model, c1[i in P], x[i,1] - I[i,1] == demand[i,1])
    
    @constraint(model, c2[i in P, t in 2:len_T], x[i,t] + I[i,t-1] - I[i,t] == demand[i,t])
    
    @constraint(model, c3[i in P, t in T], x[i,t] <= (sum(demand[i,s] for s in t:len_T))*y[i,t])

    model[:c4] = @constraint(model, c4[t in T], sum(x[i,t] for i in P) - u[t] <= sc[t])
    
    #objective
    obj = sum(set_up_cost .* y + variable_prod_cost .*x + holding_cost .*I) 
    coef = sum(mtn_cost)/(len_T)
    obj += sum(coef*u[t] for t in T)

    @objective(model, Min, obj)
    
    return model
end


function solve_model(model, w_fix, w_mip, sy, rf_or_fo)
    x = model[:x]
    I = model[:I]
    y = model[:y]
    u = model[:u]

    cts = []
    for elt in w_fix
        i, t = elt[1], elt[2]
        ct = @constraint(model, y[i,t] == sy[i,t])
        push!(cts,ct)
    end
    
    if rf_or_fo == "RF"
        for elt in w_mip 
            i, t = elt[1], elt[2]
            set_binary(y[i,t])
        end 
    end
    
    set_silent(model)
    JuMP.optimize!(model)
    
    obj = objective_value(model)

    sx = round.(JuMP.value.(x), digits = 3)
    sI = round.(JuMP.value.(I), digits = 3)
    sy = round.(JuMP.value.(y), digits = 3)
    su = round.(JuMP.value.(u), digits = 3)

    if rf_or_fo == "FO"
        for ct in cts
            delete(model, ct)
        end
    end 

    return Dict("obj" => obj, "sx" => sx, "sI" => sI, "sy" => sy, "su" => su,"model" => model)
end


function RelaxAndFix(mdl, windowSize, windowType, overlap, instance_dict)
    begin_time = time()
    t = instance_dict["t"]
    p = instance_dict["p"]
    #Résolution du problème linéaire avec y continue
    set_silent(mdl)
    JuMP.optimize!(mdl)
    y = mdl[:y]
    sy = JuMP.value.(y)
    #display(sy)

    curseur = 0
    step = overlap*windowSize
    #println("step = ", step)

    #Initialisation de l'ensemble de toutes les cases de la matrices selon l'orientation choisi (windowType)
    sol_window = initWindow(windowType, instance_dict)
    window = sol_window[1:windowSize]
    w_fix = []
    w_mip = window
    w_lp = [elt for elt in sol_window if !(elt in window)]
    rf_or_fo = "RF"
    iter = 0
    while true
        iter+=1
        println("\t\t-------------------Itération ", iter, "--------------------")
        #=
        println("window : ", length(window))
        println("w_fix : ", length(w_fix))
        println("w_mip : ", length(w_mip))
        println("w_lp : ", length(w_lp))
        =#
        result = solve_model(mdl, w_fix, w_mip, sy, rf_or_fo)
        sy = result["sy"]
        mdl = result["model"]
        #display(sy)
        curseur += floor(Int64, step)

        if curseur + windowSize <= t*p
            window = sol_window[curseur+1:(curseur+windowSize)]
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
            return Dict("obj" => obj, "sx" => sx, "sI" => sI, "sy" => sy, "su" => su)
        end
    end
end


function FixAndOptimize(mdl, sol_y, windowSize, overlap, timeLimit, instance_dict)
    begin_time = time()
    t = instance_dict["t"]
    p = instance_dict["p"]
    #display(sol_y)
    sy = sol_y
    sx, sI, su = [], [], []
    obj = 0
    
    step = overlap*windowSize
    #println("step = ", step)

    rf_or_fo = "FO"
    windowType = 0
    while true
        #println("windowType = ", windowType)
        curseur = 0
        sol_window = initWindow(windowType, instance_dict)
        window = sol_window[1:windowSize]
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
            result = solve_model(mdl, w_fix, w_mip, sy, rf_or_fo)
            sy = result["sy"]
            mdl = result["model"]
            #display(sy)
            
            curseur += floor(Int64, step)

            if curseur + windowSize <= t*p
                window = sol_window[curseur+1:(curseur+windowSize)]
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

            if curseur + windowSize >= t*p
                break
            end 
        end
        windowType = 1 - windowType
        if (time() - begin_time) >= timeLimit || windowType == 0
            return Dict("obj" => obj, "sx" => sx, "sI" => sI, "sy" => sy, "su" => su)
        end 
    end
end 


function general_FO(best_sol, windowSize, overlap, timeLimit, tolerance, increment, instance_dict )
    begin_time = time()
    sz = best_sol.z
    sc = best_sol.c
    sy = best_sol.y
    model = buildM(sz,sc,instance_dict, "FO")
    prev_cost = best_sol.obj
    mtn_cost = instance_dict["mtn_cost"]
    timeElapsed = time() - begin_time 
    timeRemaining = timeLimit - timeElapsed
    result = Dict()
    mtnCost = dot(mtn_cost, sz)
    while true 
        println("windowSize = ", windowSize)
        #println("Previous cost = ", prev_cost)
        
        result = FixAndOptimize(model, sy, windowSize, overlap, timeRemaining, instance_dict)
        sy = result["sy"]
        result["obj"] += mtnCost
        result["sz"] = sz
        result["sc"] = sc
    
        if result["obj"] < best_sol.obj
            best_sol = create_solution(result)
        end 
        println("OBJECTIF = ", best_sol.obj)

        println("Time : ", timeElapsed)
        windowSize += increment
        
        timeElapsed = time() - begin_time
        timeRemaining = timeLimit - timeElapsed
        if timeElapsed > timeLimit 
            break
        end 
        prev_cost = result["obj"]
    end
    
    println("OBJECTIF = ", result["obj"])
    
    return best_sol
end