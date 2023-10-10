import numpy as np
import matplotlib.pyplot as plt

fig, axs = plt.subplots(1, 2, figsize=(10,5))

x_rfSize = np.linspace(5, 85, 17)
y_rfSize = [1.89, 1.53, 1.58, 1.42, 1.45, 1.39, 1.39, 1.39, 1.29, 1.31, 1.29, 1.30, 1.28, 1.31, 1.24, 1.31, 1.32]

axs[0].plot(x_rfSize, y_rfSize, "o-")

x_rfOverlap = np.linspace(0.2, 0.9, 8)
y_rfOverlap = [1.19, 1.24, 1.23, 1.20, 1.28, 1.22, 1.32, 1.35]
axs[1].plot(x_rfOverlap, y_rfOverlap, "o-")

plt.show() # affiche la figure à l'écran

