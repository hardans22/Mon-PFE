using JuMP, Gurobi, CPLEX

function buildM(sc, instance_dict,rf_or_fo)
    P = instance_dict["P"]
    T = instance_dict["T"]
    len_T = instance_dict["t"]
    len_P = instance_dict["p"]
    demand = instance_dict["demand"]
    variable_prod_cost = instance_dict["variable_prod_cost"]
    holding_cost = instance_dict["holding_cost"]
    set_up_cost = instance_dict["set_up_cost"]
    model = Model(Gurobi.Optimizer)

    #Les vaiables

    model[:x] = @variable(model, 0 <= x[P,T])

    model[:I] = @variable(model, 0 <= I[P,T])

    if rf_or_fo == "RF"
        model[:y] = @variable(model, 0 <= y[P,T] <= 1)
    elseif rf_or_fo == "FO"
        model[:y] = @variable(model, 0 <= y[P,T], Bin)
    end

    #Les contraintes

    @constraint(model, c1[i in P], x[i,1] - I[i,1] == demand[i,1])
    
    @constraint(model, c2[i in P, t in 2:len_T], x[i,t] + I[i,t-1] - I[i,t] == demand[i,t])
    
    @constraint(model, c3[i in P, t in T], x[i,t] <= (sum(demand[i,s] for s in t:len_T))*y[i,t])

    @constraint(model, c4[t in T], sum(x[i,t] for i in P) <= sc[t])
    
    #objective
    @objective(model, Min, sum(set_up_cost[i,t]*y[i,t] + variable_prod_cost[i,t]*x[i,t] + holding_cost[i,t]*I[i,t] for i in P, t in T))
    
    return model
end


function solve_model(model, w_fix, w_mip, sy, instance_dict)
    x = model[:x]
    I = model[:I]
    y = model[:y]

    for elt in w_fix
        i, t = elt[1], elt[2]
        @constraint(model, y[i,t] == sy[i,t])
    end

    for elt in w_mip 
        i, t = elt[1], elt[2]
        set_binary(y[i,t])
    end 

    set_silent(model)
    JuMP.optimize!(model)
    
    sx = JuMP.value.(x)
    sI = JuMP.value.(I)
    sy = JuMP.value.(y)
    
    return Dict("sx" => sx, "sI" => sI, "sy" => sy, "model" => model)
end

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

function RelaxAndFix(mdl, windowSize, windowType, overlap, timeLimit, instance_dict)
    t = instance_dict["t"]
    p = instance_dict["p"]
    #Résolution du problème linéaire avec y continue
    set_silent(mdl)
    JuMP.optimize!(mdl)
    y = mdl[:y]
    sy = JuMP.value.(y)
    display(sy)

    curseur = 1
    step = overlap*windowSize
    println("step = ", step)

    #Initialisation de l'ensemble de toutes les cases de la matrices selon l'orientation choisi (windowType)
    sol_window = initWindow(windowType, instance_dict)
    window = sol_window[1:windowSize]
    w_fix = []
    w_mip = window
    w_lp = [elt for elt in sol_window if !(elt in window)]

    iter = 0
    while true
        iter+=1
        println("-------------------Itération", iter, "--------------------")
        #=
        println("window : ", length(window))
        println("w_fix : ", length(w_fix))
        println("w_mip : ", length(w_mip))
        println("w_lp : ", length(w_lp))
        =#
        result = solve_model(mdl, w_fix, w_mip, sy, instance_dict)
        sy = result["sy"]
        mdl = result["model"]
        display(sy)
        curseur += floor(Int64, step)

        if curseur + windowSize <= t*p
            window = sol_window[curseur+1:(curseur+windowSize)]
        else
            window = sol_window[curseur:end]
        end
            
        w_fix = vcat(w_fix, [elt for elt in w_mip if !(elt in window)])
        w_mip = window
        w_lp = [elt for elt in w_lp if !(elt in window)]
        sx = result["sx"]
        sI = result["sI"]

        if all(isinteger, sy)
            return Dict("sx" => sx, "sI" => sI, "sy" => sy)
        end
    end
end

function FixAndOptimize(mdl, sol_y, windowSize, overlap, timeLimit, instance_dict)
    t = instance_dict["t"]
    p = instance_dict["p"]
    sy = sol.y
    curseur = 1
    step = overlap*windowSize
    println("step = ", step)

    windowType = 0
    while true
        sol_window = initWindow(windowType, instance_dict)
        window = sol_window[1:windowSize]
        w_mip = window
        w_fix = [elt for elt in sol_window if !(elt in window)]

        while true
            result = solve_model(mdl, w_fix, w_mip, sy, instance_dict)
            sy = result["sy"]
            mdl = result["model"]
            display(sy)

            curseur += floor(Int64, step)

            if curseur + windowSize <= t*p
                window = sol_window[curseur+1:(curseur+windowSize)]
            else
                window = sol_window[curseur:end]
            end

            w_mip = window

            w_fix = [elt for elt in sol_window if !(elt in window)]
            
            sx = result["sx"]
            sI = result["sI"]

        end
    end

end 