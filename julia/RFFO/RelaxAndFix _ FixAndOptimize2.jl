using JuMP, Gurobi, CPLEX, LinearAlgebra
include("../Genetic algorithm/functions.jl")


#=
    Here, we combine maintenance variables and setup variables. 
    Maintenance variables first and setup variables behind.
    We develop relax-and-fix/fix-and-optimize with z_t model 
    Cette version est la toute première version qui combine les 
    variables de maintenances de setup. Son idée est d'aplatir 
    la grosse matrice en une liste et ensuite de le parcourir 
    jusqu'à la fin. 
=#

function initWindow(windowType, instance_dict)
    #= 
        Cette fonction permet d'initialiser 
        le type de parcours. 
        windowType = 0 : parcours horizontal
        windowType = 1 : parcours vertical  
        On retourne ensemble contenant des couple (item, temps)
    =#

    p = instance_dict["p"] + 1 #Ajout de la liste des variables de maintenance comme un produit 
    P = 1:p
    T = instance_dict["T"] #Ensemble des périodes 
    
    if windowType == 0
        sol_window = [(i,t) for i in P for t in T]
    elseif windowType == 1
        sol_window = [(i,t) for t in T for i in P]
    end 
    return sol_window
end 

function croissant_holding_cost(x::Tuple, y::Tuple, set_up_cost)
    #=
    Compare les coûts associés à deux variables de décision 
    représentées par leurs couples (item, temps) respectifs 
    qui sont x et y. On fait -1 à x[1] et à y[1] parce que 
    par exemple (2,1) reperesente (1,1) dans la matrice des 
    coûts 
    =#
    x_i, x_t = x[1]-1, x[2]
    y_i, y_t = y[1]-1, y[2]
    return set_up_cost[x_i,x_t] > set_up_cost[y_i,y_t]
end

function order_variable(sol_window, instance_dict)
    #=
        Permet d'ordorner les positions des variables 
        suivant leur valeurs dans l'une des matrice 
        de coûts. Pour le moment, cela est fait 
        uniquement pour le parcours horizontal  
    =# 
    t = instance_dict["t"]
    set_up_cost = instance_dict["set_up_cost"]
    temp = sol_window[1:t] #Recupère la première ligne qui est le vecteur de maintenance
    sol_w = sort(sol_window[t+1:end], lt = (x, y) -> croissant_holding_cost(x, y, set_up_cost))
    sol_window = vcat(temp, sol_w) #On remet le vecteur de maintenanceà sa place après le tri 
    return sol_window
end 

function buildM(instance_dict,rf_or_fo)
    #=
        Construction d'un modèle qui est 
        réutilisé dans la suite. Il existe 
        deux options lors de la création du 
        modele : RF et RF (voir dans la suite).
    =#
    P = instance_dict["P"] #Ensemble d'items
    T = instance_dict["T"] #Ensemble de périodes
    len_T = instance_dict["t"] #Nombre de période 
    len_P = instance_dict["p"] 
    demand = instance_dict["demand"] #Matrice des demandes par item et par période
    variable_prod_cost = instance_dict["variable_prod_cost"] #Matrice des coûts variable de production par item et par période
    holding_cost = instance_dict["holding_cost"] #Matrice des coûts de stackoge par item et par période
    set_up_cost = instance_dict["set_up_cost"] #Matrice des mise en route par item et par période
    mtn_cost = instance_dict["mtn_cost"] #Matrice des coûts de maintenance par période
    alpha = instance_dict["alpha"]  #Coefficient de réduction de  capacité 
    cmax = instance_dict["cmax"]  #Capacité maximale de la machine

    model = Model(optimizer_with_attributes(Gurobi.Optimizer, "Threads" => 1))
    #model = Model(CPLEX.Optimizer)
    #set_optimizer_attribute(model, "CPXPARAM_Threads", 1)

    #Les variables

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
    #=
        Résolution du modèle
        model : le modèle crée
        w_fix : ensemble d'indices des variables à fixer
        w_mip : ensemble d'indices des variables qui seront 
        binaires et libres dans le modèle
        sy : la matrice des décisions de mise en route 
        sz : le vecteur des décisions de maintenances
        rf_or_fo : permet de définir si c'est "RF" ou "FO"
    =# 
    #Récupération des variables dans modèle
    x = model[:x]
    I = model[:I]
    y = model[:y]
    z = model[:z]
    c = model[:c]
    u = model[:u]

    cts = []
    #Ajout des contraintes pour fixer les variables
    for elt in w_fix
        i, t = elt[1], elt[2]
        if i == 1 # Si i =1 alors c'est une variable de maintenance
            ct = @constraint(model, z[t] == sz[t])
        else # Sinon c'est une variable de mise en route 
            ct = @constraint(model, y[i-1,t] == sy[i-1,t])
        end
        push!(cts,ct)  #On ajoute à la liste des contraintes 
    end
    
    if rf_or_fo == "RF"  #Si c'est le Relax-and-fix, on ajoute ceci
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
    
    if rf_or_fo == "FO" #Suppression des contraintes si c'est le Fix-and-optimize
        for ct in cts
            delete(model, ct)
        end
    end 

    return Dict("obj" => obj, "sx" => sx, "sI" => sI, "sy" => sy, "sz" => sz, "sc" => sc, "su" => su, "model" => model)
end


function RelaxAndFix(mdl, rfSize, windowType, overlap, instance_dict)
    #=
        mdl = modèle crée 
        rfSize = Taille de la fenêtre de variable libres binaires 
        à chaque itération
        windowType = type de parcours (0 ou 1)
        overlap = proportion de variable par rapport à rfSize à 
        fixer (entre 0 et 1)
        Notons que overlap est également la proportion de nouvelles 
        variables ajoutées dans la fenêtre. Ainsi 1- overlap est la 
        proportion de variable par rapport à rf Size qui sont réoptimisées 
    =#
    begin_time = time()
    t = instance_dict["t"] #Nombre de période 
    p = instance_dict["p"] #Nombrede produits 

    #Résolution du problème linéaire avec y continue
    set_silent(mdl)
    JuMP.optimize!(mdl)
    y = mdl[:y]
    z = mdl[:z]
    sy = JuMP.value.(y)
    sz = JuMP.value.(z)
    #display(sy)

    curseur = 0 #curseur est comme un pointeur sur l'évolution dans la matrice des variables
    step = overlap*rfSize
    #println("step = ", step)

    #Initialisation de l'ensemble de toutes les cases de la matrices selon l'orientation choisi (windowType)
    sol_window = initWindow(windowType, instance_dict)
    #println(sol_window)
    #sol_window = order_variable(sol_window, instance_dict)
    #println(sol_window)

    window = sol_window[1:rfSize] #Initialisation de window
    w_fix = [] #Ensemble de variables fixées
    w_mip = window #Ensemble des variables binaires libres dans le modèle
    w_lp = [elt for elt in sol_window if !(elt in window)] #Ensemble des variables relaxées daans le modèle
    rf_or_fo = "RF"
    iter = 0
    while true
        #println("YYYYYYYYYYYYYYYYYYEEEEEEEEEEEEEEEEEESSSSSSSSSSSSSSS")
        iter+=1
        #=
        println("\t\t-------------------Itération ", iter, "--------------------")
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
        curseur += floor(Int64, step)  #On déplace le curseur

        if curseur + rfSize <= t*p #On vérifie si depuis curseur on peut avoir rfSize variables
            window = sol_window[curseur+1:(curseur+rfSize)]
        else  #Sinon on prend de curseur jusqu'à la fin
            window = sol_window[curseur:end]
        end
        
        #Mise en jour des ensembles 
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


