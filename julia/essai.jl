p = 20
t = 25

y = zeros(Int,p+1,t)
#println(y)
size = 5
step = 2
n_iter = 60
all_window = [(i,j) for i in 1:p+1 for j in 1:t]
window = [(i,j) for i in 1:size for j in 1:size]
w_fix = []
w_mip = window
w_lp = [elt for elt in all_window if !(elt in window)]

for elt in w_mip
    y[elt[1], elt[2]] = -1
end 

for elt in w_lp
    y[elt[1], elt[2]] = 1
end

#println(all_window)
display(y)
function ess(w_fix, w_mip, w_lp)
    curseur_t = size+1
    curseur_p = 1
    change = 0
    for i in 1:n_iter
        println("---------------------------ITÉRATION ", i, "-------------------------")
        println("curseur_t = ",curseur_t)
        println("curseur_p = ", curseur_p)
        
        if curseur_t + size -1  <= t && curseur_p + size - 1  <= p+1 #On vérifie si depuis curseur on peut avoir rfSize variables
            println("YES")
            if change == 1
                window = [(i,j) for i in curseur_p:curseur_p+size-1 for j in curseur_t-size:curseur_t-1]
                change = 0
                curseur_t -= step
            else
                window = [(i,j) for i in curseur_p:curseur_p-1+size for j in curseur_t + (curseur_p-i):curseur_t  + (size-1) + (curseur_p-i)]
            end

        else  #Sinon on prend de curseur jusqu'à la fin
            println("NO")
            if curseur_p + size <= p+1
                println("NOOOOOOOO")
                window = [(i,j) for i in curseur_p:curseur_p-1+size for j in curseur_t -i + curseur_p+(t-curseur_t-step):t]
                curseur_p += size - step
            else
                window = w_lp            
            end
            curseur_t = size +1
            change = 1
        end

        #println(w_fix)
        w_fix = vcat([elt for elt in w_fix if !(elt in window)], [elt for elt in w_mip if !(elt in window)])
        #w_fix = vcat(w_fix, [(i,j) for i in 1:size for j in curseur_t-size:curseur_t - i])
        w_mip = window
        w_lp = [elt for elt in w_lp if !(elt in window)]
        println(length(w_mip))
        println(length(w_fix))
        println(length(w_lp))
        for elt in w_mip
            y[elt[1], elt[2]] = -1
        end 
        
        for elt in w_fix
            y[elt[1], elt[2]] = 0
        end
        
        for elt in w_lp
            y[elt[1], elt[2]] = 2
        end
        display(y)
        if change == 0
            curseur_t += step
        end    
        println("curseur_t = ",curseur_t)
        println("curseur_p = ", curseur_p)

        if curseur_p > p+1
            break
        end 
    end 
    
end




foSize = size
all_window = [(i,j) for i in 1:p+1 for j in 1:t]
window = [(i,j) for i in 1:size for j in 1:size]
w_mip = window
w_fix = [elt for elt in all_window if !(elt in window)]

y = zeros(Int,p+1,t)
for elt in w_mip
    y[elt[1], elt[2]] = -1
end 

for elt in w_fix
    y[elt[1], elt[2]] = 1
end
display(y)

function ess1(w_fix, w_mip)
    curseur_t = foSize+1
    curseur_p = 1
    change = 0
    for i in 1:n_iter
        println("---------------------------ITÉRATION ", i, "-------------------------")
        println("curseur_t = ",curseur_t)
        println("curseur_p = ", curseur_p)
        
        if curseur_t + foSize -1  <= t && curseur_p + foSize - 1  <= p+1 #On vérifie si depuis curseur on peut avoir rfSize variables
            println("YES")
            if change == 1
                window = [(i,j) for i in curseur_p:curseur_p+foSize-1 for j in curseur_t-foSize:curseur_t-1]
                change = 0
                curseur_t -= step
            else
                window = [(i,j) for i in curseur_p:curseur_p-1+foSize for j in curseur_t + (curseur_p-i):curseur_t  + (foSize-1) + (curseur_p-i)]
            end

        else  #Sinon on prend de curseur jusqu'à la fin
            println("NO")
            if curseur_p + foSize <= p+1
                println("NOOOOOOOO")
                window = [(i,j) for i in curseur_p:curseur_p-1+foSize for j in curseur_t -i + curseur_p+(t-curseur_t-step):t]
                curseur_p += foSize - step
            else
                println("NO NO NO NO NO NO NO NO")
                window = [(i,j) for i in curseur_p:p+1 for j in curseur_t-size:t]   
                curseur_p += foSize  
            end
            curseur_t = foSize +1
            change = 1
        end

        w_mip = window
        w_fix = [elt for elt in all_window if !(elt in window)]
        
        for elt in w_mip
            y[elt[1], elt[2]] = -1
        end 
        
        for elt in w_fix
            y[elt[1], elt[2]] = 1
        end
        display(y)
        if change == 0
            curseur_t += step
        end    
        
        if curseur_p >= p+1
            println("STOPPPPPP")
            break
        end 
    end 
end
#ess(w_fix, w_mip, w_lp)
ess1(w_fix, w_mip)
