import random as rd
import numpy as np


def gen_instance_one_product(T : int, fixed_instance = True,  verbose = False):
    if fixed_instance:
        rd.seed(12)
    period_set = range(T)
    alpha = float(round(rd.uniform(0.6, 0.9), 2))
    gamma = float(round(rd.uniform(0.2, 0.4), 2))
    set_up_cost = [rd.randint(0, 10) for _ in period_set]
    variable_prod_cost = [rd.randint(0, 10) for _ in period_set]
    inventory_cost = [rd.randint(0, 5) for _ in period_set]
    mtn_cost = [rd.randint(0, 50) for _ in period_set]
    demand = [rd.randint(0, 50) for _ in period_set]
    cmax = rd.randint(40, 50)
    if verbose: 
        print('Set of periods in the planning horizon T=' + str(T))
        print()
        print('Capacity reduction coefficient alpha = ' + str(alpha))
        print()
        print('Relative decrease of capacity per set up gamma = ' + str(gamma))
        print()
        print('Set_up cost in each period f = ' + str(np.array(set_up_cost)))
        print()
        print('Variable production cost per unit in each period p = ' + str(np.array(variable_prod_cost)))
        print()
        print('Inventory holding cost per unit by the end of each period h = ' + str(np.array(inventory_cost)))
        print()
        print('Demand in each period d = ' + str(np.array(demand)))
        print()
        print('Maintenance cost in each period m =  ' + str(mtn_cost))
        print()
        print('Maximum capacity of the machine cmax = ' + str(cmax))
        print()
    return {'T': T, 'period_set': period_set, 'alpha': alpha, 'gamma': gamma, 'set_up_cost': set_up_cost, 'variable_prod_cost': variable_prod_cost, 'inventory_cost': inventory_cost, 'demand': demand,
            'mtn_cost': mtn_cost, 'cmax': cmax}

