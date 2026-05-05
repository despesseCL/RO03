# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

#include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(n::Int, g::Matrix{Int})

    # Create the model
    m = Model(with_optimizer(CPLEX.Optimizer))

    # TODO
    println("In file resolution.jl, in method cplexSolve(), TODO: fix input and output, define the model")


    # h[i, j] = 1 if cells (i, j) and (i, j+1) are connected, 0 if not
    # v[i, j] = 1 if cells (i, j) and (i+1, j) are connected, 0 if not
    # h[i, n] represents a theoretical connections between cells (i, n) and (i, 1), we will set it to zero
    
    @variable(m, h[1:n, 1:n], v[1:n, 1:n], Bin)
    
    # Set all the edges to zero
    @constraint(m, [i in 1:n], h[i, n] == 0)
    @constraint(m, [j in 1:n], v[n, j] == 0)

    # Set the obvious links for white and black pearls on the edges of the grid
    for i in 1:n
        if g[i,1] == 1
            @constraint(m, v[i,1] == 1)
            @constraint(m, v[i-1, 1] == 1)
        if g[i,1] == 2
            @constraint(m, h[i,1] == 1)
            @constraint(m, h[i, 2] == 1)
        if g[i,n] == 1
            @constraint(m, v[i,n] == 1)
            @constraint(m, v[i-1, n] == 1)
        if g[i,n] == 2
            @constraint(m, h[i,n-1] == 1)
            @constraint(m, h[i, n-2] == 1)
    
    for j in 1:n
        if g[1,j] == 1
            @constraint(m, h[1, j] == 1)
            @constraint(m, h[1, j-1] == 1)
        if g[i,1] == 2
            @constraint(m, v[1, j] == 1)
            @constraint(m, v[2, j] == 1)
        if g[n,j] == 1
            @constraint(m, h[n, j] == 1)
            @constraint(m, h[n, j-1] == 1)
        if g[i,1] == 2
            @constraint(m, v[n-1, j] == 1)
            @constraint(m, v[n-2, j] == 1)

    # Set the links going away from the edge for black pearls 1 cell away from the edge of the grid
    for i in 1:n
        if g[i, 2] == 2
            @constraint(m, h[i, 2] == 1)
            @constraint(m, h[i, 3] == 1)
        if g[i, n-1] == 2
            @constraint(m, h[i, n-2] == 1)
            @constraint(m, h[i, n-3] == 1)

    for j in 1:n
        if g[2, j] == 2
            @constraint(m, v[2, j] == 1)
            @constraint(m, v[3, j] == 1)
        if g[n-1, j] == 2
            @constraint(m, v[n-2, j] == 1)
            @constraint(m, v[n-3, j] == 1)

    # Each cell is linked to two or zero adjacent cells
    @constraint(m, [i in 1:n, j in 1:n], h[i,j]+h[i, mod1(j-1,n)]+v[i, j]+v[mod1(i-1,n), j] == 0 || h[i,j]+h[i, mod1(j-1,n)]+v[i, j]+v[mod1(i-1,n), j] == 2)
    "@constraint(m, [i in 2:n-1], h[i,1]+v[i, 1]+v[i-1, 1] == 0 || h[i,1]+v[i, 1]+v[i-1, 1] == 2)
    @constraint(m, [i in 2:n-1], h[i,n-1]+v[i, n]+v[i-1, n] == 0 || h[i, n-1]+v[i, n]+v[i-1, n] == 2)
    @constraint(m, [j in 2:n-1], h[1,j]+h[1, j-1]+v[1, j] == 0 || h[1,j]+h[1, j-1]+v[1, j] == 2)
    @constraint(m, [j in 2:n-1], h[n,j]+h[n, j-1]+v[n-1, j] == 0 || h[n,j]+h[n, j-1]+v[n-1, j] == 2)
    @constraint(m, h[1,1]+v[1,1] == 0 || h[1,1]+v[1,1] == 2)
    @constraint(m, h[1,n-1]+v[1,n] == 0 || h[1,n-1]+v[1,n] == 2)
    @constraint(m, h[n,1]+v[n-1,1] == 0 || h[n,1]+v[n-1,1] == 2)
    @constraint(m, h[n,n-1]+v[n-1,n] == 0 || h[n,n-1]+v[n-1,n] == 2)"

    # Additional constraints specific to the pearls
    for i in 1:n
        for j in 1:n
            if g[i, j] == 1
                @constraint(m, h[i,j]+h[i, mod1(j-1,n)]+v[i, j]+v[mod1(i-1,n), j] == 2)
                @constraint(m, v[mod1(i-1,n), j] + v[i, j] == 0 || v[mod1(i-1,n), j] + v[i, j] == 2)
                @constraint(m, h[i, mod1(j-1,n)] + h[i,j] == 0 || h[i, mod1(j-1,n)] + h[i,j] == 2)
                @constraint(m, h[i, j] == 1 => {v[mod1(i-1,n), mod1(j-1,n)] + v[mod1(i-1,n), mod(j+1,n)] + v[i, mod1(j-1,n)] + v[i, mod1(j+1,n)] >= 1})
                @constraint(m, v[i, j] == 1 => {h[mod1(i-1,n), mod1(j-1,n)] + h[mod1(i-1,n), j] + v[mod1(i+1,n), mod1(j-1,n)] + v[mod1(i+1,n), j] >= 1})

            if g[i, j] == 2
                @constraint(m, [i in 1:n, j in 1:n], h[i,j]+h[i, mod1(j-1,n)]+v[i, j]+v[mod1(i-1,n), j] == 2)
                @constraint(m, v[mod1(i-1,n), j] + v[i, j] == 1)
                @constraint(m, h[i, mod1(j-1,n)] + h[i, j] == 1)
                @constraint(m, v[mod1(i-1,n), j] == 1 => {v[mod1(i-2,n), j] == 1})
                @constraint(m, v[i, j] == 1 => {v[mod1(i+1,n), j] == 1})
                @constraint(m, h[i, mod1(j-1,n)] == 1 => {h[i, mod1(j-2,n)] == 1})
                @constraint(m, h[i, j] == 1 => {v[i, mod1(j+1,n)] == 1})

    # Minimize the length of the loop
    @objective(m, Min, sum(v[i, j]+h[i,j] for i in 1:n, j in 1:n))


    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, h, v, time() - start
    
end

"""
Heuristically solve an instance
"""
"""
function heuristicSolve()

    # TODO
    println("In file resolution.jl, in method heuristicSolve(), TODO: fix input and output, define the model")
    
end 


Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again

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
