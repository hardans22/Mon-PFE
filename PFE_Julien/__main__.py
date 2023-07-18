from functions import gen_instance
import initial_maintenance_planning as imp
import modified_maintenance_planning as mmp
import network_maintenance_planning as nmp
import pulp
from pulp import LpStatus
import initial_verifier as iv
import modified_verifier as mv

print(pulp.listSolvers(onlyAvailable=True))

NUMBER_OF_DIFFERENT_PRODUCTS = 2
NUMBER_OF_PERIODS = 10
FILE_PATH = "instances/rd_instance{}_{}.txt".format(NUMBER_OF_DIFFERENT_PRODUCTS, NUMBER_OF_PERIODS)
MODEL = "Network"
COMPLEXITY = False
CYCLIC = False

if __name__ == '__main__':

    kargs = gen_instance(NUMBER_OF_PERIODS, NUMBER_OF_DIFFERENT_PRODUCTS, fp=FILE_PATH, complexity=COMPLEXITY, cyclic=CYCLIC)

    if MODEL == "Modified":
        problem1 = mmp.get_problem(**kargs)

        status1 = problem1.solve(pulp.CPLEX_PY(msg=True, timeLimit=600))
        print('Status: ', LpStatus[problem1.status])

        print('Objective: ', problem1.objective.value())
        print()

        variables = problem1.variablesDict()
        # print(variables)

        # Results recuperation
        T, P = kargs['T'], kargs['P']

        c = [round(variables['c_{}'.format(t)].value()) for t in T]
        x = [[[round(variables['x_{}_{}_{}'.format(i, k, t)].value()) for t in range(k, len(T))] for k in T] for i in P]
        y = [[round(variables['y_{}_{}'.format(i, t)].value()) for t in T] for i in P]
        z = [round(variables['z_{}'.format(t)].value()) for t in T]

        # Output
        for i in P:
            print('  Demand of product {}: {}'.format(i, kargs['d'][i]))
            print('  Product {} lot size: {}'.format(i, [sum([x[i][k][t - k] for t in range(k, len(T))]) for k in T]))
            print('  Product {} inventory hold: {}'.format(i, [sum([sum([x[i][j][t - j] for t in range(k+1, len(T))]) for j in range(k+1)]) for k in T]))
        print('  Maintenance performed at: {}'.format(z))
        print('  Available capacity used: {}'.format(c))

        print(mv.verify(T, P, kargs['d'], kargs['f'], kargs['p'], kargs['h'], kargs['m'], x, c, y, z))

    if MODEL == "Network":
        problem2 = nmp.get_problem(**kargs)
        status2 = problem2.solve(pulp.CPLEX_PY(msg=True, timeLimit=600))
        print('Status: ', LpStatus[problem2.status])

        print('Objective: ', problem2.objective.value())
        print()

        variables = problem2.variablesDict()
        # print(variables)

        # Results recuperation
        T, P = kargs['T'], kargs['P']
        c = [round(variables['c_{}'.format(t)].value()) for t in T]
        x = [[round(variables['x_{}_{}'.format(i, t)].value()) for t in T] for i in P]
        phi = [[[round(variables['phi_{}_{}_{}'.format(i, k, t)]) for t in range(k, len(T))] for k in T] for i in P]
        y = [[round(variables['y_{}_{}'.format(i, t)].value()) for t in T] for i in P]
        z = [round(variables['z_{}'.format(t)].value()) for t in T]

        # Output
        for i in P:
            print('  Demand of product {}: {}'.format(i, kargs['d'][i]))
            print('  Product {} lot size: {}'.format(i, x[i]))
            print('  Product {} inventory hold: {}'.format(i, sum([sum([d[i][k] * phi[i][t][k - t] for k in range(t, len(T))]) for t in T])))
        print('  Maintenance performed at: {}'.format(z))
        print('  Available capacity used: {}'.format(c))

        print(iv.verify(T, P, kargs['d'], kargs['f'], kargs['p'], kargs['h'], kargs['m'], x, I, c, y, z))

    else:
        problem3 = imp.get_problem(**kargs)
        status3 = problem3.solve(pulp.CPLEX_PY(msg=True, timeLimit=600))
        print('Status: ', LpStatus[problem3.status])

        print('Objective: ', problem3.objective.value())
        print()

        variables = problem3.variablesDict()
        # print(variables)

        # Results recuperation
        T, P = kargs['T'], kargs['P']
        c = [round(variables['c_{}'.format(t)].value()) for t in T]
        x = [[round(variables['x_{}_{}'.format(i, t)].value()) for t in T] for i in P]
        y = [[round(variables['y_{}_{}'.format(i, t)].value()) for t in T] for i in P]
        I = [[round(variables['I_{}_{}'.format(i, t)].value()) for t in T] for i in P]
        z = [round(variables['z_{}'.format(t)].value()) for t in T]

        # Output
        for i in P:
            print('  Demand of product {}: {}'.format(i, kargs['d'][i]))
            print('  Product {} lot size: {}'.format(i, x[i]))
            print('  Product {} inventory hold: {}'.format(i, I[i]))
        print('  Maintenance performed at: {}'.format(z))
        print('  Available capacity used: {}'.format(c))

        print(iv.verify(T, P, kargs['d'], kargs['f'], kargs['p'], kargs['h'], kargs['m'], x, I, c, y, z))
