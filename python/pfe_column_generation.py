import numpy as np 
from docplex.mp.model import Model
import random as rd
import time 


def create_column_generation_model(instance_dict : dict, verbose = False):
    start_time = time.time()
    T = instance_dict["T"]
    P = instance_dict["P"]
    len_T = len(T)
    set_up_cost = np.array(instance_dict["set_up_cost"])
    variable_prod_cost = np.array(instance_dict["variable_prod_cost"])
    holding_cost = np.array(instance_dict["holding_cost"])
    demand = np.array(instance_dict["demand"])

    # Create optimization model
    master = Model(name="clspm")

    # Create variables 
    # x - Lot size of product i in period t
    x = {(i,t):master.continuous_var(name=f'x_{i}_{t}') for i in P for t in T}

    # y  - y_it = 1 if product i is produced in period t
    y = {(i,t):master.continuous_var(name=f'y_{i}_{t}') for i in P for t in T}

    # I - Inventory level of product i at the end of the period t
    I = {(i,t):master.continuous_var(name=f'I_{i}_{t}') for i in P for t in T} 

    # c - Available capacity in period t
    c = master.continuous_var_list(T,name = "c")

    # z  - z_t = 1 if maintenance is performed during period t
    z = master.continuous_var_list(1, lb=0.0, ub=1.0, name = 'z') #maintenance variable

    # Add constraints
    cts1_0 = master.add_constraints(x[i,0] == demand[i,0] + I[i,0] for i in P)

    cts1 = master.add_constraints(x[i,t] + I[i,t-1] == I[i,t] + demand[i,t] for i in P for t in range(1,len_T))

    cts2 = master.add_constraints(x[i,t] <= sum(demand[i,s] for s in range(t,len_T))*y[i,t] for i in P for t in T)

    cts3 = master.add_constraints(master.sum(x[i,t] for i in P) <= c[t] for t in T)
   
    ct4 = master.add_constraint(z[0] == 1)

    #Fonction objectif
    cost = sum(set_up_cost[i,t]*y[i,t] + variable_prod_cost[i,t]*x[i,t] + holding_cost[i,t]*I[i,t] for i in P for t in T)

    master.obj = cost
    master.minimize(master.obj)

    if verbose: 
        print(master.export_as_lp_string())
    
    variables_dict = {"x": x, "I": I, "y": y, "c": c, "z" : z}
    constraints_dict = {"cts1_0":cts1_0, "cts1":cts1, "cts2":cts2, "cts3":cts3, "ct4" : ct4}
    end_time = time.time()
    tim = end_time - start_time
    #print(tim)
    return master, variables_dict, constraints_dict




