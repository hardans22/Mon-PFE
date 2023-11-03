import numpy as np
import matplotlib.pyplot as plt
import pandas as pd 

rfSize = [10, 10, 10, 10, 10, 15, 15, 15, 15, 15, 20, 20, 20, 20, 20, 25, 25, 25, 25, 25, 30, 30, 30, 30, 30, 35, 35, 35, 35, 35, 40, 40, 40, 40, 40, 45, 45, 45, 45, 45, 50, 50, 50, 50, 50, 55, 55, 55, 55, 55]

category = {'0.2':0, '0.3':1, '0.4':2, '0.5':3, '0.6':4} # Numéroter les catégories

col = {'0.2':'green', '0.3':'yellow', '0.4':'blue', '0.5':'pink', '0.6':'red'} # Définition des colorations par catégories

cex = {'0.2':30, '0.3':30, '0.4':30, '0.5':30, '0.6':30}  #Définition des tailles de points par catégories

rfOverlap = ["0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6", "0.2", "0.3", "0.4", "0.5", "0.6"]

fig, ax = plt.subplots(figsize=(10, 7))

#Parcouurs Horizontal
time = [0.1128, 0.0756, 0.0604, 0.0519, 0.0482, 0.0954, 0.079, 0.0526, 0.0482, 0.0404, 0.0994, 0.0752, 0.0577, 0.048, 0.0472, 0.1126, 0.0788, 0.0674, 0.0582, 0.0509, 0.1104, 0.0789, 0.0785, 0.0635, 0.0543, 0.1235, 0.0952, 0.0828, 0.077, 0.0735, 0.1148, 0.1176, 0.0837, 0.0763, 0.0726, 0.1208, 0.1205, 0.0933, 0.0814, 0.0714, 0.1308, 0.1123, 0.0964, 0.087, 0.0751, 0.1535, 0.1328, 0.1223, 0.118, 0.1027]

compil = {"rfSize":rfSize, "time":time, "rfOverlap":rfOverlap} # Etape de mise en dictionnaire avant conversion en dataframe

compil = pd.DataFrame(compil) # Les données doivent être au format dataframe

#pch = {'0.1':"o", '0.2':"^", '0.3':'s'}   # Définition des types de marqueurs par catégories

col_s = compil.rfOverlap.apply(lambda x: col[x])

cex_s = compil.rfOverlap.apply(lambda x: cex[x])

#pch_s = compil.Sexe.apply(lambda x: pch[x])

category_s = compil.rfOverlap.apply(lambda x: category[x])

for i in range(5) :

    print("Voici la catégorie : ",i)

    ax.scatter(compil.rfSize[category_s==i],compil.time[category_s==i],

               c=col_s[category_s==i], s=cex_s[category_s==i],

               marker="o",label=list(cex.keys())[i])


ax.legend() ; #ax.grid(True)




#Parcouurs Vertital
time = [0.1216, 0.0965, 0.081, 0.0596, 0.0513, 0.1343, 0.1058, 0.0761, 0.0768, 0.0556, 0.1459, 0.1035, 0.083, 0.0731, 0.0801, 0.1696, 0.1307, 0.0968, 0.0895, 0.0739, 0.1895, 0.144, 0.1138, 0.0956, 0.0805, 0.1893, 0.1556, 0.1185, 0.1029, 0.0897, 0.2053, 0.1467, 0.1266, 0.1046, 0.0947, 0.1996, 0.163, 0.1504, 0.1455, 0.1324, 0.1793, 0.1546, 0.1497, 0.1443, 0.1269, 0.1324, 0.1374, 0.1334, 0.1253, 0.1226]

compil = {"rfSize":rfSize, "time":time, "rfOverlap":rfOverlap} # Etape de mise en dictionnaire avant conversion en dataframe

compil = pd.DataFrame(compil) # Les données doivent être au format dataframe

#pch = {'0.1':"o", '0.2':"^", '0.3':'s'}   # Définition des types de marqueurs par catégories

col_s = compil.rfOverlap.apply(lambda x: col[x])

cex_s = compil.rfOverlap.apply(lambda x: cex[x])

#pch_s = compil.Sexe.apply(lambda x: pch[x])

category_s = compil.rfOverlap.apply(lambda x: category[x])


for i in range(5) :

    print("Voici la catégorie : ",i)

    ax.scatter(compil.rfSize[category_s==i],compil.time[category_s==i],

               c=col_s[category_s==i], s=cex_s[category_s==i],

               marker="^",label=list(cex.keys())[i])


#ax.legend() ; 
ax.grid(True)
ax.set_xlabel("Taille de la fenêtre de variables fixées")
ax.set_ylabel("Moyenne des times obtenus (%)")
ax.set_title("Nuage de points pour le groupe d'instances 5-10")
ax.set_xticks(np.arange(5, 61, 5))  # Par exemple, créez des graduations de 1 à 5 avec un pas de 1 sur l'axe x
#ax.set_yticks(np.arange(0, 7, 1))  # Par exemple, créez des graduations de 5 à 20 avec un pas de 5 sur l'axe y
ax.text(2.5, 18, "cercle => H, triangle => V",  fontsize=12, ha='center', va='center', color='black')
plt.show()