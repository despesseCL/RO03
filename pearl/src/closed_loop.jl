"""
Génération d'une boucle fermée dans une grille N×N par DFS
avec couverture minimale forcée.

Utilisation :
    julia closed_loop_dfs.jl
"""

const DIRS = ((-1, 0), (1, 0), (0, -1), (0, 1))  # haut bas gauche droite

# ─── Algorithme principal ─────────────────────────────────────────────────────

"""
    dfs!(path, visited, r, c, min_cells, n) -> Bool

Explore récursivement la grille depuis (r, c).
- Tente de fermer la boucle vers (1,1) uniquement si `length(path) >= min_cells`.
- Retourne `true` si une boucle valide a été trouvée.
"""
function dfs!(path::Vector{Tuple{Int,Int}},
              visited::BitMatrix,
              r::Int, c::Int,
              min_cells::Int, n::Int)::Bool

    # Tentative de fermeture si le seuil est atteint
    if length(path) >= min_cells
        for (dr, dc) in DIRS
            if r + dr == 1 && c + dc == 1
                return true   # boucle fermée vers l'origine (1,1)
            end
        end
    end

    # Exploration des voisins dans un ordre aléatoire
    for (dr, dc) in shuffle(DIRS)
        nr, nc = r + dr, c + dc
        if checkbounds(Bool, visited, nr, nc) && !visited[nr, nc]
            visited[nr, nc] = true
            push!(path, (nr, nc))

            dfs!(path, visited, nr, nc, min_cells, n) && return true

            # Backtrack
            pop!(path)
            visited[nr, nc] = false
        end
    end

    return false
end

"""
    generate_loop(n; coverage=0.6) -> Vector{Tuple{Int,Int}}

Génère une boucle fermée sur une grille n×n.
- `coverage` : fraction minimale de cellules à visiter (entre 0 et 1).
- Retourne le chemin (liste de positions), sans inclure la fermeture finale.
- Lance une erreur si aucune boucle n'est trouvée.
"""
function generate_loop(n::Int; coverage::Float64=0.6)::Vector{Tuple{Int,Int}}
    min_cells = max(4, floor(Int, n * n * coverage))

    visited = falses(n, n)
    visited[1, 1] = true
    path = [(1, 1)]

    success = dfs!(path, visited, 1, 1, min_cells, n)
    success || error("Aucune boucle trouvée (couverture $(round(Int, coverage*100))% trop élevée ?)")

    return path
end

# ─── Utilitaires ─────────────────────────────────────────────────────────────

"""Mélange un tuple de directions et retourne un vecteur."""
shuffle(dirs) = dirs[randperm(length(dirs))]

"""Affiche la grille avec le chemin numéroté dans le terminal."""
function print_grid(path::Vector{Tuple{Int,Int}}, n::Int)
    order = Dict(pos => i for (i, pos) in enumerate(path))
    # Largeur d'une cellule = nb de chiffres dans n²
    w = length(string(n * n))

    for r in 1:n
        row = String[]
        for c in 1:n
            if haskey(order, (r, c))
                push!(row, lpad(order[(r, c)], w))
            else
                push!(row, " " ^ w)
            end
        end
        println(join(row, " │ "))
        r < n && println("─" ^ (n * (w + 3) - 1))
    end
    println()
end

"""Affiche un résumé statistique."""
function print_summary(path, n; t_ms)
    total = n * n
    pct   = round(Int, length(path) / total * 100)
    first = path[1]
    last  = path[end]
    println("Grille        : $(n)×$(n) = $(total) cellules")
    println("Chemin        : $(length(path)) cellules ($(pct)%)")
    println("Départ        : $(first)")
    println("Dernière cell : $(last)  →  fermeture vers $(first)")
    println("Temps         : $(round(t_ms, digits=2)) ms")
end

# ─── Point d'entrée ──────────────────────────────────────────────────────────

function main()
    n        = 10
    coverage = 0.65

    println("=== DFS boucle fermée — grille $(n)×$(n), couverture min $(round(Int, coverage*100))% ===\n")

    t0   = time()
    path = generate_loop(n; coverage)
    t_ms = (time() - t0) * 1000

    print_grid(path, n)
    print_summary(path, n; t_ms)
end

main()