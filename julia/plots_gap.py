import numpy as np
import matplotlib.pyplot as plt
import pandas as pd 

rfSize = [215, 215, 215, 215, 215, 250, 250, 250, 250, 250, 285, 285, 285, 285, 285, 320, 320, 320, 320, 320, 355, 355, 355, 355, 355, 390, 390, 390, 390, 390, 425, 425, 425, 425, 425, 460, 460, 460, 460, 460, 495, 495, 495, 495, 495, 530, 530, 530, 530, 530, 565, 565, 565, 565, 565, 600, 600, 600, 600, 600, 635, 635, 635, 635, 635, 670, 670, 670, 670, 670, 705, 705, 705, 705, 705, 740, 740, 740, 740, 740, 775, 775, 775, 775, 775, 810, 810, 810, 810, 810, 845, 845, 845, 845, 845, 880, 880, 880, 880, 880, 915, 915, 915, 915, 915, 950, 950, 950, 950, 950, 985, 985, 985, 985, 985]

category = {'0.2':0, '0.3':1, '0.4':2, '0.5':3, '0.6':4} # Numéroter les catégories

col = {'0.2':'green', '0.3':'yellow', '0.4':'blue', '0.5':'pink', '0.6':'red'} # Définition des colorations par catégories

cex = {'0.2':30, '0.3':30, '0.4':30, '0.5':30, '0.6':30}  #Définition des tailles de points par catégories

rfOverlap = ["0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6"]

fig, ax = plt.subplots(figsize=(10, 7))



#----------------------GAPS---------------------
#Parcouurs Horizontal
gap = [0.85, 0.92, 0.94, 0.97, 0.99, 0.76, 0.79, 0.84, 0.91, 0.9, 0.64, 0.66, 0.71, 0.74, 0.86, 0.6, 0.63, 0.65, 0.74, 0.75, 0.47, 0.55, 0.56, 0.61, 0.66, 0.41, 0.43, 0.5, 0.53, 0.6, 0.36, 0.38, 0.45, 0.52, 0.56, 0.33, 0.37, 0.4, 0.44, 0.45, 0.26, 0.3, 0.34, 0.35, 0.43, 0.2, 0.2, 0.26, 0.28, 0.36, 0.19, 0.2, 0.23, 0.29, 0.36, 0.16, 0.19, 0.2, 0.28, 0.34, 0.14, 0.16, 0.21, 0.25, 0.29, 0.12, 0.15, 0.19, 0.22, 0.28, 0.11, 0.12, 0.17, 0.19, 0.24, 0.1, 0.11, 0.14, 0.17, 0.21, 0.08, 0.09, 0.12, 0.14, 0.18, 0.06, 0.07, 0.09, 0.11, 0.12, 0.03, 0.04, 0.05, 0.07, 0.08, 0.02, 0.02, 0.04, 0.05, 0.06, 0.02, 0.03, 0.03, 0.04, 0.05, 0.01, 0.01, 0.02, 0.02, 0.03, 0.0, 0.01, 0.01, 0.01, 0.02]

compil = {"rfSize":rfSize, "gap":gap, "rfOverlap":rfOverlap} # Etape de mise en dictionnaire avant conversion en dataframe

compil = pd.DataFrame(compil) # Les données doivent être au format dataframe

#pch = {'0.1':"o", '0.2':"^", '0.3':'s'}   # Définition des types de marqueurs par catégories

col_s = compil.rfOverlap.apply(lambda x: col[x])

cex_s = compil.rfOverlap.apply(lambda x: cex[x])

#pch_s = compil.Sexe.apply(lambda x: pch[x])

category_s = compil.rfOverlap.apply(lambda x: category[x])

for i in range(5) :

    print("Voici la catégorie : ",i)

    ax.scatter(compil.rfSize[category_s==i],compil.gap[category_s==i],

               c=col_s[category_s==i], s=cex_s[category_s==i],

               marker="o",label=list(cex.keys())[i])


ax.legend() ; #ax.grid(True)




