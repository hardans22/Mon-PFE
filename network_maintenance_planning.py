# -*- encoding: utf-8 -*-
from pulp import LpProblem, LpMinimize, LpVariable, LpBinary, lpSum, LpInteger


def get_problem(**kargs):
    T = kargs['T']                      # Period (0, 1, 2, ..., T-1)
    P = kargs['P']                      # Product (0, 1, 2, ..., P-1)
    alpha = kargs['alpha']              # Capacity reduction coefficient
    gamma = kargs['gamma']              # Relative decrease of capacity per set up
    beta = kargs['beta']                # Capacity reduction coefficient due to product types
    f = kargs['setup_cost']             # Fixed production cost
    p = kargs['variable_prod_cost']     # Variable production cost
    h = kargs['holding_cost']           # Inventory holding cost
    d = kargs['demand']                 # Demand
    m = kargs['mtn_cost']               # Maintenance cost
    cmax = kargs['cmax']                # Maximum capacity
    complexity = kargs['complexity']    # Model choice
    cyclic = kargs['cyclic']            # Model choice
    extended = kargs['extended']        # Model choice
    len_T = len(T)                     # Number of periods

    # -- Problem creation
    problem = LpProblem("Network_Model_Complexity:{}_Cyclic:{}_Extended:{}".format(complexity, cyclic, extended),
                        LpMinimize)

    # -- Variable creation
    # x - x_it - Lot size of product i produced in period t
    x = [[LpVariable('x_{}_{}'.format(i, t), lowBound=0) for t in T] for i in P]

    # phi - phi_ikt - Percentage of demands of product i between periods k and t satisfied in period k
    phi = [[[LpVariable('phi_{}_{}_{}'.format(i, k, t), lowBound=0) for t in range(k, len_T)] for k in T] for i in P]

    # c - Available capacity in period t
    c = [LpVariable('c_{}'.format(t), lowBound=0, upBound=cmax) for t in T]

    # y  - y_it = 1 if product i is produced in period t
    y = [[LpVariable('y_{}_{}'.format(i, t), cat=LpBinary) for t in T] for i in P]

    if extended:
        # z  - z_kt = 1 if last maintenance at period t was performed at period k
        z = [[LpVariable('z_{}_{}'.format(k, t), cat=LpBinary) for t in range(k, len_T)] for k in T]
    else:
        # z  - z_t = 1 if maintenance is performed during period t
        z = [LpVariable('z_{}'.format(t), cat=LpBinary) for t in T]

    if complexity:
        # c'_t = c_t * w_t
        c_prime = [LpVariable('c_prime_{}'.format(t), lowBound=0) for t in T]

        # w - w_t = 1 if the equipment is started up in period t
        w = [LpVariable('w_{}'.format(t), cat=LpBinary) for t in T]

    # -- Objective creation
    if extended:
        problem += lpSum([lpSum([f[i][t] * y[i][t] + (p[i][t] + lpSum(h[i][t:])) * x[i][t] - h[i][t] * lpSum(d[i][:t+1])
                                 for t in T]) for i in P]) + lpSum([m[t] * z[t][0] for t in T])
    else:
        problem += lpSum([lpSum([f[i][t] * y[i][t] + (p[i][t] + lpSum(h[i][t:])) * x[i][t] - h[i][t] * lpSum(d[i][:t+1])
                                 for t in T]) for i in P]) + lpSum([m[t] * z[t] for t in T])

    # -- Constraints creation
    # Constraint 2
    for i in P:
        problem += -lpSum(phi[i][0]) == -1
        problem += lpSum(phi[i][k][-1] for k in T) == 1

        for t in range(1, len_T):
            problem += lpSum(phi[i][u][t - u - 1] for u in range(t)) - lpSum(phi[i][t]) == 0

    # Constraint 3
    for i in P:
        for t in T:
            problem += lpSum(phi[i][t][to - t] if sum(d[i][t:to+1]) > 0 else 0 for to in range(t, len_T)) <= y[i][t]

    for i in P:
        for t in T:
            problem += lpSum([lpSum(d[i][t:k+1]) * phi[i][t][k - t] for k in range(t, len_T)]) == x[i][t]

    for t in T:
        problem += lpSum([x[i][t] for i in P]) <= c[t]

    # Constraint
    if complexity:
        if extended:
            for t in range(1, len_T):
                problem += c[t] <= cmax * lpSum(alpha ** (t - k) * z[k][t - k] for k in range(t+1)) \
                       - gamma * c_prime[t] - lpSum([beta[i] * x[i][t-1] for i in P])
        else:
            for t in range(1, len_T):
                problem += c[t] <= alpha * c[t-1] - gamma * c_prime[t] - lpSum([beta[i] * x[i][t-1] for i in P]) + cmax * z[t]
    else:
        if extended:
            for t in T:
                problem += c[t] <= cmax * lpSum(alpha ** (t - k) * z[k][t - k] for k in range(t+1))
        else:
            for t in range(1, len_T):
                problem += c[t] <= alpha * c[t-1] + cmax * z[t]

    if extended:
        for k in T:
            for t in range(k+1, len_T):
                problem += z[k][t - k] <= z[k][0]

        for t in T:
            problem += lpSum(z[k][t - k] for k in range(t+1)) <= 1

    if complexity:
        # Constraint 12
        for i in P:
            for t in range(1, len_T):
                problem += w[t] >= y[i][t] - y[i][t-1]

        # Constraints 16, 17 and 19
        for t in T:
            problem += c_prime[t] <= c[t]
            problem += c_prime[t] <= cmax * w[t]
            problem += c_prime[t] >= c[t] - cmax * (1 - w[t])

    # Constraint given under Table 2
    if extended:
        problem += z[0][0] == 1
    else:
        problem += z[0] == 1

    if cyclic:
        # Constraint 27
        if extended:
            for t in T:
                for k in range(1, len_T):
                    if t + 2 * k <= len_T - 1:
                        problem += z[t][0] + z[t + k][0] <= z[t + 2 * k][0] + 1
        else:
            for t in T:
                for k in range(1, len_T):
                    if t + 2 * k <= len_T - 1:
                        problem += z[t] + z[t + k] <= z[t + 2 * k] + 1

        # Constraint 28
        if extended:
            for t in T:
                for k in range(1, len_T):
                    if t - k >= 0 and t + k <= len_T - 1:
                        problem += z[t][0] + z[t + k][0] <= z[t - k][0] + 1
        else:
            for t in T:
                for k in range(1, len_T):
                    if t - k >= 0 and t + k <= len_T - 1:
                        problem += z[t] + z[t + k] <= z[t - k] + 1

    # Wagner-Whitin Constraint
    for i in P:
        for t in range(1, len_T):
            for l in range(t, len_T):
                problem += lpSum(x[i][:t]) - lpSum(d[i][:t]) >= lpSum([d[i][j] * (1 - lpSum(y[i][t:j+1]))
                                                                       for j in range(t, l+1)])

    # print(problem)
    return problem
