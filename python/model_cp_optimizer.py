from docplex.cp.model import CpoModel

# Crée un modèle
model = CpoModel()

# Définit les variables
x = model.integer_var_list(5, 0, 100, name='x')

# Définit la contrainte
model.add(model.sum(x) == 10)

# Définit la fonction objectif
model.maximize(model.sum(x))

# Résout le modèle
solution = model.solve()

# Affiche la solution
if solution:
    print('Solution trouvée :')
    for v in x:
        print('{} = {}'.format(v.get_name(), solution[v]))
else:
    print('Aucune solution trouvée')
