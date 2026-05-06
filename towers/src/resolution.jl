# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(n::Int,d::Matrix{Int}, g::Matrix{Int})

    # Create the model
    m = Model(with_optimizer(CPLEX.Optimizer))
    # x[i, j, k] = 1 if cell (i, j) has value k
    @variable(m, x[1:n, 1:n, 1:n], Bin)
    # v[i, j, k] = 1 if cell (i, j) has value is visible by side k. 
    #    k=1 on top ; k=2 on the left ; k=3 on the right ; k=4 on bottom
    @variable(m, v[1:n, 1:n, 1:4], Bin)
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
    # Each cell (i, j) has one value k
    @constraint(m, [i in 1:n, j in 1:n], sum(x[i, j, k] for k in 1:n) == 1)

    # Each line i has one cell with value k
    @constraint(m, [k in 1:n, i in 1:n], sum(x[i, j, k] for j in 1:n) == 1)

    # Each column c has one cell with value k
    @constraint(m, [k in 1:n, j in 1:n], sum(x[i, j, k] for i in 1:n) == 1)

    # The sum of visibility must be equal to the constraints (top and bottom)
    @constraint(m, [i in 1:n], sum(v[i, j, 1] for j in 1:n) == d[1,i])
    @constraint(m, [i in 1:n], sum(v[i, j, 4] for j in 1:n) == d[4,i])

    # The sum of visibility must be equal to the constraints (sides)
    @constraint(m, [j in 1:n], sum(v[i, j, 2] for i in 1:n) == d[2,j])
    @constraint(m, [j in 1:n], sum(v[i, j, 3] for i in 1:n) == d[3,j])

    # TODO
    println("In file resolution.jl, in method cplexSolve(), TODO: fix input and output, define the model")

    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)

    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start
    
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
