# -*- encoding: utf-8 -*-
import os
import json
from numpy import random as rd


def gen_instance(t, p, fp=False, complexity=False, cyclic=False):
    if os.path.isfile(fp):
        T, P, alpha, gamma, beta, f, p, h, d, m, cmax = read_instance(fp)
        return {'T': T, 'P': P, 'alpha': alpha, 'gamma': gamma, 'beta': beta, 'f': f, 'p': p, 'h': h,
                 'd': d, 'm': m, 'cmax': cmax, 'complexity': complexity, 'cyclic': cyclic}

    else:
        T = range(t)
        P = range(p)
        alpha = float(round(rd.uniform(0.6, 0.9), 2))
        gamma = float(round(rd.uniform(0.2, 0.4), 2))
        beta = [float(round(rd.uniform(0.2, 0.4), 2)) for _ in P]
        matf = [[rd.randint(100*t, 500*t) for _ in T] for _ in P]
        matp = [[rd.randint(20, 30) for _ in T] for _ in P]
        math = [[rd.randint(10, 20) for _ in T] for _ in P]
        matd = [[rd.randint(5, 50) for _ in T] for _ in P]
        m = [rd.randint(1000*t, 5000*t) for _ in T]
        cmax = p * rd.randint(40, 50)
        if fp:
            file = open(fp, "w+")
            file.write('Set of periods in the planning horizon T: \n' + str(t) + '\n' +
                     'Set of products P: \n' + str(p) + '\n' +
                     'Capacity reduction coefficient alpha: \n' + str(alpha) + '\n' +
                     'Relative decrease of capacity per set up gamma: \n' + str(gamma) + '\n' +
                     'Capacity reduction coefficient due to product types beta: \n' + str(beta) + '\n' +
                     'Fixed production cost of each product in each period f: \n' +
                       json.dumps(matf) + '\n' +
                     'Variable production cost per unit of each product in each period p: \n' +
                       json.dumps(matp) + '\n' +
                     'Inventory holding cost per unit of each product by the end of each period h: \n' +
                       json.dumps(math) + '\n' +
                     'Demand for each product in each period d: \n' +
                       json.dumps(matd) + '\n' +
                     'Maintenance cost in each period m: \n' + str(m) + '\n' +
                     'Maximum capacity of the machine cmax: \n' + str(cmax))

            print(file.read())
            file.close()

    return {'T': T, 'P': P, 'alpha': alpha, 'gamma': gamma, 'beta': beta, 'f': matf, 'p': matp, 'h': math, 'd': matd,
            'm': m, 'cmax': cmax, 'complexity': complexity, 'cyclic': cyclic}


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
    print(data)
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
