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

    # height of tallest tower seen so far
    # Mtop[i,j]   : max height in column j from top    up to (but not incl.) row i
    # Mbot[i,j]   : max height in column j from bottom up to (but not incl.) row i
    # Mleft[i,j]  : max height in row i    from left   up to (but not incl.) col j
    # Mright[i,j] : max height in row i    from right  up to (but not incl.) col j
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
    # h(i,j) = sum_k k * x[i,j,k] height of cell (i,j)
    h = [sum(k * x[i, j, k] for k in 1:n) for i in 1:n, j in 1:n]

"""    for j in 1:n
        # Initialisation : le max à la première ligne est la hauteur de la tour
        @constraint(m, m_top[1, j, 1] == sum(l * x[1, j, l] for l in 1:n))
        @constraint(m, m_top[n, j, 4] == sum(l * x[n, j, l] for l in 1:n))
        for i in 2:n
            h_curr1 = sum(l * x[i, j, l] for l in 1:n)
            # m_top[i, j] >= m_top[i-1, j] et m_top[i, j] >= h_curr
            @constraint(m, m_top[i, j, 1] >= m_top[i-1, j])
            @constraint(m, m_top[i, j, 1] >= h_curr1)
            h_curr4 = sum(l * x[n-i+1, j, l] for l in 1:n)
            @constraint(m, m_top[n-i+1, j, 4] >= m_top[n-i+2, j])
            @constraint(m, m_top[n-i+1, j, 4] >= h_curr4)

        end
    end

    for i in 1:n
        # Initialisation : le max à la première ligne est la hauteur de la tour
        @constraint(m, m_top[i, 1, 2] == sum(l * x[i, 1, l] for l in 1:n))
        @constraint(m, m_top[i, n, 3] == sum(l * x[i, n, l] for l in 1:n))
        for j in 2:n
            h_curr2 = sum(l * x[i, j, l] for l in 1:n)
            # m_top[i, j] >= m_top[i-1, j] et m_top[i, j] >= h_curr
            @constraint(m, m_top[i, j, 2] >= m_top[i, j-1])
            @constraint(m, m_top[i, j, 2] >= h_curr2)
            h_curr3 = sum(l * x[i, n-j+1, l] for l in 1:n)
            @constraint(m, m_top[i, n-j+1, 3] >= m_top[i, n-j+2])
            @constraint(m, m_top[i, n-j+1, 3] >= h_curr3)
        end
    end
    # La première tour est toujours visible
    @constraint(m,[j in 1:n], v[1, j, 1] == 1)
    @constraint(m,[j in 1:n], v[n, j, 4] == 1)
    @constraint(m,[i in 1:n], v[i, 1, 2] == 1)
    @constraint(m,[i in 1:n], v[i, n, 3] == 1)
        for i in 2:n
            h_curr1 = sum(l * x[i, j, l] for l in 1:n)
            h_curr2 = sum(l * x[i, j, l] for l in 1:n)
            h_curr3 = sum(l * x[n-i+1, j, l] for l in 1:n)
            h_curr4 = sum(l * x[i, n-j+1, l] for l in 1:n)
            # Si visible (v=1), alors h_curr doit être > max précédent
            # On utilise h_curr >= m_top[i-1, j] + 1 - N(1 - v)
            @constraint(m, h_curr >= m_top[i-1, j, 1] + 1 - n * (1 - v[i, j, 1]))
            @constraint(m, h_curr >= m_top[i-1, j, 2] + 1 - n * (1 - v[i, j, 1]))
            @constraint(m, h_curr >= m_top[i-1, j] + 1 - n * (1 - v[i, j, 1]))
            @constraint(m, h_curr >= m_top[i-1, j] + 1 - n * (1 - v[i, j, 1]))
            # Si non visible (v=0), h_curr doit être <= max précédent
            @constraint(m, h_curr <= m_top[i-1, j] + n * v[i, j, 1])
        end
    end
"""
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

            # Visibility: vtop[i,j]=1 iff h[i,j] > Mtop[i,j]
            @constraint(m, h[i, j] - Mtop[i, j] + n * vtop[i, j] >= 1)
            @constraint(m, h[i, j] - Mtop[i, j] - n * vtop[i, j] <= 0)
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

            @constraint(m, h[i, j] - Mbot[i, j] + n * vbot[i, j] >= 1)
            @constraint(m, h[i, j] - Mbot[i, j] - n * vbot[i, j] <= 0)
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

            @constraint(m, h[i, j] - Mleft[i, j] + n * vleft[i, j] >= 1)
            @constraint(m, h[i, j] - Mleft[i, j] - n * vleft[i, j] <= 0)
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

            @constraint(m, h[i, j] - Mright[i, j] + n * vright[i, j] >= 1)
            @constraint(m, h[i, j] - Mright[i, j] - n * vright[i, j] <= 0)
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

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        readInputFile(dataFolder * file)

        # TODO
        println("In file resolution.jl, in method solveDataSet(), TODO: read value returned by readInputFile()")
        
        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    
                    # TODO 
                    println("In file resolution.jl, in method solveDataSet(), TODO: fix cplexSolve() arguments and returned values")
                    
                    # Solve it and get the results
                    isOptimal, resolutionTime = cplexSolve()
                    
                    # If a solution is found, write it
                    if isOptimal
                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write cplex solution in fout") 
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # TODO 
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                
                # TODO
                println("In file resolution.jl, in method solveDataSet(), TODO: write the solution in fout") 
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
