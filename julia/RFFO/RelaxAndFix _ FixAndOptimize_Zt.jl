using JuMP, Gurobi, CPLEX, LinearAlgebra
include("../Genetic algorithm/functions.jl")

#=
    Here, we combine maintenance variables and setup variables. 
    Maintenance variables first and setup variables behind.
    We develop relax-and-fix/fix-and-optimize with z_t model 
    Une petite légende sur les noms des différents techniques
    RelaxAndFix et FixAndOptimize : parcours en bloc verticalement
    RelaxAndFix_0 et FixAndOptimize_0 : parcours en bloc horizontalement
    RelaxAndFix_1 et FixAndOptimize_1 : parcours en bloc par escalier 
    ou en parallélogramme (elle ne marche pas très bien)

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
    sol_window = []
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
    set_time_limit_sec(model, 7200.0)
    
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


function RelaxAndFix(mdl, rfSize, step, instance_dict)
    #=
        PARCOURS EN COLONNE PAR BLOC
        mdl = modèle crée 
        rfSize = Taille de la fenêtre de variable libres binaires 
        à chaque itération
        step = Nombre de nouvelle variables à ajouter
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

    curseur = 1 #curseur est comme un pointeur sur l'évolution dans la matrice des variables
    #step = overlap*rfSize
    #println("step = ", step)

    #Initialisation de l'ensemble de toutes les cases de la matrices selon l'orientation choisi (windowType)
    
    #println(sol_window)
    #sol_window = order_variable(sol_window, instance_dict)
    #println(sol_window)

    window = [(i,j) for i in 1:p+1 for j in 1:rfSize] #Initialisation de window
    w_fix = [] #Ensemble de variables fixées
    w_mip = window #Ensemble des variables binaires libres dans le modèle
    w_lp = [(i,j) for i in 1:p+1 for j in rfSize+1:t] #Ensemble des variables relaxées daans le modèle
    rf_or_fo = "RF"
    iter = 0
    while true
        #println("YYYYYYYYYYYYYYYYYYEEEEEEEEEEEEEEEEEESSSSSSSSSSSSSSS")
        iter+=1
        #=
        println("\t\t-------------------Itération ", iter, "--------------------")
        println("window : ",length(window))
        println("w_fix : ", length(w_fix))
        #println("w_mip : ", w_mip)
        println("w_lp : ", length(w_lp))
        =#
        result = solve_model(mdl, w_fix, w_mip, sy, sz, rf_or_fo)
        sy = result["sy"]
        sz = result["sz"]
        sc = result["sc"]
        mdl = result["model"]
        #display(sy)
        curseur += ceil(Int64, step)  #On déplace le curseur
        #println("curseur = ", curseur)
        if curseur + rfSize <= t #On vérifie si depuis curseur on peut avoir rfSize variables
            window = [(i,j) for i in 1:p+1 for j in curseur:curseur+rfSize-1] 
        else  #Sinon on prend de curseur jusqu'à la fin
            window = [(i,j) for i in 1:p+1 for j in curseur:t] 
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
        if all(isinteger, sy) && all(isinteger, sz)
            return Dict("obj" => obj, "sx" => sx, "sI" => sI, "sy" => sy, "sz" => sz, "sc" => sc, "su" => su)
        end
    end
end


