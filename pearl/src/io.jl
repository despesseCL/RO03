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
  - pearls   : matrice n×n de Char  (' '=vide, '2'=noire, '1'=blanche)
"""
function readInputFile(path::String)
    open(path, "r") do f
        lines = readlines(f)
        lines = filter(l -> strip(l) != "", lines)
        n = parse(Int, strip(lines[1]))
        pearls = fill(' ', n, n)
        for i in 1:n
            tokens = split(lines[i+1], ",")
            for j in 1:n
                t = strip(tokens[j])
                if t == "2"
                    pearls[i, j] = '2'
                elseif t == "1"
                    pearls[i, j] = '1'
                else
                    pearls[i, j] = ' '
                end
            end
        end
        return n, pearls
    end
end

"""
Affiche la grille initiale
"""
function displayGrid(n::Int, pearls::Matrix{Char})
    println("+" * ("---+" ^ n))
    for i in 1:n
        row = "|"
        for j in 1:n
            c = pearls[i, j]
            if c == '2'
                row *= " ● |"
            elseif c == '1'
                row *= " ○ |"
            else
                row *= "   |"
            end
        end
        println(row)
        println("+" * ("---+" ^ n))
    end
end