def run_column_generation(instance_dict, master, master_variables, master_constraints, first_column, nb_iteration, sp_method, epsilon, var_delete_proba = 0.3, verbose = False):
    T = instance_dict["T"]
    P = instance_dict["P"]
    len_T = len(T)
    len_P = len(P)
    mtn_cost = instance_dict["mtn_cost"]
    demand = np.array(instance_dict["demand"])
    mtn_columns = []
    capacities_colunms = []
    Mc_columns = []

    #Model update with the initial column 
    z_initial = first_column["z"]
    capacities = first_column['c']
    Mc = first_column["Mc"]
    mtn_columns.append(z_initial)
    capacities_colunms.append(capacities)
    Mc_columns.append(Mc)
    cts5 = master.add_constraints(master_variables['c'][t] == capacities[t]*master_variables["z"][0] for t in T)  #A CHECKER
    master_constraints["cts5"] = cts5
    master.obj += Mc*master_variables['z'][-1] ######### possible problème après 
    master.minimize(master.obj)
    
    stop = [mtn_cost[0]*100]
    master_objectives = [] 
    sp_objectives = []
    best_bounds = []
    rmp_run_time = []
    sp_run_time = []
    new_cols = []
    start_time = time.time()
    for inter_index in range(nb_iteration):        
        # Solve master 
        master_sol = master.solve(log_output = False)
        rmp_time = master_sol.solve_details.time
        rmp_run_time.append(rmp_time)
        #print("RMP resolution time : ", rmp_time)
        master_obj = master_sol.get_objective_value()
        master_objectives.append(master_obj)
        # Dual values
        
        pi = master.dual_values(master_constraints["cts5"])
        pi.insert(0,master_constraints["ct4"].dual_value)
        if verbose:
            print("\n---------------- itération ",inter_index, "----------------")
            print("RMP_obj = ",master_obj)
            print("pi = ", pi)

        u = np.array(master.dual_values(master_constraints["cts1_0"]))
        
        v = np.array(master.dual_values(master_constraints["cts1"]))

        v = np.reshape(v, (len_P,len_T-1))
        temp1 = 0
        for i in P:
            for t in range(1,len_T):
                temp1 += v[i,t-1]*demand[i,t]

        temp2 = np.dot(u, demand[:,0]) + temp1

        
        rmp_obj_bis = temp2 + pi[0]
        #print("RMP_OBJ_BIS = ", rmp_obj_bis)

        #RÉSOLUTION DU SP
        if sp_method == "MIP":
            column = sp_MIP(instance_dict, pi, verbose)
        if sp_method == "PD":
            column = prog_dynamic(instance_dict, pi, verbose)

        if column == 0 :
            print("RMP optimal")
            sp_objectives.append(sp_obj)
            sp_run_time.append(sp_time)
            break
        
        else:
            szt = column["z"]
            sct = column["c"]
            sp_obj = column["obj"]
            sp_time = column["sp_time"]
            new_col = column['new_col']
            
            Mc = sum(mtn_cost[t]*szt[t]for t in T)
            
            best_b = temp2 + sp_obj + pi[0]
            best_bounds.append(best_b)
            if verbose:
                print("BEST_BOUND = ", best_b) 
            mtn_columns.append(szt)
            capacities_colunms.append(sct)
            Mc_columns.append(Mc)
            new_cols.append(new_col)

            # Add the new colonne to master 
            #Définition de la nouvelle variable
            master_variables["z"].append(master.continuous_var(0.0, 1.0,name='z_'+str(len(master_variables['z']))))
            
            #Ajout à la contrainte de somme des z == 1
            master_constraints["ct4"].left_expr += master_variables["z"][-1]

            #Ajout à la contrainte de capacités
            for t in T:
                master_constraints["cts5"][t].right_expr += sct[t]*master_variables["z"][-1]
            
            #Ajout à la fonction objective
            master.obj += Mc*master_variables["z"][-1]
            
            stop.append(master_obj + sp_obj)
            sp_objectives.append(sp_obj)
            sp_run_time.append(sp_time)
    
        #print(abs(master_obj - best_b))
        if abs(master_obj - best_b) <= epsilon:
            print("STOP")
            break
    #best_bounds.append(best_b)
    end_time = time.time()
    cg_time = end_time - start_time
    sx = np.zeros((len_P,len_T))
    sy = np.zeros((len_P,len_T))
    sI = np.zeros((len_P, len_T))
    for i in P:
        for t in T:
            sy[i,t] = master_sol.get_value(master_variables["y"][i,t])
            sx[i,t] = master_sol.get_value(master_variables["x"][i,t])
            sI[i,t] = master_sol.get_value(master_variables["I"][i,t])
    
    sz = master_sol.get_values(master_variables["z"])
    sc = master_sol.get_values(master_variables["z"])
    
    master_sol_dict = {'x':sx, "I": sI, 'y':sy, 'z':sz, 'c':sc, 'obj':master_objectives[-1]}

    #print(stop)
    return inter_index, master_objectives, sp_objectives, best_bounds, new_cols, master_sol_dict, rmp_run_time, sp_run_time, cg_time


