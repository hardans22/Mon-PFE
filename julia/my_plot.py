import numpy as np 
import matplotlib.pyplot as plt 

def f(u):
    beta = 2
    gamma = 2
    c = 1
    z_prime = u - c
    return beta*u + gamma*z_prime

def f1(u):
    cmax = 410
    alpha = 2
    if 0 <= u <= cmax:
        return alpha*u
    else:
        return alpha*5*u
     
x = np.linspace(0,1000, 20)
y = [f1(i) for i in x]
print(x)
plt.plot(x,y)
plt.show()
