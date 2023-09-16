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
    
    parent2_z = copy(sol_parent2.z)
   
    list_pts = sort(randperm(t-1)[1:2] .+ 1)

    
    ind_1, ind_2  = list_pts[1], list_pts[2]
    
    fils1_z = vcat(parent1_z[1:ind_1], parent2_z[ind_1+1:ind_2], parent1_z[ind_2+1:t])
    
    fils2_z = vcat(parent2_z[1:ind_1], parent1_z[ind_1+1:ind_2], parent2_z[ind_2+1:t])
    
    #Crossover pour chaque item de y
        
    list_fils_sol = []
    
    if fils1_z == fils2_z
        list_fils_z = [fils1_z]
    else
        list_fils_z = [fils1_z, fils2_z]
    end
     
    list_fils_y = [sol_parent1.y]

    return list_fils_z, list_fils_y
    
end 
