include("./functions.jl")

function crossover(sol_parent1, sol_parent2, instance_dict)
    #=
    Cette fonction est permet d'appliquer l'opérateur 
    de crossover en deux points pour les individus 
    sol_parent1 et sol_parent2. Le crossover est 
    appliqué pour chaque item avec des points de 
    croisement différents. Pour z et y le croisement 
    donne deux fils pour chaque. Ainsi on retourne 
    une liste de fils z et une liste de fils y. 
    À voir dans la suite  
    =#
    T = instance_dict["T"] #Ensemble des périodes 
    P = instance_dict["P"] #Ensemble des produits
    t = instance_dict["t"] #Nombre de période de temps 
    p = instance_dict["p"] #Nombre de produits 
    alpha = instance_dict["alpha"] #coefficient de réduction de capacité 
    cmax = instance_dict["cmax"]   #capacité maximale de la machine
    
    #Copie des parents
    parent1_z = copy(sol_parent1.z) 
    parent1_y = copy(sol_parent1.y)
    
    parent2_z = copy(sol_parent2.z)
    parent2_y = copy(sol_parent2.y)

    #Liste des points deux croisement de croisment
    list_pts = sort(randperm(t-1)[1:2] .+ 1)

    ind_1, ind_2  = list_pts[1], list_pts[2]
    
    #Les deux lignes suivantes s'occupent du croisement, cela génère deux fils 
    fils1_z = vcat(parent1_z[1:ind_1], parent2_z[ind_1+1:ind_2], parent1_z[ind_2+1:t])
    
    fils2_z = vcat(parent2_z[1:ind_1], parent1_z[ind_1+1:ind_2], parent2_z[ind_2+1:t])
    
    #Crossover pour chaque item de y
    fils1_y = zeros(Int64,p,t)
    fils2_y = zeros(Int64,p,t)

    #On effectue le même processus qu'en z pour chaque item
    for item in P
        #Liste des points deux croisement de croisment
        list_pts = sort(randperm(t-1)[1:2] .+ 1)
        #println("Les points de croisement :", list_pts)
        ind_1, ind_2  = list_pts[1], list_pts[2]
        fils1_y[item,:] = vcat(parent1_y[item,1:ind_1], parent2_y[item,ind_1+1:ind_2], parent1_y[item,ind_2+1:t])
        fils2_y[item,:] = vcat(parent2_y[item,1:ind_1], parent1_y[item,ind_1+1:ind_2], parent2_y[item,ind_2+1:t])
    end
    
    if fils1_z == fils2_z
        list_fils_z = [fils1_z]
    else
        list_fils_z = [fils1_z, fils2_z]
    end
     
    list_fils_y = [fils1_y, fils2_y]

    return list_fils_z, list_fils_y
    
end 