#Parcouurs Vertital
gap = [0.84, 0.83, 0.93, 0.98, 1.5, 0.43, 0.62, 0.65, 0.66, 0.88, 0.31, 0.36, 0.41, 0.62, 0.64, 0.26, 0.26, 0.33, 0.45, 0.44, 0.18, 0.21, 0.26, 0.31, 0.47, 0.13, 0.16, 0.2, 0.25, 0.34, 0.13, 0.13, 0.18, 0.23, 0.34, 0.09, 0.11, 0.12, 0.21, 0.18, 0.08, 0.08, 0.12, 0.15, 0.19, 0.05, 0.08, 0.1, 0.14, 0.13, 0.03, 0.04, 0.09, 0.08, 0.1, 0.05, 0.05, 0.06, 0.07, 0.1, 0.02, 0.04, 0.05, 0.06, 0.08, 0.01, 0.03, 0.03, 0.04, 0.07, 0.01, 0.01, 0.03, 0.04, 0.05, 0.0, 0.02, 0.02, 0.04, 0.05, 0.0, 0.01, 0.02, 0.03, 0.04, 0.0, 0.01, 0.02, 0.04, 0.04, 0.0, 0.0, 0.0, 0.01, 0.01, 0.0, 0.0, 0.0, 0.0, 0.01, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.0, -0.0, 0.0, 0.0, 0.0]

compil = {"rfSize":rfSize, "gap":gap, "rfOverlap":rfOverlap} # Etape de mise en dictionnaire avant conversion en dataframe

compil = pd.DataFrame(compil) # Les données doivent être au format dataframe

#pch = {'0.1':"o", '0.2':"^", '0.3':'s'}   # Définition des types de marqueurs par catégories

col_s = compil.rfOverlap.apply(lambda x: col[x])

cex_s = compil.rfOverlap.apply(lambda x: cex[x])

#pch_s = compil.Sexe.apply(lambda x: pch[x])

category_s = compil.rfOverlap.apply(lambda x: category[x])


for i in range(5) :

    print("Voici la catégorie : ",i)

    ax.scatter(compil.rfSize[category_s==i],compil.gap[category_s==i],

               c=col_s[category_s==i], s=cex_s[category_s==i],

               marker="^",label=list(cex.keys())[i])


#ax.legend() ; 
ax.grid(True)
ax.set_xlabel("Taille de la fenêtre de variables fixées")
ax.set_ylabel("Moyenne des gaps obtenus (%)")
ax.set_title("Instance 100_10 : les gaps")
ax.set_xticks(np.arange(215, 1010, 35))  # Par exemple, créez des graduations de 1 à 5 avec un pas de 1 sur l'axe x
#ax[0].set_yticks(np.arange(0, 7, 1))  # Par exemple, créez des graduations de 5 à 20 avec un pas de 5 sur l'axe y


fig, ax1 = plt.subplots(figsize=(10, 7))
#----------------------TEMPS---------------------
#Parcouurs Horizontal
time = [1.7569, 1.2186, 0.9926, 0.8115, 0.6779, 1.7262, 1.2607, 0.9903, 0.8464, 0.7037, 1.7493, 1.3376, 1.0644, 0.932, 0.786, 1.7689, 1.2901, 1.0225, 0.865, 0.7527, 1.7647, 1.3425, 1.0521, 0.8822, 0.9382, 1.6299, 1.4899, 0.9587, 0.8738, 0.8473, 1.553, 1.2978, 1.156, 0.9192, 0.9572, 1.9027, 1.2993, 1.1868, 1.3141, 0.8346, 1.9583, 1.5818, 1.1858, 1.048, 0.9612, 2.3638, 1.33, 1.4378, 1.4389, 1.0895, 2.2641, 1.5827, 1.4074, 1.3669, 1.2898, 2.4782, 1.9228, 1.3884, 1.4492, 1.2982, 2.5548, 2.3203, 2.3331, 1.9673, 1.7955, 2.6143, 1.9125, 2.0564, 1.6343, 1.5023, 2.9464, 2.418, 2.2222, 1.8603, 1.5326, 2.9105, 2.7355, 2.1369, 2.1746, 1.85, 2.5101, 2.4055, 2.2525, 1.7522, 1.9108, 3.1826, 2.9732, 2.6854, 2.5013, 2.2105, 3.3704, 3.8016, 3.1513, 3.0716, 2.8044, 4.1887, 3.7342, 3.7095, 4.3034, 3.3699, 4.8954, 5.1287, 4.698, 4.2963, 4.2737, 7.161, 7.7885, 7.2414, 7.4464, 7.1111, 12.1415, 11.264, 11.3198, 10.9672, 10.557]

