# -*- encoding: utf-8 -*-

import numpy as np
from numpy import random as rd
from pulp import LpProblem, LpMinimize, LpVariable, LpBinary, lpSum, LpInteger


def get_problem(**kargs):
    T = kargs['T']                      # Period (0, 1, 2, ..., T-1)
    P = kargs['P']                      # Product (0, 1, 2, ..., P-1)
    alpha = kargs['alpha']              # Capacity reduction coefficient
    gamma = kargs['gamma']              # Relative decrease of capacity per set up
    beta = kargs['beta']                # Capacity reduction coefficient due to product types
    f = kargs['f']                      # Fixed production cost
    p = kargs['p']                      # Variable production cost
    h = kargs['h']                      # Inventory holding cost
    d = kargs['d']                      # Demand
    m = kargs['m']                      # Maintenance cost
    cmax = kargs['cmax']                # Maximum capacity
    complexity = kargs['complexity']    # Model choice
    cyclic = kargs['cyclic']            # Model choice

    # -- Problem creation
    problem = LpProblem("Integrated non-cyclic maintenance and production model", LpMinimize)

    # -- Variable creation

    # x - Lot size of product i in period t
    x = [[LpVariable('x_{}_{}'.format(i, t), cat=LpInteger, lowBound=0) for t in T] for i in P]

    # I - Inventory level of product i at the end of the period t
    I = [[LpVariable('I_{}_{}'.format(i, t), lowBound=0) for t in T] for i in P]

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

    # -- Objective creation
    problem += lpSum([lpSum([f[i][t] * y[i][t] + p[i][t] * x[i][t] + h[i][t] * I[i][t] for i in P]) + m[t]*z[t] for t in T])

    # -- Constraints creation
    # Constraint 2
    for i in P:
        for t in range(1, len(T)):
            problem += x[i][t] + I[i][t-1] == d[i][t] + I[i][t]
        problem += x[i][0] == d[i][0] + I[i][0]

    # Constraint 3
    for i in P:
        for t in T:
            problem += x[i][t] <= lpSum([d[i][s] for s in range(t, len(T))]) * y[i][t]

    # Constraint 4
    for t in T:
        problem += lpSum([x[i][t] for i in P]) <= c[t]

    # Constraint 8 or 11 and 14 combined
    for t in range(1, len(T)):
        if complexity:
            problem += c[t] <= alpha * c[t-1] - gamma * c_prime[t] - lpSum([beta[i] * x[i][t-1] for i in P]) + cmax * z[t]
        else:
            problem += c[t] <= alpha * c[t-1] + cmax * z[t]

    if complexity:
        # Constraint 12
        for i in P:
            for t in range(1, len(T)):
                problem += w[t] >= y[i][t] - y[i][t-1]

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

    # Wagner-Within Constraint
    for i in P:
        for t in range(1, len(T)):
            problem += I[i][t-1] >= lpSum([d[i][u] * (1 - lpSum([y[i][v] for v in range(t, u+1)])) for u in range(t, len(T))])

    # Constraints 6, 7, 10, 18 are defined during variables creation

    # print(problem)
    return problem
