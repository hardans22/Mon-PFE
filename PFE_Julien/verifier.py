# -*- encoding: utf-8 -*-


def verify(T, P, d, f, p, h, m, x, I, c, y, z):
    """ Verify a solution.
    Params:
      - x: Lot size of product
      - I: Inventory level of product
      - c: Available capacity
      - y: Production of products or not
      - z: Maintenance actions or not.

    Return:
      - (False, X) if the verification failed, X contains information.
      - (True, O) if the verification succeed, O contains objective.
    """

    # Check that demands are satisfied.
    for i in P:
        for t in T:
            if x[i][t] + I[i][t-1] - (d[i][t] + I[i][t]) >= 0.01:
                return (False, 'Demand of product {} is not satisfied at period {}, {} + {} != {} + {}.'
                        .format(i, t, x[i][t], I[i][t-1], d[i][t], I[i][t]))

    # Check that production level is under the available capacity one
    for t in range(len(T)):
        if sum([x[i][t] for i in range(len(P))]) - c[t] >= 0.01:
            return (False, 'Overproduction at the period {}'.format(t))

    # Compute objective value.
    obj = 0
    for t in range(len(T)):
        cost = 0
        for i in range(len(P)):
            cost += f[i][t]*y[i][t] + p[i][t]*x[i][t] + h[i][t]*I[i][t]
        print('t='+str(t)+' cost='+str(cost))
        obj += cost + m[t]*z[t]

    return (True, obj)
