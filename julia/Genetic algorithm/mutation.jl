include("./functions.jl")

function mutation(sol_parent,instance_dict)
    #=
    Cette fonction est permet d'appliquer 
    un opérateur de mutation à l'individu 
    sol_parent. L'opérateur appliqué dépend 
    de la valeur de nombre aléatoire tiré.
    Cette fonction retourne le fils_z et le 
    fils_y obtenu
    À voir dans la suite 
    =#

    T = instance_dict["T"] #Ensemble des périodes 
    P = instance_dict["P"] #Ensemble des produits
    t = instance_dict["t"] #Nombre de période de temps 
    p = instance_dict["p"] #Nombre de produits 
    
    mtn_cost = instance_dict["mtn_cost"] #Coût de maintenance (liste) pour chaque période
    
    parent_z = copy(sol_parent.z)
    parent_y = copy(sol_parent.y)

    #Les indices gènes de z égales à 1 et 0 sont stockés resp dans z_ones et z_zeros
    #La première période n'est pas considérée
    z_ones, z_zeros = [], []
    for ind in 2:t
        if parent_z[ind] == 1
            push!(z_ones, ind)
        else 
            push!(z_zeros, ind)
        end
    end
    shuffle!(z_ones) # Mélange des positions des indices aléatoirement
    shuffle!(z_zeros) # Mélange des positions des indices aléatoirement


    fils_z = copy(sol_parent.z)
    fils_y = copy(sol_parent.y)

    rd = rand() # Tirage aléatoire suivant la loi normal

    if  rd <= 1/3
        #println("-------------SWAP-----------")
        #=
        Dans ce cas, on effectue un swap, c'est-à-dire 
        la position d'un gène de valeur 1 est échangé 
        avec celle d'un gène de valeur 0 
        =#
        
        if length(z_ones) != 0 && length(z_zeros) != 0
            #=
            Un contrôle pour être sûr que z_ones 
            et z_zeros sont non vide avant l'échange
            =#
            fils_z[z_ones[1]] = 0
            fils_z[z_zeros[1]] = 1
        end
        
        item = rand(1:p) #Un item aléatoire est tiré
        
        item_ones, item_zeros = [], []
        #On récupère la position des gènes de valeurs 0 et 1 pour cet item
        for j in 2:t
            if fils_y[item,j] == 1
                push!(item_ones,j)
            else
                push!(item_zeros,j)
            end
        end
        shuffle!(item_ones) #Mélange des positions des indices aléatoirement
        shuffle!(item_zeros)

        fils_y[item, item_ones[1]] = 0
        fils_y[item, item_zeros[1]] = 1 
        
    end
    if  1/3 < rd <= 2/3
        #println("-----------------DÉCALAGE--------------")
        #=
        Dans ce cas, on effectue un décalage vers la droite 
        à partir d'un gène dont la valeur est égale à 1. 
        On ajoute un 0 au point de décalage
        =#
        if length(z_ones) != 0
            #=
            Un contrôle pour être sûr que z_ones 
            est non vide
            =#
            ind = z_ones[1]
            #Décalage d'un pas de maintenance à droite à partir d'une période où une maintenance est effectué 
            fils_z = vcat(parent_z[1:ind-1], [0], parent_z[ind:t-1])
        end 
        #On effectue la même chose pour un item choisi aléatoire 
        y_ones = []
       
        item = rand(2:p)
    
        for j in 2:t
            if parent_y[item,j] == 1
                push!(y_ones, j)
            end
        end
        
        shuffle!(y_ones)

        ind = y_ones[1]
        fils_y[item,:] = vcat(parent_y[item,1:ind-1], [0], parent_y[item,ind:t-1])        
    end

    if  2/3 < rd <= 1
        #println("------------------INVERSER LA VALEUR D'UN GÈNE-----------------")
        #=Dans ce cas, on inverse la valeur d'un gène =#
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
