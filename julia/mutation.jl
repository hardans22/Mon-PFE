include("./functions.jl")

function mutation(sol_parent,instance_dict,rst,rd)
    T = instance_dict["T"]
    P = instance_dict["P"]
    t = length(T)
    p = length(P)
    
    mtn_cost = instance_dict["mtn_cost"]
    
    parent_z = copy(sol_parent.z)
    parent_y = copy(sol_parent.y)
    
    ind_ones, ind_zeros = [], []
    for ind in 2:t
        if parent_z[ind] == 1
            push!(ind_ones, ind)
        else 
            push!(ind_zeros, ind)
        end
    end

    shuffle!(ind_ones)
    shuffle!(ind_zeros)
    if !rst
        rd = rand()
    end

    if  rd <= 0.3
        #println("-------------SWAP-----------")
        fils_z = copy(sol_parent.z)

        fils_z[ind_ones[1]] = 0
        fils_z[ind_zeros[1]] = 1
        fils_y = copy(sol_parent.y)

        for item in P
            i_ones, i_zeros = [], []
            for j in 2:t
                if fils_y[item, j] == 1
                    push!(i_ones, j)
                else
                    push!(i_zeros, j)
                end
            end
            shuffle!(i_ones)
            shuffle!(i_zeros)
            if length(i_ones) != 0 && length(i_zeros) != 0
                #println(i_ones[1], " : ", i_zeros[1])
                fils_y[item, i_ones[1]] = 0
                fils_y[item, i_zeros[1]] = 1
            end 
        end
    end
    if  0.3 < rd <= 0.6
        #println("-----------------DÉCALAGE--------------")
        ind = ind_ones[1]
        #Décalage d'un pas de maintenance à droite à partir d'une période où une maintenance est effectué 
        fils1_z = vcat(parent_z[1:ind-1], [0], parent_z[ind:t-1])
        #fils1_z je décale un pas de maintenance à gauche à partir d'une période où une maintenance est effectué 
        fils2_z = vcat(parent_z[1:ind-1], parent_z[ind+1:t], [0])
        
        #on prend le meilleur en terme de coût de maintenance
        if dot(mtn_cost,fils1_z) <= dot(mtn_cost,fils2_z)
            fils_z = fils1_z
        else
            fils_z = fils2_z
        end

        fils_y = zeros(Int64,p,t)
        for item in P
            i_ones = []
            for j in 2:t
                if parent_y[item,j] == 1
                    push!(i_ones, j)
                end
            end
            shuffle!(i_ones)
            if length(i_ones) != 0
                ind = i_ones[1]
            else
                ind = rand(1:t)
            end
            #println(ind)
            fils_y[item,:] = vcat(parent_y[item,1:ind-1], [0], parent_y[item,ind:t-1])        
        end
    end
    if  0.6 < rd <= 0.9
        #println("------------------ENLÈVE UN 1-----------------")
        ind_ones_y = []
        for i in P
            for j in 2:t
                if parent_y[i,j] == 1
                    temp = (i,j)
                    push!(ind_ones_y, temp)
                end
            end
        end
        shuffle!(ind_ones_y)
        
        fils_z = copy(sol_parent.z)
        fils_z[ind_ones[1]] = 0
        
        fils_y = copy(sol_parent.y)
        temp = ind_ones_y[1]
        #println(temp)
        fils_y[temp[1], temp[2]] = 0
    end
    if rd > 0.9
        #println("-----------------AJOUT DE 1--------------")
        ind_zeros_y = []
        for i in P
            for j in 2:t
                if parent_y[i,j] == 0
                    temp = (i,j)
                    push!(ind_zeros_y, temp)
                end
            end
        end
        shuffle!(ind_zeros_y)
        
        fils_z = copy(sol_parent.z)
        fils_z[ind_zeros[1]] = 1
        fils_y = copy(sol_parent.y)
        #println(temp)
        temp = ind_zeros_y[1]
        fils_y[temp[1], temp[2]] = 1
    end
    

    return fils_z, fils_y   
end 
