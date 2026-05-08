# This file contains methods to generate random Towers instances
using Random
include("io.jl")

"""
Generate a random complete n×n Towers solution grid (a Latin square with values 1..n).

Argument:
- n: size of the grid
"""
function generateCompleteSolution(n::Int)

    # We build a random valid Latin square using a shuffled base row and
    # circular shifts (guaranteed to be a Latin square).
    base = shuffle(collect(1:n))
    sol = Matrix{Int}(undef, n, n)
    for i in 1:n
        for j in 1:n
            sol[i, j] = base[mod(j + i - 2, n) + 1]
        end
    end

    # Apply random row and column permutations to get more variety
    rowPerm = shuffle(1:n)
    colPerm = shuffle(1:n)
    sol = sol[rowPerm, colPerm]

    return sol
end


"""
Compute the number of towers visible from the left of row `row` in grid `sol`.
"""
function visibleFromLeft(sol::Matrix{Int}, row::Int)
    n = size(sol, 1)
    count = 0
    maxH = 0
    for j in 1:n
        if sol[row, j] > maxH
            count += 1
            maxH = sol[row, j]
        end
    end
    return count
end

"""
Compute the number of towers visible from the right of row `row` in grid `sol`.
"""
function visibleFromRight(sol::Matrix{Int}, row::Int)
    n = size(sol, 1)
    count = 0
    maxH = 0
    for j in n:-1:1
        if sol[row, j] > maxH
            count += 1
            maxH = sol[row, j]
        end
    end
    return count
end

"""
Compute the number of towers visible from the top of column `col` in grid `sol`.
"""
function visibleFromTop(sol::Matrix{Int}, col::Int)
    n = size(sol, 1)
    count = 0
    maxH = 0
    for i in 1:n
        if sol[i, col] > maxH
            count += 1
            maxH = sol[i, col]
        end
    end
    return count
end

"""
Compute the number of towers visible from the bottom of column `col` in grid `sol`.
"""
function visibleFromBottom(sol::Matrix{Int}, col::Int)
    n = size(sol, 1)
    count = 0
    maxH = 0
    for i in n:-1:1
        if sol[i, col] > maxH
            count += 1
            maxH = sol[i, col]
        end
    end
    return count
end


"""
Generate a random Towers instance of size n×n.

The instance is built by:
1. Generating a random complete solution.
2. Computing all border clues from that solution.
3. Randomly hiding a fraction (1 - clueDensity) of the border clues.
4. Randomly revealing a fraction cellDensity of the interior cells.

Arguments:
- n:            grid size (default 6)
- clueDensity:  fraction of border clues to keep in [0, 1] (default 0.5)
- cellDensity:  fraction of interior cells pre-filled in [0, 1] (default 0.0)

Returns:
- n, d, g  (same format as readInputFile)
"""
function generateInstance(n::Int=6, clueDensity::Float64=0.8, cellDensity::Float64=0.1)

    # 1. Build a complete random solution
    sol = generateCompleteSolution(n)

    # 2. Compute full clue matrix
    d_full = zeros(Int, 4, n)
    for j in 1:n
        d_full[1, j] = visibleFromTop(sol, j)
        d_full[4, j] = visibleFromBottom(sol, j)
    end
    for i in 1:n
        d_full[2, i] = visibleFromLeft(sol, i)
        d_full[3, i] = visibleFromRight(sol, i)
    end

    # 3. Randomly hide some clues (keep only clueDensity fraction)
    d = zeros(Int, 4, n)
    for j in 1:n
        if rand() < clueDensity;  d[1, j] = d_full[1, j];  end
        if rand() < clueDensity;  d[4, j] = d_full[4, j];  end
    end
    for i in 1:n
        if rand() < clueDensity;  d[2, i] = d_full[2, i];  end
        if rand() < clueDensity;  d[3, i] = d_full[3, i];  end
    end

    # 4. Randomly reveal some interior cells
    g = zeros(Int, n, n)
    for i in 1:n, j in 1:n
        if rand() < cellDensity
            g[i, j] = sol[i, j]
        end
    end

    return n, d, g
end


"""
Generate a dataset of Towers instances and save them in "../data/".

Instances are generated for several grid sizes, clue densities and replications.
A file is only created if it does not already exist.
"""
function generateDataSet()

    dataFolder = "../data/"
    if !isdir(dataFolder)
        mkpath(dataFolder)
    end

    # Grid sizes to consider
    for n in [4, 5, 6, 8, 10]

        # Clue densities (fraction of border clues kept)
        for clueDensity in [0.5, 0.75, 0.9, 1.0]

            # 5 instances per configuration
            for instance in 1:5

                fileName = dataFolder *
                    "towers_n$(n)_cd$(round(Int, clueDensity*100))_$(instance).txt"

                if !isfile(fileName)
                    println("-- Generating ", fileName)
                    n_inst, d_inst, g_inst = generateInstance(n, clueDensity, 0.1)
                    saveInstance(n_inst, d_inst, g_inst, fileName)
                end
            end
        end
    end
end
