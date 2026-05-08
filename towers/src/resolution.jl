# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(n::Int,d::Matrix{Int}, g::Matrix{Int})

    # Create the model
    m = Model(CPLEX.Optimizer)
    # TODO
    println("In file resolution.jl, in method cplexSolve(), TODO: fix input and output, define the model")
    # x[i,j,k] = 1  iff cell (i,j) has height k
    @variable(m, x[1:n, 1:n, 1:n], Bin)

        # h(i,j) = sum_k k * x[i,j,k] height of cell (i,j)
    @expression(m, h[i in 1:n, j in 1:n], sum(k * x[i, j, k] for k in 1:n))

    @variable(m, 0 <= Mtop[1:n, 1:n]   <= n)
    @variable(m, 0 <= Mbot[1:n, 1:n]   <= n)
    @variable(m, 0 <= Mleft[1:n, 1:n]  <= n)
    @variable(m, 0 <= Mright[1:n, 1:n] <= n)

    # Binary visibility variables
    @variable(m, vtop[1:n, 1:n],   Bin)
    @variable(m, vbot[1:n, 1:n],   Bin)
    @variable(m, vleft[1:n, 1:n],  Bin)
    @variable(m, vright[1:n, 1:n], Bin)
    
    @objective(m, Min, 0)


    # Each cell (i, j) has one value k
    @constraint(m, [i in 1:n, j in 1:n], sum(x[i, j, k] for k in 1:n) == 1)

    # Each line i has one cell with value k
    @constraint(m, [k in 1:n, i in 1:n], sum(x[i, j, k] for j in 1:n) == 1)

    # Each column c has one cell with value k
    @constraint(m, [k in 1:n, j in 1:n], sum(x[i, j, k] for i in 1:n) == 1)
    
    # Set the fixed value in the grid
    for i in 1:n
        for j in 1:n
            if g[i,j] != 0
                @constraint(m, x[i,j,g[i,j]] == 1)
            end
        end
    end
   # Set the obvious cells (if 1 on n on the sides)
    for j in 1:n
        if d[1,j] == 1
            @constraint(m, x[1,j,n] == 1)
        end
        if d[2,j] == 1
            @constraint(m, x[j,1,n] == 1)
        end
        if d[3,j] == 1
            @constraint(m, x[j,n,n] == 1)
        end
        if d[4,j] == 1
            @constraint(m, x[n,j,n] == 1)  
        end
    # If n on the side then linear increasing on rows or columns   
        if d[1,j] == n
            @constraint(m, [i in 1:n], x[i,j,i] == 1)
        end
        if d[2,j] == n
            @constraint(m, [i in 1:n], x[j,i,i] == 1)
        end
        if d[3,j] == n
            @constraint(m, [i in 1:n] ,x[j,n-i+1,i] == 1)
        end
        if d[4,j] == n
            @constraint(m, [i in 1:n], x[n-i+1,j,i] == 1)
        end
    end


   # TOP (reading column j from row 1 downward)
    for j in 1:n
        # Row 1: nothing above, so Mtop = 0 and tower is always visible
        @constraint(m, Mtop[1, j] == 0)
        @constraint(m, vtop[1, j] == 1)

        for i in 2:n
            # Mtop[i,j] ≥ Mtop[i-1,j]
            @constraint(m, Mtop[i, j] >= Mtop[i-1, j])
            # Mtop[i,j] ≥ h[i-1,j]
            @constraint(m, Mtop[i, j] >= h[i-1, j])
            # Mtop[i,j] ≤ max of all heights above and upper-bound by n
            @constraint(m, Mtop[i, j] <= Mtop[i-1, j] + h[i-1, j])  # borne haute

            # Visibility: vtop[i,j]=1 iff h[i,j] > Mtop[i,j]
            @constraint(m, h[i, j] >= Mtop[i, j] - n * (1 - vtop[i, j]) + 1)
            @constraint(m, h[i, j] <= Mtop[i, j] + n * vtop[i, j])
        end

        # Clue constraint (skip if clue == 0)
        if d[1, j] != 0
            @constraint(m, sum(vtop[i, j] for i in 1:n) == d[1, j])
        end
    end

    # BOTTOM (reading column j from row n upward)
    for j in 1:n
        @constraint(m, Mbot[n, j] == 0)
        @constraint(m, vbot[n, j] == 1)

        for i in (n-1):-1:1
            @constraint(m, Mbot[i, j] >= Mbot[i+1, j])
            @constraint(m, Mbot[i, j] >= h[i+1, j])

            @constraint(m, h[i, j] >= Mbot[i, j] - n * (1 - vbot[i, j]) + 1)
            @constraint(m, h[i, j]<= Mbot[i, j] + n * vbot[i, j])
        end

        if d[4, j] != 0
            @constraint(m, sum(vbot[i, j] for i in 1:n) == d[4, j])
        end
    end

    # LEFT (reading row i from column 1 rightward)
    for i in 1:n
        @constraint(m, Mleft[i, 1] == 0)
        @constraint(m, vleft[i, 1] == 1)

        for j in 2:n
            @constraint(m, Mleft[i, j] >= Mleft[i, j-1])
            @constraint(m, Mleft[i, j] >= h[i, j-1])

            @constraint(m, h[i, j] >= Mleft[i, j] - n * (1 - vleft[i, j]) + 1)
            @constraint(m, h[i, j]<= Mleft[i, j] + n * vleft[i, j])
        end

        if d[2, i] != 0
            @constraint(m, sum(vleft[i, j] for j in 1:n) == d[2, i])
        end
    end

    # RIGHT (reading row i from column n leftward)
    for i in 1:n
        @constraint(m, Mright[i, n] == 0)
        @constraint(m, vright[i, n] == 1)

        for j in (n-1):-1:1
            @constraint(m, Mright[i, j] >= Mright[i, j+1])
            @constraint(m, Mright[i, j] >= h[i, j+1])

            @constraint(m, h[i, j] >= Mright[i, j] - n * (1 - vright[i, j]) + 1)
            @constraint(m, h[i, j]<= Mright[i, j] + n * vright[i, j])
        end

        if d[3, i] != 0
            @constraint(m, sum(vright[i, j] for j in 1:n) == d[3, i])
        end
    end
    # TODO
    println("In file resolution.jl, in method cplexSolve(), TODO: fix input and output, define the model")

    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)
    status = termination_status(m)
    is_feasible = (status == MOI.OPTIMAL || status == MOI.LOCALLY_SOLVED || status == MOI.FEASIBLE_POINT)
    sol = zeros(Int, n, n)
    if is_feasible
        x_val = value.(x)
        for i in 1:n, j in 1:n, k in 1:n
            if x_val[i, j, k] > 0.5
                sol[i, j] = k
            end
        end
    end
    return is_feasible, time() - start, sol
end

"""
Heuristically solve an instance
"""
function heuristicSolve()

    # TODO
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
end 

function solveDataSet()
    dataFolder = "../data/"
    resFolder  = "../res/cplex"
    mkpath(resFolder)

    global isOptimal = false
    global solveTime = -1

    for file in filter(x -> occursin(".txt", x), readdir(dataFolder))

        println("-- Resolution of ", file)
        n, d, g = readInputFile(dataFolder * file)
        outputFile = resFolder * file

        if !isfile(outputFile)
            fout = open(outputFile, "w")
            isOptimal, resolutionTime, sol = cplexSolve(n, d, g)
            if isOptimal
                println(fout, "# Solution")
                for i in 1:n
                    println(fout, join(sol[i, :], ","))
                end
                println(fout, "sol = ", sol) 
            end
            println(fout, "solveTime = ", resolutionTime)
            println(fout, "isOptimal = ", isOptimal)
            close(fout)
        end
    end
end