function RelaxAndFix_0(mdl, rfSize, step, instance_dict)
    #=
        PARCOURS EN LIGNE PAR BLOC 
        mdl = modèle crée 
        rfSize = Taille de la fenêtre de variable libres binaires 
        à chaque itération
        step = Nombre denouvelles variables à ajouter 
        
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

    curseur = 1 #curseur est comme un pointeur sur l'évolution dans la matrice des variables
    #step = overlap*rfSize
    #println("step = ", step)

    #Initialisation de l'ensemble de toutes les cases de la matrices selon l'orientation choisi (windowType)
    
    #println(sol_window)
    #sol_window = order_variable(sol_window, instance_dict)
    #println(sol_window)

    window = [(i,j) for i in 1:rfSize for j in 1:t] #Initialisation de window
    w_fix = [] #Ensemble de variables fixées
    w_mip = window #Ensemble des variables binaires libres dans le modèle
    w_lp = [(i,j) for i in rfSize+1:p+1 for j in 1:t] #Ensemble des variables relaxées daans le modèle
    rf_or_fo = "RF"
    iter = 0
    while true
        #println("YYYYYYYYYYYYYYYYYYEEEEEEEEEEEEEEEEEESSSSSSSSSSSSSSS")
        iter+=1
        
        #println("\t\t-------------------Itération ", iter, "--------------------")
        #=
        println("window : ",window)
        println("w_fix : ", w_fix)
        #println("w_mip : ", w_mip)
        println("w_lp : ", w_lp)
        =#
        result = solve_model(mdl, w_fix, w_mip, sy, sz, rf_or_fo)
        sy = result["sy"]
        sz = result["sz"]
        sc = result["sc"]
        mdl = result["model"]
        #display(sy)
        curseur += ceil(Int64, step)  #On déplace le curseur
        #println("curseur = ", curseur)
        if curseur + rfSize <= p+1 #On vérifie si depuis curseur on peut avoir rfSize variables
            window = [(i,j) for i in curseur:curseur+rfSize-1 for j in 1:t] 
        else  #Sinon on prend de curseur jusqu'à la fin
            window = [(i,j) for i in curseur:p+1 for j in 1:t] 
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
        if all(isinteger, sy) && all(isinteger, sz)
            return Dict("obj" => obj, "sx" => sx, "sI" => sI, "sy" => sy, "sz" => sz, "sc" => sc, "su" => su)
        end
    end
end



function RelaxAndFix_1(mdl, rfSize, step, instance_dict)
    #=
        PARCOURS EN ESCALIER 
        mdl = modèle crée 
        rfSize = Taille de la fenêtre de variable libres binaires 
        à chaque itération
        step = Nombre denouvelles variables à ajouter 
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

    curseur = 1 #curseur est comme un pointeur sur l'évolution dans la matrice des variables
    #step = overlap*rfSize
    #println("step = ", step)

    #Initialisation de l'ensemble de toutes les cases de la matrices selon l'orientation choisi (windowType)
    
    #println(sol_window)
    #sol_window = order_variable(sol_window, instance_dict)
    #println(sol_window)
    
    all_window = [(i,j) for i in 1:p+1 for j in 1:t]

    window = [(i,j) for i in 1:rfSize for j in 1:rfSize]
    w_fix = []
    w_mip = window
    w_lp = [elt for elt in all_window if !(elt in window)]

    rf_or_fo = "RF"
    iter = 0

    curseur_t = rfSize+1
    curseur_p = 1
    change = 0

    while true
        #println("YYYYYYYYYYYYYYYYYYEEEEEEEEEEEEEEEEEESSSSSSSSSSSSSSS")
        iter+=1
        #=
        println("\t\t-------------------Itération ", iter, "--------------------")
        
        println("window : ",window)
        println("w_fix : ", w_fix)
        #println("w_mip : ", w_mip)
        println("w_lp : ", w_lp)
        =#
        result = solve_model(mdl, w_fix, w_mip, sy, sz, rf_or_fo)
        sy = result["sy"]
        sz = result["sz"]
        sc = result["sc"]
        mdl = result["model"]
        obj = result["obj"]
        sx = result["sx"]
        sI = result["sI"]
        su = result["su"]
        #println("Objectif : ", obj)
        #display(sy)
        #println("curseur = ", curseur)

        
        if curseur_t + rfSize -1  <= t && curseur_p + rfSize - 1  <= p+1 #On vérifie si depuis curseur on peut avoir rfSize variables
            if change == 1
                window = [(i,j) for i in curseur_p:curseur_p+rfSize-1 for j in curseur_t-rfSize:curseur_t-1]
                change = 0
                curseur_t -= step
            else
                window = [(i,j) for i in curseur_p:curseur_p-1+rfSize for j in curseur_t + (curseur_p-i):curseur_t  + (rfSize-1) + (curseur_p-i)]
            end

        else  #Sinon on prend de curseur jusqu'à la fin
            if curseur_p + rfSize <= p+1
                window = [(i,j) for i in curseur_p:curseur_p-1+rfSize for j in curseur_t -i + curseur_p+(t-curseur_t-step):t]
                curseur_p += rfSize 
            else
                window = w_lp            
            end
            curseur_t = rfSize +1
            change = 1
        end

        
        w_fix = vcat([elt for elt in w_fix if !(elt in window)], [elt for elt in w_mip if !(elt in window)])
        w_mip = window
        w_lp = [elt for elt in w_lp if !(elt in window)]
        
        if change == 0
            curseur_t += step
        end    
      
        if all(isinteger, sy) && all(isinteger, sz)
            return Dict("obj" => obj, "sx" => sx, "sI" => sI, "sy" => sy, "sz" => sz, "sc" => sc, "su" => su)
        end
    end
