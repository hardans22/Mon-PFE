include("./functions.jl")

function crossover(sol_parent1, sol_parent2, instance_dict)
    P = instance_dict["P"]
    T = instance_dict["T"]
    p = length(P)
    t = length(T)
    alpha = instance_dict["alpha"]
    cmax = instance_dict["cmax"]
    
    #Copie des parents
    parent1_z = copy(sol_parent1.z)
    parent1_y = copy(sol_parent1.y)
    
    parent2_z = copy(sol_parent2.z)
    parent2_y = copy(sol_parent2.y)

    list_pts = sort(randperm(t-1)[1:2] .+ 1)

    
    ind_1, ind_2  = list_pts[1], list_pts[2]
    
    fils1_z = vcat(parent1_z[1:ind_1], parent2_z[ind_1+1:ind_2], parent1_z[ind_2+1:t])
    
    fils2_z = vcat(parent2_z[1:ind_1], parent1_z[ind_1+1:ind_2], parent2_z[ind_2+1:t])
    
    #Crossover pour chaque item de y
    fils3_y = zeros(Int64,p,t)
    fils4_y = zeros(Int64,p,t)
    
    for item in P
        list_pts = sort(randperm(t-1)[1:2] .+ 1)
        #println("Les points de croisement :", list_pts)

        ind_1, ind_2  = list_pts[1], list_pts[2]
        fils3_y[item,:] = vcat(parent1_y[item,1:ind_1], parent2_y[item,ind_1+1:ind_2], parent1_y[item,ind_2+1:t])
        fils4_y[item,:] = vcat(parent2_y[item,1:ind_1], parent1_y[item,ind_1+1:ind_2], parent2_y[item,ind_2+1:t])
    end
    
    list_fils_sol = []
    
    if fils1_z == fils2_z
        list_fils_z = [fils1_z]
    else
        list_fils_z = [fils1_z, fils2_z]
    end
     
    list_fils_y = [fils3_y, fils4_y]

    return list_fils_z, list_fils_y
    
end 