def sp_MIP(instance_dict, pi, verbose = False):
    T = instance_dict["T"]
    len_T = len(T)
    mtn_cost = instance_dict["mtn_cost"]
    cmax = instance_dict["cmax"]
    alpha = instance_dict["alpha"]

    # Pricing model
    pricing = Model(name = "sous_probleme")
    zt = pricing.binary_var_list(T, name = "zt")
    ct = pricing.continuous_var_list(T, name = 'ct')
    ct0 = pricing.add_constraint(zt[0] == 1)
    ct1 = pricing.add_constraints(ct[t] <= cmax for t in T)
    ct2 = pricing.add_constraints(ct[t] <= alpha*ct[t-1] + cmax*zt[t] for t in range(1,len_T))
    ct3_0 = pricing.add_constraint(ct[0] == cmax)
    ct3 = pricing.add_constraints(ct[t] >= alpha*ct[t-1] for t in range(1,len_T))

    # Solve pricing problem
    pricing.obj = sum(mtn_cost[t]*zt[t] + pi[t+1]*ct[t] for t in T) - pi[0]

    pricing.minimize(pricing.obj)

    pricing_sol = pricing.solve(log_output = False)
    pricing_obj = pricing_sol.get_objective_value()
    sp_time = pricing_sol.solve_details.time
    
    #print("SP resolution time : ", sp_time)
    Z_SP = pricing_sol.get_objective_value()
    if verbose:
        print("Z_SP =" ,Z_SP)
    #condition d'arrêt
    
    if Z_SP >=0 :
        if verbose:
            print("RMP optimal")
        return 0
    else:
        c_opt= pricing_sol.get_values(ct)
        z_opt = pricing_sol.get_values(zt)
        new_col = [t for t in T if z_opt[t] != 0]
        Mc = sum(mtn_cost[t]*z_opt[t]for t in T)
        if verbose:
            print("nouvelle colonne : ",new_col, "avec un coût de :", Mc)
            print("Capacité associées : ", c_opt)
        return {"z": z_opt, "c": c_opt, "obj": Z_SP, "sp_time" : sp_time, "new_col" : new_col}
    

def prog_dynamic(instance_dict, pi, verbose = False):
    T = instance_dict["T"]
    len_T = len(T)
    mtn_cost = instance_dict["mtn_cost"]
    cmax = instance_dict["cmax"]
    alpha = instance_dict["alpha"]
    pi_0 = pi[0]
    pi = pi[1:]

    start_time = time.time()

    cases_per_period = dict()  #contient toutes les cases par période
    cases_per_period[0] = np.array([mtn_cost[0] + pi[0]*cmax]) #La seule case de la période 0 contient que 0 
    
    min_path_index = []  #Permet de récupérer le chemin des min séléctionnés, le min pour période t est à la position t-1 dans la liste 
    
    

    for t in range(1,len_T):
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
        
    
    index_opt = np.argmin(cases_per_period[len_T-1])
    #print("index = ",index_opt)
    obj_opt = cases_per_period[len_T-1][index_opt] - pi_0
    #print('Optimal = ', obj_opt)

    #Construction de la solution i.e z et c
    index = index_opt
    period  = len_T-1
    z_opt = np.zeros(len_T)
    z_opt[0] = 1
    c_opt = [0. for _ in T]
    c_opt[0] = cmax
    while period != 0:
        if index == 0: 
            z_opt[period] = 1
            c_opt[period] = float(cmax)
            index = min_path_index[period-1]
            period -= 1

        else :
            period -= index
            z_opt[period] = 1
            for i in range(1, index+1):
                temp = alpha**i
                c_opt[period+i] = temp*cmax
            c_opt[period] = float(cmax)
            index = 0
    
    end_time = time.time()
    
    sp_time = end_time - start_time
    if verbose:
            print("sp_obj = ", obj_opt)
    if obj_opt >= 0:
        return 0
    else:
        new_col = [t for t in T if z_opt[t] != 0]
        Mc = sum(mtn_cost[t]*z_opt[t]for t in T)
        if verbose :
            print("nouvelle colonne : ",new_col, "avec un coût de : ", Mc)
            print("Capacité associées : ", c_opt)
        return {"z": z_opt, "c": c_opt, "obj": obj_opt, "sp_time" : sp_time, "new_col" : new_col}
    

            