end


function FixAndOptimize(mdl, sol_y, sol_z, foSize, step, instance_dict)
    #=
        PARCOURS EN COLONNE PAR BLOC
        mdl = modèle crée 
        foSize = Taille de la fenêtre de variable libres binaires 
        à chaque itération
        step = Nombre de nouvelle variables à ajouter
    =#

    begin_time = time()
    t = instance_dict["t"]
    p = instance_dict["p"]
    #display(sol_y)
    sy = sol_y
    sz = sol_z
    sc = []
    sx, sI, su = [], [], []
    obj = 0
    
    #step = overlap*foSize
    #println("step = ", step)

    rf_or_fo = "FO"
    
    #println("windowType = ", windowType)
    sol_window = [(i,j) for i in 1:p+1, j in 1:t]
    curseur = 1
    window = [(i,j) for i in 1:p+1 for j in 1:foSize]
    w_mip = window
    w_fix = [(i,j) for i in 1:p+1 for j in 1:t if !((i,j) in window)]
    iter = 0
    while true
        iter+=1
        #=
        println("\t-------------------Itération ", iter, "--------------------")
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

        if curseur + foSize <= t
            window = [(i,j) for i in 1:p+1 for j in curseur:curseur + foSize]
        else
            window = [(i,j) for i in 1:p+1 for j in curseur:t]
            curseur = t
        end

        w_mip = window
        w_fix = [elt for elt in sol_window if !(elt in window)]
        
        obj = result["obj"]
        sx = result["sx"]
        sI = result["sI"]
        su = result["su"]
        #println("\tObjectif : ", obj)

        if curseur == t
            break
        end 
    end

    return Dict("obj" => obj, "sx" => sx, "sI" => sI, "sy" => sy, "sz" => sz, "sc" => sc, "su" => su)
end 



function FixAndOptimize_0(mdl, sol_y, sol_z, foSize, step, instance_dict)
    #=
        PARCOURS EN LIGNE PAR BLOC 
        mdl = modèle crée 
        foSize = Taille de la fenêtre de variable libres binaires 
        à chaque itération
        step = Nombre denouvelles variables à ajouter 
    =#
        begin_time = time()
    t = instance_dict["t"]
    p = instance_dict["p"]
    #display(sol_y)
    sy = sol_y
    sz = sol_z
    sc = []
    sx, sI, su = [], [], []
    obj = 0
    
    #step = overlap*foSize
    #println("step = ", step)

    rf_or_fo = "FO"
    
    #println("windowType = ", windowType)
    sol_window = [(i,j) for i in 1:p+1, j in 1:t]
    curseur = 1
    window = [(i,j) for i in 1:foSize for j in 1:t]
    w_mip = window
    w_fix = [(i,j) for i in 1:p+1 for j in 1:t if !((i,j) in window)]
    iter = 0
    while true
        iter+=1
        #=
        println("\t-------------------Itération ", iter, "--------------------")
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

        if curseur + foSize <= p+1
            window = [(i,j) for i in curseur:curseur+foSize for j in 1:t]
        else
            window = [(i,j) for i in curseur:p+1 for j in 1:t]
            curseur = t
        end

        w_mip = window
        w_fix = [elt for elt in sol_window if !(elt in window)]
        
        obj = result["obj"]
        sx = result["sx"]
        sI = result["sI"]
        su = result["su"]
        #println("\tObjectif : ", obj)

        if curseur == t
            break
        end 
    end

    return Dict("obj" => obj, "sx" => sx, "sI" => sI, "sy" => sy, "sz" => sz, "sc" => sc, "su" => su)
end 



