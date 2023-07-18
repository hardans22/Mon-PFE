import numpy as np

def verify_one_product(instance_dict, x, y, z, c):
    T = instance_dict['T']
    demand = instance_dict["demand"]
    period_set = instance_dict["period_set"]
    temp1 = [sum(x[k,t] for k in range(t+1)) == demand[t] for t in period_set]
    temp3 = [sum(x[k,t] for t in range(k,T)) <= c[k] for k in period_set]
    temp4 = sum(z)
    if sum(temp1) == T:
        print("Constraint 1 is satisfied")
    
    if sum(temp3) == T:
        print("Constraint 3 is satisfied")
    if temp4 == 1:
        print("Constraint 4 is satisfied")

    