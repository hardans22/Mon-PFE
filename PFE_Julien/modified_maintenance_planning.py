# -*- encoding: utf-8 -*-

import numpy as np
from numpy import random as rd
from pulp import LpProblem, LpMinimize, LpVariable, LpBinary, lpSum, LpInteger


def gen_instance(t, p, complexity=False, cyclic=False):
    T = range(t)
    P = range(p)
    alpha = float(round(rd.uniform(0.6, 0.9), 2))
    gamma = float(round(rd.uniform(0.2, 0.4), 2))
    beta = [float(round(rd.uniform(0.2, 0.4), 2)) for _ in P]
    matf = [[rd.randint(0, 1000) for _ in T] for _ in P]
    matp = [[rd.randint(0, 10) for _ in T] for _ in P]
    math = [[rd.randint(0, 5) for _ in T] for _ in P]
    matd = [[rd.randint(0, 50) for _ in T] for _ in P]
    m = [rd.randint(0, 100) for _ in T]
    cmax = p * rd.randint(40, 50)
    print('Set of periods in the planning horizon T=' + str(T))
    print()
    print('Set of products P = ' + str(P))
    print()
    print('Capacity reduction coefficient alpha = ' + str(alpha))
    print()
    print('Relative decrease of capacity per set up gamma = ' + str(gamma))
    print()
    print('Capacity reduction coefficient due to product types beta = ' + str(beta))
    print()
    print('Fixed production cost of each product in each period f = ' + str(np.array(matf)))
    print()
    print('Variable production cost per unit of each product in each period p = ' + str(np.array(matp)))
    print()
    print('Inventory holding cost per unit of each product by the end of each period h = ' + str(np.array(math)))
    print()
    print('Demand for each product in each period d = ' + str(np.array(matd)))
    print()
    print('Maintenance cost in each period m =  ' + str(m))
    print()
    print('Maximum capacity of the machine cmax = ' + str(cmax))
    print()
    return {'T': T, 'P': P, 'alpha': alpha, 'gamma': gamma, 'beta': beta, 'f': matf, 'p': matp, 'h': math, 'd': matd,
            'm': m, 'cmax': cmax, 'complexity': complexity, 'cyclic': cyclic}


def get_problem(**kargs):
    T = kargs['T']  # Period (0, 1, 2, ..., T-1)
    P = kargs['P']  # Product (0, 1, 2, ..., P-1)
    alpha = kargs['alpha']  # Capacity reduction coefficient
    gamma = kargs['gamma']  # Relative decrease of capacity per set up
    beta = kargs['beta']  # Capacity reduction coefficient due to product types
    f = kargs['f']  # Fixed production cost
    p = kargs['p']  # Variable production cost
    h = kargs['h']  # Inventory holding cost
    d = kargs['d']  # Demand
    m = kargs['m']  # Maintenance cost
    cmax = kargs['cmax']  # Maximum capacity
    complexity = kargs['complexity']  # Model choice
    cyclic = kargs['cyclic']  # Model choice

    # -- Problem creation
    problem = LpProblem("Integrated non-cyclic maintenance and production model", LpMinimize)

    # -- Variable creation

    K = []
    for t in T:
        K.append([(t, k) for k in range(t, len(T))])

    J = []
    for t in T:
        J.append([(l, t) for l in range(t + 1)])

    # x - x_ikt - Lot size of product i produced in period k for period t
    x = [[[LpVariable('x_{}_{}_{}'.format(i, j, t), cat=LpInteger, lowBound=0) for j, t in k] for k in K] for i in P]

    # c - Available capacity in period t
    c = [LpVariable('c_{}'.format(t), cat=LpInteger, lowBound=0, upBound=cmax) for t in T]

    # y  - y_it = 1 if product i is produced in period t
    y = [[LpVariable('y_{}_{}'.format(i, t), cat=LpBinary) for t in T] for i in P]

    # z  - z_t = 1 if maintenance is performed during period t
    z = [LpVariable('z_{}'.format(t), cat=LpBinary) for t in T]

    if complexity:
        # c'_t = c_t * w_t
        c_prime = [LpVariable('c_prime_{}'.format(t), lowBound=0) for t in T]

        # w - w_t = 1 if the equipment is started up in period t
        w = [LpVariable('w_{}'.format(t), cat=LpBinary) for t in T]

    cost = [[[sum(h[i][t:][:s]) for s in range(len(h[i][t:]))] for t in T] for i in P]

    # -- Objective creation
    problem += lpSum([lpSum([f[i][t] * y[i][t] + lpSum([(p[i][l - j] + cost[i][l - j][j]) * x[i][l - j][j]
                                                       for j, l in K[t]]) for t in T]) for i in P]) + lpSum([m[t] * z[t] for t in T])

    # -- Constraints creation
    # Constraint 2
    for i in P:
        for t in T:
            problem += lpSum([x[i][j][l - j] for j, l in J[t]]) == d[i][t]

    # Constraint 3
    for i in P:
        for t in T:
            problem += lpSum([x[i][j][l - j] for j, l in K[t]]) <= lpSum([d[i][s] for s in range(t, len(T))]) * y[i][t]

    # Constraint 4
    for t in T:
        problem += lpSum([lpSum([x[i][j][l - j] for j, l in K[t]]) for i in P]) <= c[t]

    # Constraint 8 or 11 and 14 combined
    if complexity:
        for t in range(1, len(T)):
            problem += c[t] <= alpha * c[t - 1] - gamma * c_prime[t] - \
                       lpSum([beta[i] * lpSum([x[i][j][l - j] for j, l in K[t-1]]) for i in P]) + cmax * z[t]
    else:
        for t in range(1, len(T)):
            problem += c[t] <= alpha * c[t - 1] + cmax * z[t]

    if complexity:
        # Constraint 12
        for i in P:
            for t in range(1, len(T)):
                problem += w[t] >= y[i][t] - y[i][t - 1]

        # Constraints 16, 17 and 19
        for t in T:
            problem += c_prime[t] <= c[t]
            problem += c_prime[t] <= cmax * w[t]
            problem += c_prime[t] >= c[t] - cmax * (1 - w[t])

    # Constraint given under Table 2
    problem += z[0] == 1

    if cyclic:
        # Constraint 27
        for t in T:
            for k in range(1, len(T)):
                if t + 2 * k <= len(T) - 1:
                    problem += z[t] + z[t + k] <= z[t + 2 * k] + 1

        # Constraint 28
        for t in T:
            for k in range(1, len(T)):
                if t - k >= 0 and t + k <= len(T) - 1:
                    problem += z[t] + z[t + k] <= z[t - k] + 1

    # Constraints 6, 7, 10, 18 are defined during variables creation


    # print(problem)
    return problem
