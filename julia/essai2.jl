# Définir une fonction personnalisée de comparaison avec un argument supplémentaire
function comparer_somme_tuple(x::Tuple, y::Tuple, facteur::Float64)
    somme_x = sum(x) * facteur
    somme_y = sum(y) * facteur
    return somme_x < somme_y
end

# Votre liste de tuples
ma_liste_de_tuples = [(2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (5, 1), (5, 2), (5, 3), (5, 4), (5, 5), (6, 1), (6, 2), (6, 3), (6, 4), (6, 5)]

# Trier la liste de tuples en utilisant la fonction de comparaison personnalisée avec un facteur
facteur_tri = 2.0  # Exemple d'un facteur de tri personnalisé
liste_triee = sort(ma_liste_de_tuples, lt=(x, y) -> comparer_somme_tuple(x, y, facteur_tri))

# Afficher la liste triée
println(liste_triee)
