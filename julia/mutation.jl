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

        item = rand(2:p)
        
        item_ones, item_zeros = [], []
        for j in 2:t
            if fils_y[item,j] == 1
                push!(item_ones,j)
            else
                push!(item_zeros,j)
            end
        end
        shuffle!(item_ones)
        shuffle!(item_zeros)

        fils_y[item, item_ones[1]] = 0
        fils_y[item, item_zeros[1]] = 1 
        
    end
    if  1/3 < rd <= 2/3
        #println("-----------------DÉCALAGE--------------")
        ind = z_ones[1]
        #Décalage d'un pas de maintenance à droite à partir d'une période où une maintenance est effectué 
        fils_z = vcat(parent_z[1:ind-1], [0], parent_z[ind:t-1])
        
        y_ones = []
        for i in P
            for j in 2:t
                temp = (i,j)
                if parent_y[i,j] == 1
                    push!(y_ones, temp)
                end
            end
        end
        shuffle!(y_ones)

        item = y_ones[1][1]
        ind = y_ones[1][2]
        fils_y[item,:] = vcat(parent_y[item,1:ind-1], [0], parent_y[item,ind:t-1])        
    end
    if  2/3 < rd <= 1
        #println("------------------MODIFIER LA VALEUR D'UN GÈNE-----------------")
        fils_z = copy(sol_parent.z)
        ind = rand(2:t)
        fils_z[ind] = 1 - fils_z[ind]
        
        fils_y = copy(sol_parent.y)
        item = rand(2:p)
        ind = rand(2:t)
        fils_y[item, ind] = 1 - fils_y[item, ind]
    end
    
    return fils_z, fils_y   
end 
