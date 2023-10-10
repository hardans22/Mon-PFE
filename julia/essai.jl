# Créez une matrice de test (par exemple, une matrice 3x3)
matrice = [1 2 3 1 2 3; 4 5 6 4 5 6; 7 8 9 7 8 9; 1 2 3 1 2 3; 4 5 6 4 5 6; 7 8 9 7 8 9]

# Obtenez les dimensions de la matrice
n, m = size(matrice)

# Utilisez des boucles for pour parcourir la matrice
for i in 1:n
    for j in 1:m
        # Accédez à l'élément de la matrice à la position (i, j)
        élément = matrice[i, j]
        
        # Faites quelque chose avec l'élément (par exemple, l'afficher)
        println("Élément à la position ($i, $j) : $élément")
    end
end
# Taille du carré

carré_taille = 5

for i in 1:n-carré_taille+1
    for j in 1:m-carré_taille+1
        # Accédez aux éléments du carré
        carré = matrice[i:i+carré_taille-1, j:j+carré_taille-1]
        
        # Faites quelque chose avec le carré
        println("Carré à la position ($i, $j) : $carré")
    end
end