compil = {"rfSize":rfSize, "time":time, "rfOverlap":rfOverlap} # Etape de mise en dictionnaire avant conversion en dataframe

compil = pd.DataFrame(compil) # Les données doivent être au format dataframe

#pch = {'0.1':"o", '0.2':"^", '0.3':'s'}   # Définition des types de marqueurs par catégories

col_s = compil.rfOverlap.apply(lambda x: col[x])

cex_s = compil.rfOverlap.apply(lambda x: cex[x])

#pch_s = compil.Sexe.apply(lambda x: pch[x])

category_s = compil.rfOverlap.apply(lambda x: category[x])

for i in range(5) :

    print("Voici la catégorie : ",i)

    ax1.scatter(compil.rfSize[category_s==i],compil.time[category_s==i],

               c=col_s[category_s==i], s=cex_s[category_s==i],

               marker="o",label=list(cex.keys())[i])


ax1.legend(loc='upper left') ; #ax.grid(True)




#Parcouurs Vertital
time = [2.3327, 1.5917, 0.9872, 0.9001, 0.8708, 1.9252, 1.3531, 1.0136, 0.8391, 0.7058, 2.1898, 1.4788, 1.1341, 1.1996, 0.7574, 2.4901, 2.0372, 1.2082, 1.125, 1.2086, 2.8649, 1.7917, 1.8223, 1.2108, 1.1173, 3.0781, 2.7838, 1.9355, 1.2856, 1.6788, 6.2694, 2.7314, 2.9365, 1.6554, 1.3962, 5.0136, 5.3423, 2.4059, 2.5786, 1.3242, 6.1084, 3.0238, 3.8638, 1.9994, 1.1164, 5.8536, 6.7175, 2.7475, 2.4027, 2.3625, 6.9088, 4.5762, 2.8257, 2.3503, 1.7552, 10.4507, 8.622, 8.0757, 7.2237, 6.2936, 8.0336, 6.0564, 4.5, 3.9417, 3.1961, 7.2152, 5.6567, 5.2092, 4.627, 3.3991, 14.7834, 7.1747, 6.9285, 5.9029, 5.0935, 8.1381, 4.8048, 3.4242, 2.7902, 2.5162, 13.7392, 11.5367, 9.1192, 8.3205, 7.8404, 8.8704, 5.1528, 5.0848, 4.4674, 4.0323, 14.0986, 11.2936, 10.6322, 10.0823, 9.838, 14.8363, 13.2074, 12.1631, 11.6522, 11.4761, 7.8765, 7.7324, 7.6354, 7.7187, 7.5517, 9.3617, 9.022, 9.1787, 8.8872, 8.7756, 9.6233, 9.4096, 9.3887, 9.2885, 9.2846]

compil = {"rfSize":rfSize, "time":time, "rfOverlap":rfOverlap} # Etape de mise en dictionnaire avant conversion en dataframe

compil = pd.DataFrame(compil) # Les données doivent être au format dataframe

#pch = {'0.1':"o", '0.2':"^", '0.3':'s'}   # Définition des types de marqueurs par catégories

col_s = compil.rfOverlap.apply(lambda x: col[x])

cex_s = compil.rfOverlap.apply(lambda x: cex[x])

#pch_s = compil.Sexe.apply(lambda x: pch[x])

category_s = compil.rfOverlap.apply(lambda x: category[x])


for i in range(5) :

    print("Voici la catégorie : ",i)

    ax1.scatter(compil.rfSize[category_s==i],compil.time[category_s==i],

               c=col_s[category_s==i], s=cex_s[category_s==i],

               marker="^",label=list(cex.keys())[i])


#ax.legend() ; 
#ax[1].grid(True)
ax1.set_xlabel("Taille de la fenêtre de variables fixées")
ax1.set_ylabel("Moyenne des temps obtenus (s)")
ax1.set_title("Instance 100_10 : les temps")
ax1.set_xticks(np.arange(215, 1010, 35))  #Par exemple, créez des graduations de 1 à 5 avec un pas de 1 sur l'axe x
#ax.set_yticks(np.arange(0, 7, 1))  # Par exemple, créez des graduations de 5 à 20 avec un pas de 5 sur l'axe y
plt.show()