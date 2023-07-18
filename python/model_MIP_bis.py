import numpy as np 
from docplex.mp.model import Model

def initial_model_bis(instance_dict, pl):
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
        z = {(k,t):model.continuous_var(name=f'z_{k}_{t}') for k in T for t in range(k, len(T))}
    else:
        # y  - y_it = 1 if product i is produced in period t
        y = {(i,t):model.binary_var(name=f'y_{i}_{t}') for i in P for t in T}
        # z  - z_t = 1 if maintenance is performed during period t
        z = {(k,t):model.binary_var(name=f'z_{k}_{t}') for k in T for t in range(k, len(T))}


    # Add constraints 

    cts1_0 = model.add_constraints(x[i,0] == demand[i,0] + I[i,0] for i in P)

    cts1 = model.add_constraints(x[i,t] + I[i,t-1] == I[i,t] + demand[i,t] for i in P for t in range(1,len_T))

    cts2 = model.add_constraints(x[i,t] <= sum(demand[i,s] for s in range(t,len_T))*y[i,t] for i in P for t in T)

    cts3 = model.add_constraints(model.sum(x[i,t] for i in P) <= c[t] for t in T)

    cts4 = model.add_constraint(z[0,0] == 1)
    
    cts5 = model.add_constraints(c[t] == cmax * (model.sum(alpha**(t-k)* z[k,t] for k in range(t+1))) for t in T)

    cts6 = model.add_constraints(model.sum(z[k,t] for k in range(t+1)) <= 1 for t in T )

    cts7 = model.add_constraints(z[k,t] <= z[k,k] for k in T for t in range(k+1, len_T))


    #model.add_constraints(y[i,0] == 0 for i in P)

    #cts7 = model.add_constraints(sum(z[k,j] for j in range(k+1,t+1)) >= (t-k)*(z[k,k] - sum(z[u,u] for u in range(k+1,t+1))) for t in T for k in range(t))

    
    
    
    #Fonction objectif
    cost1 = sum(set_up_cost[i,t]*y[i,t] + variable_prod_cost[i,t]*x[i,t] + holding_cost[i,t]*I[i,t] for i in P for t in T)
    cost2 = sum(mtn_cost[t]*z[t,t] for t in T)

    model.obj = cost1 + cost2
    model.minimize(model.obj)

    #print(model.export_as_lp_string())
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
    sz = np.zeros((len_T,len_T))
    for t in T:
        for i in P:
            sy[i,t] = model_sol.get_value(y[i,t])
            sx[i,t] = model_sol.get_value(x[i,t])
            sI[i,t] = model_sol.get_value(I[i,t])
        for k in range(t+1):
            sz[k,t] = model_sol.get_value(z[k,t])
    
    
    sc = model_sol.get_values(c)

    #print(sum(sum(sz)))
    #print(sum([mtn_cost[t]*sz[t,t] for t in T]))

    
    #Output
    """
    for i in P:
            print('  Demand of product {}: {}'.format(i, demand[i]))
            print('  Product {} lot size: {}'.format(i, sx[i]))
            print('  Product {} inventory hold: {}'.format(i, sI[i]))
    print('  Maintenance performed at: {}'.format(sz))
    print('  Available capacity used: {}'.format(sc))
    """    
