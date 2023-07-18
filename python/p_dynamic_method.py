import numpy as np
from genere_instances import *
from decimal import *
import random as rd
import itertools



T = 20
instance_dict = gen_instance_one_product(T)
np.random.seed(14)
pi = np.random.normal(0,1, size = T)
#pi = [ -1.55133911, -0.07918602, -0.17397653, -0.07233657, -2.0043294 ]
def construction_sol(index, position, solution, capacities, min_path_index, alpha, cmax):
    if index == 0: 
        solution[position] = 1
        capacities[position] = cmax
        index = min_path_index[position-1]
        position -= 1

    else :
        position -= index
        solution[position] = 1
        for i in range(1, index+1):
            capacities[position+i] = (alpha**i)*cmax
        capacities[position] = cmax
        index = 0
    

    return index, position, solution, capacities 
    


def prog_dynamic(instance_dict, pi):
    T = instance_dict['T']
    mtn_cost = instance_dict["mtn_cost"]
    cmax = instance_dict["cmax"]
    alpha = instance_dict["alpha"]
    
    cases_per_period = dict()  #contient toutes les cases par période
    cases_per_period[0] = np.array([mtn_cost[0] + pi[0]*cmax]) #La seule case de la période 0 contient que 0 
    
    min_path_index = []  #Permet de récupérer le chemin des min séléctionnés, le min pour période t est à la position t-1 dans la liste  
    for t in range(1,T):
        cases_per_period[t] = np.zeros(t+1)

        #Calcule de la valeur de la case 0
        min_index = np.argmin(cases_per_period[t-1])
        min_val = cases_per_period[t-1][min_index]
        min_path_index.append(min_index)
        cases_per_period[t][0] = min_val + pi[t]*cmax + mtn_cost[t]

        #Copie des cases de t-1 et ajouut des coûts
        cost = [(alpha**(i+1))*pi[t]*cmax for i in range(t)]  # On calcule le coût à ajouter à chaque case de la periode t sauf la case 0
        temp = cases_per_period[t-1] 
        cases_per_period[t][1:] = temp + cost  #Ajout des coûts pour chaque case sauf de la période t sauf la case 0
        
    
    index_opt = np.argmin(cases_per_period[T-1])
    #print("index = ",index_opt)
    obj_opt = cases_per_period[T-1][index_opt]
    #print('Optimal = ', obj_opt)

    #Construction de la solution i.e z et c
    index = index_opt
    period  = T-1
    z_opt = np.zeros(T)
    c_opt = [0 for _ in range(T)]

    while period != 0:
        if index == 0: 
            z_opt[period] = 1
            c_opt[period] = Decimal(cmax)
            index = min_path_index[period-1]
            period -= 1

        else :
            period -= index
            z_opt[period] = 1
            for i in range(1, index+1):

                c_opt[period+i] = Decimal(alpha**i)*Decimal(cmax)
            c_opt[period] = Decimal(cmax)
            index = 0
    
    
    
    return z_opt, c_opt, obj_opt



def verify(instance_dict):
    T = instance_dict['T']
    period_set = instance_dict['period_set']
    mtn_cost = instance_dict["mtn_cost"]
    cmax = instance_dict["cmax"]
    alpha = instance_dict["alpha"]

    possibilities_z = list(itertools.product([0,1], repeat = T))
    all_capacities = []
    val_list = []
    all_z = []
    for z in possibilities_z:
        if z[0] ==1 : 
            cap_z = np.zeros(T)
            compt = 0
            for t in period_set: 
                if z[t] == 1:
                    cap_z[t] = cmax
                    compt = 0
                else:
                    cap_z[t] = (alpha**(compt+1))*cmax
                    compt+=1
            all_capacities.append(cap_z)
            cost1 = sum(mtn_cost[t]*z[t] for t in period_set)
            cost2 = sum(pi[t]*cap_z[t] for t in period_set)
            val_list.append(cost1+cost2)
            all_z.append(z)
    val_list = np.array(val_list)
    j = np.argmin(val_list)
    z_opt = all_z[j]
    c_opt = all_capacities[j]
    obj_opt = val_list[j]

    return z_opt, c_opt, obj_opt

"""
z_opt_dyn, c_opt_dyn, obj_opt_dyn = prog_dynamic(instance_dict, pi)

print("z_opt_dyn = ", z_opt_dyn)
print("c_opt_dyn = ", c_opt_dyn)
print("obj_opt_dyn = ", obj_opt_dyn)
print()
z_opt, c_opt, obj_opt = verify(instance_dict)
print()
print("z_opt = ", z_opt)
print("c_opt = ", c_opt)
print("obj_opt = ", obj_opt)
"""