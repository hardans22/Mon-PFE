# -*- encoding: utf-8 -*-
import os
import json
import numpy as np
from numpy import random as rd


def gen_instance(p, t, fp=False, complexity=False, cyclic=False):
    if os.path.isfile(fp):
        T, P, alpha, gamma, beta, set_up_cost,variable_prod_cost, holding_cost, demand, mtn_cost, cmax = read_instance(fp)

    else:
        T = range(t)
        P = range(p)
        alpha = float(0.8)
        gamma = float(round(rd.uniform(0.2, 0.4), 2))
        beta = [float(round(rd.uniform(0.2, 0.4), 2)) for _ in P]

        set_up_cost = [[rd.randint(500, 1000) for _ in T] for _ in P]
        variable_prod_cost = [[rd.randint(10, 14) for _ in T] for _ in P]
        holding_cost = [[rd.randint(5, 10) for _ in T] for _ in P]
        temp = int(p/3)
        p_A = int(0.15*p)
        p_B = int(0.25*p)
        p_C = p - p_A - p_B
        demand_A = [[rd.randint(0, 50) if rd.random() >= 0.05 else 0 for _ in T] for _ in range(p_A)]
        demand_B = [[rd.randint(0, 30) if rd.random() >= 0.05 else 0 for _ in T] for _ in range(p_B)]
        demand_C = [[rd.randint(0, 10) if rd.random() >= 0.05 else 0 for _ in T] for _ in range(p_C)]
        demand = np.concatenate((np.array(demand_A), np.array(demand_B), np.array(demand_C)), axis = 0)
        #print(demand)
        demand = demand.tolist()

        #demand = [[rd.randint(0, 50) if rd.random() >= 0.05 else 0 for _ in T] for _ in P]
        mtn_cost = [rd.randint(1000 + 3 * p * t, 5000 + 3 * p * t) for _ in T]
        cmax = p * rd.randint(40, 50)
        if fp:
            file = open(fp, "w+")
            file.write('Set of periods in the planning horizon T: \n' + str(t) + '\n' +
                     'Set of products P: \n' + str(p) + '\n' +
                     'Capacity reduction coefficient alpha: \n' + str(alpha) + '\n' +
                     'Relative decrease of capacity per set up gamma: \n' + str(gamma) + '\n' +
                     'Capacity reduction coefficient due to product types beta: \n' + str(beta) + '\n' +
                     'Fixed production cost of each product in each period f: \n' +
                       json.dumps(set_up_cost) + '\n' +
                     'Variable production cost per unit of each product in each period p: \n' +
                       json.dumps(variable_prod_cost) + '\n' +
                     'Inventory holding cost per unit of each product by the end of each period h: \n' +
                       json.dumps(holding_cost) + '\n' +
                     'Demand for each product in each period d: \n' +
                       json.dumps(demand) + '\n' +
                     'Maintenance cost in each period m: \n' + str(mtn_cost) + '\n' +
                     'Maximum capacity of the machine cmax: \n' + str(cmax))

            print(file.read())
            file.close()

    return {'T': T, 'P': P, 'alpha': alpha, 'gamma': gamma, 'beta': beta, 'set_up_cost': set_up_cost, 'variable_prod_cost': variable_prod_cost, 
            'holding_cost': holding_cost, 'demand': demand , 'mtn_cost': mtn_cost, 'cmax': cmax, 'complexity': complexity, 'cyclic': cyclic}

def read_instance(fp):
    """ Read an instance from the specified filename.

    >>> fp = open('instances/instance1.txt')
    >>> t, n, a, b, f, p, h, d, m, cmax = read_instance(fp)

    Return values:
      - t (int): Number of periods.
      - n (int): Number of products.
      - a (int): Capacity reduction coefficient.
      - f (list x list): Fixed production cost.
      - p (list x list): Variable production cost.
      - h (list x list): Inventory holding cost.
      - d (list x list): Demand.
      - m (list): Maintenance cost.
      - cmax (int): Maximum capacity.

    """
    file = open(fp)
    data = file.read()
    file.close()
    #print(data)
    data = data.split("\n")
    t = int(data[1])
    p = int(data[3])
    alpha = float(data[5])
    gamma = float(data[7])
    beta = json.loads(data[9])

    matf = json.loads(data[11])
    matp = json.loads(data[13])
    math = json.loads(data[15])
    matd = json.loads(data[17])

    m = json.loads(data[-3])
    cmax = int(data[-1])

    return range(t), range(p), alpha, gamma, beta, matf, matp, math, matd, m, cmax
