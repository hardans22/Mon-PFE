include("./functions.jl")

function mutation(sol_parent,instance_dict)
    T = instance_dict["T"]
    P = instance_dict["P"]
    t = length(T)
    p = length(P)
    
    mtn_cost = instance_dict["mtn_cost"]
    
    parent_z = copy(sol_parent.z)
    parent_y = copy(sol_parent.y)

    #Les gènes de z égales à 1 et 0 sont stocké resp dans z_ones et z_zeros
    z_ones, z_zeros = [], []
    for ind in 2:t
        if parent_z[ind] == 1
            push!(z_ones, ind)
        else 
            push!(z_zeros, ind)
        end
    end
    shuffle!(z_ones)
    shuffle!(z_zeros)


    fils_z = copy(sol_parent.z)
    fils_y = copy(sol_parent.y)

    rd = rand()

    if  rd <= 1/3
        #println("-------------SWAP-----------")
        
        fils_z[z_ones[1]] = 0
        fils_z[z_zeros[1]] = 1 
        
    end
    if  1/3 < rd <= 2/3
        #println("-----------------DÉCALAGE--------------")
        ind = z_ones[1]
        #Décalage d'un pas de maintenance à droite à partir d'une période où une maintenance est effectué 
        fils_z = vcat(parent_z[1:ind-1], [0], parent_z[ind:t-1])

    end
    if  2/3 < rd <= 1
        #println("------------------MODIFIER LA VALEUR D'UN GÈNE-----------------")
        fils_z = copy(sol_parent.z)
        ind = rand(2:t)
        fils_z[ind] = 1 - fils_z[ind]
        
    end
    
    return fils_z, parent_y  
end 
