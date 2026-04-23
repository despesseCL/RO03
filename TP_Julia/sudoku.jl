using JuMP
using CPLEX
# using GLPK

function sudoku(t::Matrix{Int})

    # Taille de la grille
    n = size(t, 1)

    # Créer le modèle
    m = Model(CPLEX.Optimizer)
    # m = Model(GLPK.Optimizer)

    ### Variables
    # x[i, j, k] = 1 if cell (i, j) has value k
    @variable(m, x[1:n, 1:n, 1:n], Bin)

    ### Objectif : maximiser la valeur de la case en haut à gauche
    # L'objectif est quelconque car on souhaite simplement trouver une solution faisable
    @objective(m, Max, sum(k * x[1, 1, k] for k in 1:n))

    ### Contraintes
    # Obtenir la taille d'un bloque (3 dans une grille standard)
    blockSize = round.(Int, sqrt(n))

    # TODO: Ajouter les contraintes du modèle
    # Remarque : un 0 dans la matrice t, indique que la valeur de la case correspondante de la grille de sudoku n'est pas fixée

    ### Résoudre le problème
    optimize!(m)

    ### Si une solution est trouvé, l'afficher ainsi que la valeur de l'objectif associé
    if primal_status(model) == MOI.FEASIBLE_POINT
        objectiveValue = round(Int, JuMP.objective_value(m))
        println("Valeur de l'objectif : ", round(Int, JuMP.objective_value(m)))
        
        # TODO: Récupérer la solution
    else                             
        println("Aucun solution trouvée.")
    end   

end

t = [
0 7 0 2 0 3 0 1 0;
3 0 0 0 0 0 0 0 0;
0 0 0 0 0 0 2 0 0;
0 0 0 0 0 0 0 0 0;
0 0 0 0 0 0 0 0 0;
0 0 0 0 0 0 0 0 2;
2 0 0 0 0 0 0 0 0;
0 0 0 0 0 0 0 0 0;
0 0 0 0 0 0 0 0 0]

sudoku(t)

