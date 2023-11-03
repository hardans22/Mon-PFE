import numpy as np
import matplotlib.pyplot as plt
import pandas as pd 

rfSize = [2, 2, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 5]

category = {'step = 1':0, 'step = 2':1, 'step = 3':2, 'step = 4':3, 'step = 5':4} # Numéroter les catégories

col = {'step = 1':'green', 'step = 2':'yellow', 'step = 3':'blue', 'step = 4':'pink', 'step = 5':'red'} # Définition des colorations par catégories

cex = {'step = 1':30, 'step = 2':30, 'step = 3':30, 'step = 4':30, 'step = 5':30}  #Définition des tailles de points par catégories

rfStep = ["step = 1", "step = 2", "step = 1", "step = 2", "step = 3", "step = 1", "step = 2", "step = 3", "step = 4", "step = 1", "step = 2", "step = 3", "step = 4", "step = 5"]

fig, ax = plt.subplots(1, 2, figsize=(10, 7))



#----------------------GAPS---------------------

gap = [1.04, 4.52, 0.34, 0.61, 2.82, 0.11, 0.23, 0.36, 1.04, 0.13, 0.1, 0.17, 0.26, 0.98]

compil = {"rfSize":rfSize, "gap":gap, "rfStep":rfStep} # Etape de mise en dictionnaire avant conversion en dataframe

compil = pd.DataFrame(compil) # Les données doivent être au format dataframe

#pch = {'0.1':"o", '0.2':"^", '0.3':'s'}   # Définition des types de marqueurs par catégories

col_s = compil.rfStep.apply(lambda x: col[x])

cex_s = compil.rfStep.apply(lambda x: cex[x])

#pch_s = compil.Sexe.apply(lambda x: pch[x])

category_s = compil.rfStep.apply(lambda x: category[x])

for i in range(5) :

    print("Voici la catégorie : ",i)

    ax[0].scatter(compil.rfSize[category_s==i],compil.gap[category_s==i],

               c=col_s[category_s==i], s=cex_s[category_s==i],

               marker="o",label=list(cex.keys())[i])


ax[0].legend() ; #ax.grid(True) 
#ax[0].grid(True)
ax[0].set_xlabel("Taille de la fenêtre de variables libres")
ax[0].set_ylabel("Moyenne des gaps obtenus (%)")
ax[0].set_title("Instance 100_10 : les gaps")
#ax[0].set_xticks(np.arange(215, 1010, 35))  # Par exemple, créez des graduations de 1 à 5 avec un pas de 1 sur l'axe x
#ax[0].set_yticks(np.arange(0, 7, 1))  # Par exemple, créez des graduations de 5 à 20 avec un pas de 5 sur l'axe y


#fig, ax1 = plt.subplots(figsize=(10, 7))
#----------------------TEMPS---------------------

time = [0.7854, 0.7013, 1.2976, 0.6855, 0.4652, 3.734, 2.5773, 0.8324, 0.4297, 14.9449, 3.5634, 1.4519, 0.805, 0.4784]

compil = {"rfSize":rfSize, "time":time, "rfStep":rfStep} # Etape de mise en dictionnaire avant conversion en dataframe

compil = pd.DataFrame(compil) # Les données doivent être au format dataframe

#pch = {'0.1':"o", '0.2':"^", '0.3':'s'}   # Définition des types de marqueurs par catégories

col_s = compil.rfStep.apply(lambda x: col[x])

cex_s = compil.rfStep.apply(lambda x: cex[x])

#pch_s = compil.Sexe.apply(lambda x: pch[x])

category_s = compil.rfStep.apply(lambda x: category[x])

for i in range(5) :

    print("Voici la catégorie : ",i)

    ax[1].scatter(compil.rfSize[category_s==i],compil.time[category_s==i],

               c=col_s[category_s==i], s=cex_s[category_s==i],

               marker="o",label=list(cex.keys())[i])


ax[1].legend(loc='upper left') ; #ax.grid(True)

ax[1].set_xlabel("Taille de la fenêtre de variables libres")
ax[1].set_ylabel("Moyenne des temps obtenus (s)")
ax[1].set_title("Instance 100_10 : les temps")
#ax[1].set_xticks(np.arange(215, 1010, 35))  #Par exemple, créez des graduations de 1 à 5 avec un pas de 1 sur l'axe x
#ax.set_yticks(np.arange(0, 7, 1))  # Par exemple, créez des graduations de 5 à 20 avec un pas de 5 sur l'axe y
plt.show()