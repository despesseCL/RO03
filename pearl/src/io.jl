###############################################################################
# RO03 - Projet Pearl (Masyu)
# Fichier : io.jl
# Lecture des instances, affichage console, génération de tableaux de résultats
###############################################################################
using Printf
"""
Lecture d'une instance Pearl depuis un fichier texte.

Format du fichier :
  - Ligne 1 : n (taille grille)
  - Lignes suivantes : n lignes de n valeurs séparées par des virgules
      0 = case vide
      2 = perle noire (black)
      1 = perle blanche (white)

Exemple pour une grille 5×5 :
5
0,2,0,0,1
0,0,1,0,0 
2,0,0,0,2
0,0,1,0,0
0,1,0,2,0

Retourne :
  - n        : taille de la grille
  - pearls   : matrice n×n de Char  ('0'=vide, '2'=noire, '1'=blanche)
"""
function readInputFile(path::String)
    open(path, "r") do f
        lines = readlines(f)
        lines = filter(l -> strip(l) != "", lines)
        n = parse(Int, strip(lines[1]))
        pearls = fill(0, n, n)
        for i in 1:n
            tokens = split(lines[i+1], ",")
            for j in 1:n
                t = strip(tokens[j])
                if t == "2"
                    pearls[i, j] = 2
                elseif t == "1"
                    pearls[i, j] = 1
                else
                    pearls[i, j] = 0
                end
            end
        end
        return n, pearls
    end
end

"""
Affiche la grille initiale
"""
function displayGrid(n::Int, pearls::Matrix{Int})
    println("+" * ("---+" ^ n))
    for i in 1:n
        row = "|"
        for j in 1:n
            c = pearls[i, j]
            if c == 2
                row *= " ● |"
            elseif c == 1
                row *= " ○ |"
            else
                row *= "   |"
            end
        end
        println(row)
        println("+" * ("---+" ^ n))
    end
end

"""
Affiche la solution dans la console.

h[i,j] = 1 si l'arête horizontale entre (i,j) et (i,j+1) est utilisée
v[i,j] = 1 si l'arête verticale entre (i,j) et (i+1,j) est utilisée
"""
function displaySolution(n::Int, pearls::Matrix{Int},
                          h::Matrix{Float64}, v::Matrix{Float64})
    for i in 1:n
        top = "+"
        for j in 1:n
            # Arête verticale au-dessus de (i,j) = v[i-1,j]
            if i > 1 && v[i-1, j] > 0.5
                top *= "   +"
            else
                top *= "---+"
            end
        end
        println(top)

        # Ligne des cellules
        row = ""
        for j in 1:n
            # Arête horizontale à gauche de (i,j) = h[i,j-1]
            if j == 1
                row *= "|"
            elseif h[i, j-1] > 0.5
                row *= " "
            else
                row *= "|"
            end
            # Contenu de la case
            c = pearls[i, j]
            if c == 2
                row *= " ● "
            elseif c == 1
                row *= " ○ "
            else
                row *= "   "
            end
        end
        # Bord droit
        row *= "|"
        println(row)
    end
    # Dernière ligne du bas
    bottom = "+"
    for j in 1:n
        bottom *= "---+"
    end
    println(bottom)
end

# Données de test cohérentes
n = 4
pearls = [0 1 0  0; 0 0 0 0 ; 0 1 0 1 ; 0 0 2 1] # Matrice d'Int
# 2. Création des segments (1.0 pour un trait, 0.0 pour du vide)
# h[i, j] connecte la cellule (i, j) à (i, j+1)
h = [
    1.0  1.0  0.0 ;  # Ligne 1 : traits entre col 1-2 et col 2-3
    1.0  0.0  1.0 ;  ## Ligne 2 : traits entre col 1-2 et col 2-3
    0.0  0.0  0.0 ;  # Ligne 3 : aucun trait horizontal
    0.0  1.0  1.0  # Ligne 4 : traits entre col 1-2 et col 2-3
]

# v[i, j] connecte la cellule (i, j) à (i+1, j)
v = [
    1.0  0.0  1.0 0.0 ;
    0.0  1.0  0.0 1.0 ; 
    0.0  1.0  0.0 1.0  
]

# 3. Appel de ta fonction
displaySolution(n, pearls, h, v)