import numpy as np
import matplotlib.pyplot as plt
import pandas as pd 

poids = [60,50,40,35,55,48,65,67,58,55,72]

taille = [173,135,140,150,150,160,165,170,180,177,178]

sexe = ["0.1"]*5+["0.2"]+["0.3"]*5

compil = {"Poids":poids, "Taille":taille, "Sexe":sexe} # Etape de mise en dictionnaire avant conversion en dataframe

import pandas as pd 

compil = pd.DataFrame(compil) # Les données doivent être au format dataframe

category = {'0.1':0, '0.2':1, '0.3':2} # Numéroter les catégories

col = {'0.1':'red', '0.2':'green', '0.3':'yellow'} # Définition des colorations par catégories

cex = {'0.1':20, '0.2':20, '0.3':20}  # Définition des tailles de points par catégories

pch = {'0.1':"o", '0.2':"^", '0.3':'s'}   # Définition des types de marqueurs par catégories

col_s = compil.Sexe.apply(lambda x: col[x])

cex_s = compil.Sexe.apply(lambda x: cex[x])

pch_s = compil.Sexe.apply(lambda x: pch[x])

category_s = compil.Sexe.apply(lambda x: category[x])

fig, ax = plt.subplots(figsize=(10, 5))

for i in range(3) :

    print("Voici la catégorie : ",i)

    ax.scatter(compil.Poids[category_s==i],compil.Taille[category_s==i],

               c=col_s[category_s==i], s=cex_s[category_s==i],

               marker="o",label=list(cex.keys())[i])


ax.legend() ; ax.grid(True)

plt.show()