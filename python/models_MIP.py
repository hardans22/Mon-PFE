import numpy as np 
from docplex.mp.model import Model

def initial_model(instance_dict, pl):
    T = instance_dict["T"]
    P = instance_dict["P"]
    len_T = len(T)
    set_up_cost = np.array(instance_dict["set_up_cost"])
    variable_prod_cost = np.array(instance_dict["variable_prod_cost"])
    holding_cost = np.array(instance_dict["holding_cost"])
    demand = np.array(instance_dict["demand"])
    mtn_cost = instance_dict["mtn_cost"]
    cmax = instance_dict["cmax"]
    alpha = instance_dict["alpha"]
    
    model = Model("model_simple")
    #Create variable
    # x - Lot size of product i in period t
    x = {(i,t):model.continuous_var(name=f'x_{i}_{t}') for i in P for t in T}

    
    # I - Inventory level of product i at the end of the period t
    I = {(i,t):model.continuous_var(name=f'I_{i}_{t}') for i in P for t in T} 

    # c - Available capacity in period t
    c = model.continuous_var_list(T,name = "c")
    if pl:
        # y  - y_it = 1 if product i is produced in period t
        y = {(i,t):model.continuous_var(name=f'y_{i}_{t}') for i in P for t in T}

        # z  - z_t = 1 if maintenance is performed during period t  
        z = model.continuous_var_list(T, name = 'z')

    else:
        # y  - y_it = 1 if product i is produced in period t
        y = {(i,t):model.binary_var(name=f'y_{i}_{t}') for i in P for t in T}

        # z  - z_t = 1 if maintenance is performed during period t  
        z = model.binary_var_list(T, name = 'z')

    # Add constraints 
    cts1_0 = model.add_constraints(x[i,0] == demand[i,0] + I[i,0] for i in P)

    cts1 = model.add_constraints(x[i,t] + I[i,t-1] == I[i,t] + demand[i,t] for i in P for t in range(1,len_T))

    cts2 = model.add_constraints(x[i,t] <= sum(demand[i,s] for s in range(t,len_T))*y[i,t] for i in P for t in T)

    cts3 = model.add_constraints(model.sum(x[i,t] for i in P) <= c[t] for t in T)

    cts4 = model.add_constraints(c[t] <= cmax for t in T)

    cts5 = model.add_constraints(c[t] <= alpha * c[t-1] + cmax * z[t] for t in range(1,len(T)))
    
    cts_6 = model.add_constraint(z[0] == 1)
    
    #Fonction objectif
    cost1 = sum(set_up_cost[i,t]*y[i,t] + variable_prod_cost[i,t]*x[i,t] + holding_cost[i,t]*I[i,t] for i in P for t in T)
    cost2 = sum(mtn_cost[t]*z[t] for t in T)

    model.obj = cost1 + cost2
    model.minimize(model.obj)

    model.set_time_limit(180)
    
    model_sol = model.solve(log_output = True)
    mdl_time = model_sol.solve_details.time
    #print(mdl_time)
    mdl_obj = model_sol.get_objective_value()
    print("MIP_objective = ", mdl_obj)
    #model.print_solution()
    
    #Extraction
    len_T = len(T)
    len_P = len(P)
    sx = np.zeros((len_P,len_T))
    sy = np.zeros((len_P,len_T))
    sI = np.zeros((len_P, len_T))
    for i in P:
        for t in T:
            sy[i,t] = model_sol.get_value(y[i,t])
            sx[i,t] = model_sol.get_value(x[i,t])
            sI[i,t] = model_sol.get_value(I[i,t])
    
    sz = model_sol.get_values(z)
    sc = model_sol.get_values(c)

    plan_mtn_opt = [t for t in T if sz[t] != 0]
    #Output
    """
    for i in P:
            print('  Demand of product {}: {}'.format(i, demand[i]))
            print('  Product {} lot size: {}'.format(i, sx[i]))
            print('  Product {} inventory hold: {}'.format(i, sI[i]))
    print('  Maintenance performed at: {}'.format(sz))
    print('  Available capacity used: {}'.format(sc))
    """
    return plan_mtn_opt, mdl_obj
    

def initial_model_modified(instance_dict):
    T = instance_dict["T"]
    P = instance_dict["P"]
    set_up_cost = np.array(instance_dict["set_up_cost"])
    variable_prod_cost = np.array(instance_dict["variable_prod_cost"])
    holding_cost = np.array(instance_dict["holding_cost"])
    demand = np.array(instance_dict["demand"])
    mtn_cost = instance_dict["mtn_cost"]
    cmax = instance_dict["cmax"]
    alpha = instance_dict["alpha"]

    model = Model("model modified")
   
    # Create variables 
    x = {(i,k,t):model.integer_var(name=f'x_{i}_{k}_{t}') for i in P for k in T for t in range(k, len(T))} #lot variable
    y = {(i,t):model.binary_var(name=f'y_{i}_{t}') for i in P for t in T} #set_up variable
    c = model.continuous_var_list(T,name = "c") #capacity variable
    z = model.binary_var_list(T, name = 'z') #maintenance variable

    # Add constraints
    cts1 = model.add (model.sum(x[i,k,t] for k in range(t+1)) == demand[i,t] for i in P for t in T)
    cts2 = model.add_constraints(model.sum(x[i,t,k] for k in range(t, len(T))) <= sum(demand[i,s] for s in range(t,len(T)))*y[i,t] for i in P for t in T) 
    cts3 = model.add_constraints(model.sum(x[i,t,k] for i in P for k in range(t, len(T))) <= c[t] for t in T)    
    cts4 = model.add_constraints(c[t] <= cmax for t in T)
    cts5 = model.add_constraints(c[t] <= alpha*c[t-1] + cmax*z[t] for t in range(1,len(T)))

    model.add_constraint(z[0] == 1)

    #Fonction objectif
    cost1 = sum(set_up_cost[i,k]*y[i,k] for i in P for k in T)
    cost2 = sum(sum(variable_prod_cost[i,k]*x[i,k,t] for i in P for t in range(k,len(T))) for k in T)
    cost3 = sum(x[i,k,t]*sum(holding_cost[i,j] for j in range(k,t)) for i in P for k in T for t in range(k,len(T)))
    cost4 = sum(mtn_cost[t]*z[t] for t in T)

    model.obj = cost1 + cost2 + cost3 + cost4
    model.minimize(model.obj)

    model.set_time_limit(180)
    
    model_sol = model.solve(log_output = True)
    mdl_time = model_sol.solve_details.time
    #print(mdl_time)
    mdl_obj = model_sol.get_objective_value()
    print("MIP_objective = ", mdl_obj)
    #model.print_solution()