function FixAndOptimize_1(mdl, sol_y, sol_z, foSize, step, instance_dict)
    #=
        PARCOURS EN ESCALIER 
        mdl = modèle crée 
        rfSize = Taille de la fenêtre de variable libres binaires 
        à chaque itération
        step = Nombre denouvelles variables à ajouter 
    =#
    begin_time = time()
    t = instance_dict["t"]
    p = instance_dict["p"]
    #display(sol_y)
    sy = sol_y
    sz = sol_z
    sc = []
    sx, sI, su = [], [], []
    obj = 0
    
    #step = overlap*foSize
    #println("step = ", step)

    rf_or_fo = "FO"
    
    #println("windowType = ", windowType)
    all_window = [(i,j) for i in 1:p+1 for j in 1:t]

    window = [(i,j) for i in 1:foSize for j in 1:foSize]
    w_mip = window
    w_fix = [elt for elt in all_window if !(elt in window)]



    curseur_t = foSize+1
    curseur_p = 1
    change = 0
   
    iter = 0
    while true
        iter+=1
        #=
        println("\t-------------------Itération ", iter, "--------------------")
        println("AVANT")
        println("window : ", length(window))
        println("w_fix : ", length(w_fix))
        println("w_mip : ", w_mip)
        
        println("curseur_p = ", curseur_p)
        println("curseur_t = ", curseur_t)
        =#
        result = solve_model(mdl, w_fix, w_mip, sy, sz, rf_or_fo)
        sy = result["sy"]
        sz = result["sz"]
        sc = result["sc"]
        mdl = result["model"]
        obj = result["obj"]
        sx = result["sx"]
        sI = result["sI"]
        su = result["su"]
        #println("\tObjectif : ", obj)
        #display(sy)
        
        if curseur_t + foSize -1  <= t && curseur_p + foSize - 1  <= p+1 #On vérifie si depuis curseur on peut avoir rfSize variables
            #println("YES")
            if change == 1
                window = [(i,j) for i in curseur_p:curseur_p+foSize-1 for j in curseur_t-foSize:curseur_t-1]
                change = 0
                curseur_t -= step
            else
                window = [(i,j) for i in curseur_p:curseur_p-1+foSize for j in curseur_t + (curseur_p-i):curseur_t  + (foSize-1) + (curseur_p-i)]
            end

        else  #Sinon on prend de curseur jusqu'à la fin
            #println("NO")
            if curseur_p + foSize <= p+1
                #println("NOOOOOOOO")
                window = [(i,j) for i in curseur_p:curseur_p-1+foSize for j in curseur_t -i + curseur_p+(t-curseur_t-step):t]
                curseur_p += foSize - step
            else
                #println("NO NO NO NO NO NO NO NO")
                window = [(i,j) for i in curseur_p:p+1 for j in curseur_t-foSize:t]   
                curseur_p += foSize  
            end
            curseur_t = foSize +1
            change = 1
        end

        
        
        w_mip = window
        w_fix = [elt for elt in all_window if !(elt in window)]
        
        if change == 0
            curseur_t += step
        end    
        #=
        println("APRÈS")
        println("window : ", length(window))
        println("w_fix : ", length(w_fix))
        println("w_mip : ", w_mip)
        
        println("curseur_p = ", curseur_p)
        println("curseur_t = ", curseur_t)
        =#
        if curseur_p >= p+1
            #println("STOPPPPPP")
            break
        end 
    end

    return Dict("obj" => obj, "sx" => sx, "sI" => sI, "sy" => sy, "sz" => sz, "sc" => sc, "su" => su)
end 


function IFO(sol, foSize, foOverlap, sizeLimit, inc, instance_dict)
    #=
        IFO est une idée de base en exploitant l'article de Toledo 
        mais par la suite. Elle n'est plus très utile pour nous 
        mais je la conserve quand même.
        Elle fait plusieurs itérations de FixAndOptimize(...) 
        en augmentant la taille des variables binaires dans le 
        modèle à chaque itération de "inc".

        Pour plus d'explication est peut-etre judicieux de revoir 
        l'article de Toledo
    =#
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
        
        foSize += inc  #augmentation de la taille des variables binaires dans le modèle.
    
        timeElapsed = time() - begin_time
        
        if foSize > sizeLimit
            break
        end 
    end
    
    println("OBJECTIF = ", result["obj"])
end 


