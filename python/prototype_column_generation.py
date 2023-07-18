import numpy as np 
from docplex.mp.model import Model
from genere_instances import *
import time 
"""
T = 5
set_up_cost = [1,5,7,3,6]
variable_prod_cost = [4,5,8,7,4]
inventory_cost = [1,1,1,1,1]
demand = [61,72,58,95,31]
cmax = 50
"""
#Instance
T = 20
instance_dict = gen_instance_one_product(T)
period_set = instance_dict["period_set"]
set_up_cost = instance_dict["set_up_cost"]
variable_prod_cost = instance_dict["variable_prod_cost"]
inventory_cost = instance_dict["inventory_cost"]
demand = instance_dict["demand"]
mtn_cost = instance_dict["mtn_cost"]
cmax = instance_dict["cmax"]
alpha = instance_dict["alpha"]
#print(mtn_cost)

def RMP(col: list):
    if col != 0:
        z.append(master.continuous_var(0.0, 1.0,name='z_'+str(len(z))))
        # On ajoute la variable dans toutes les contraintes concernées
        sct = col[0]
        Mc = col[1]
        contrainte4.left_expr += z[-1]
        for t in period_set:
            contraintes5[t].right_expr += sct[t]*z[-1]
            #print(contraintes5[t])
            
        
        #Ajout à la fonction objective
        master.obj += Mc*z[-1]
        #master.minimize(master.obj)

        #print(master.export_as_lp_string())
        # Résolution
        master_sol = master.solve(log_output = False)
        rmp_obj = master_sol.get_objective_value()
        objectives.append(rmp_obj)
        print("RMP_obj = ",rmp_obj)
        #master.print_solution()
        
        #Valeurs du dual
        pi = master.dual_values(contraintes5)
        pi.append(contrainte4.dual_value)
        #print(pi)
        return(pi)
    else:
        master_sol = master.solve(log_output = True)
        objectives.append(master_sol.get_objective_value())
        master.print_solution()
        
        #Valeurs du dual
        pi = master.dual_values(contraintes5)
        pi.append(contrainte4.dual_value)
        print(pi)
        return(pi)
    


def SP_MIP(pi: list):
    pricing = Model(name = "sous_probleme")
    zt = pricing.binary_var_list(period_set, name = "z")
    ct = pricing.integer_var_list(period_set, name = 'c')
    ct1 = pricing.add_constraints(ct[t] <= cmax for t in period_set)
    ct2 = pricing.add_constraints(ct[t] <= alpha*ct[t-1] + cmax*zt[t] for t in period_set)
    cost1 = sum(mtn_cost[t]*zt[t] + pi[t]*ct[t] for t in period_set)
    pricing.obj = cost1 - pi[-1]
    pricing.minimize(pricing.obj)
    
    
    # Résolution
    pricing_sol = pricing.solve(log_output = False)
    Z_SP = pricing_sol.get_objective_value()
    #pricing.print_solution()
    sct = pricing_sol.get_values(ct)
    szt = pricing_sol.get_values(zt)

    Mc = sum(mtn_cost[t]*szt[t]for t in period_set)
    new_col = [t for t in period_set if szt[t] != 0]
    
    col = [sct,Mc]
    if Z_SP >= -1E-5:
        Z_SP = 0
    if Z_SP >=0 :
        print("RMP optimal")
        return(0)
    else:
        print("Nouvelles période de maintenance: ",new_col, " Cout des maintenaces : ", Mc)
        print("Z_SP =" ,Z_SP)
        return(col)


start_time = time.time()

print("Itération 1")
c_init = [cmax for _ in period_set]
Mc = sum(mtn_cost)
objectives = []
master = Model(name="clspm")
#x = master.integer_var_matrix(period_set, period_set, name = "Lot variable")
x = {(i,j): master.continuous_var(name=f'x_{i}_{j}') for i in range(T) for j in range(i, T)} #lot variable

y = master.continuous_var_list(period_set, name = "y") #set_up variable

c = master.continuous_var_list(period_set,name = "c") #capacity variable

z = master.continuous_var_list(1, 0.0, 1.0, name = 'z') #maintenance variable


contraintes1 = master.add_constraints(master.sum(x[k,t] for k in range(t+1)) == demand[t] for t in period_set)

contraintes2 = master.add_constraints(x[k,t] <= demand[t]*y[k] for k in period_set for t in range(k,T)) 

contraintes3 = master.add_constraints(master.sum(x[k,t] for t in range(k,T)) <= c[k] for k in period_set)

contrainte4 = master.add_constraint(z[0] == 1)

contraintes5 = master.add_constraints(c[t] == c_init[t]*z[0] for t in period_set)

#Fonction objectif
cost1 = sum(set_up_cost[k]*y[k] for k in period_set)
cost2 = sum(variable_prod_cost[k]*sum(x[k,t] for t in range(k,T)) for k in period_set)
cost3 = sum(x[k,t]*sum(inventory_cost[j] for j in range(k,t)) for k in period_set for t in range(k,T))
cost4 = Mc*z[0]
master.obj = cost1 + cost2 + cost3 + cost4
master.minimize(master.obj)

#print(master.export_as_lp_string())

# Résolution
master_sol = master.solve(log_output = False)
rmp_obj = master_sol.get_objective_value()
objectives.append(rmp_obj)
print("RMP_obj = ",rmp_obj)
#master.print_information()
#master.print_solution()

#Sauvegarde des variables duales 
pi = master.dual_values(contraintes5)
pi.append(contrainte4.dual_value)
#print(pi)

col=SP_MIP(pi)
print(col)

i=2
stop=False
while(stop==False):
    print("\n")
    print("---------------- itération ",i, "----------------")
    pi=RMP(col)
   
    col=SP_MIP(pi)
    i+=1
    if col==0:
        stop=True
end_time = time.time()


#print("Évolution de l'objectif",objectives)

run_time = end_time - start_time

print("Temps d'exécution :", run_time, "secondes")
