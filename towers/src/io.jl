# This file contains functions related to reading, writing and displaying a grid and experimental results

using JuMP
using Plots
import GR

"""
Read an instance from an input file

- Argument:
inputFile: path of the input file
"""

function readInputFile(inputFile::String)
    # Lire le fichier
    datafile = open(inputFile)
    data = readlines(datafile)
    data = filter(l -> strip(l) != "", data)
    close(datafile)
    if isempty(data)
        error("Fichier vide après nettoyage")
    end
    n = length(split(data[1], ","))

    # Initialisation des matrices
    d = Matrix{Int}(undef, 4, n)
    g = Matrix{Int}(undef, n, n)
    # Remplir d (premier bloc)
    for i in 1:4
        lineSplit = split(data[i], ",")
        for j in 1:n
            val = strip(lineSplit[j])
            if isempty(val)
                d[i, j] = 0
            else d[i, j] = parse(Int, val)
            end
        end
    end

    # Remplir c (deuxième bloc)
    for i in 1:n
        lineSplit = split(data[4 + i], ",")
        for j in 1:n
            val = strip(lineSplit[j])
            if isempty(val)
                g[i, j] = 0
            else g[i, j] = parse(Int, val)
            end
        end
    end
    return n, d, g
end


function displayGrid(n::Int,d::Matrix{Int}, g::Matrix{Int})
    # Afficher les indices du haut (top)
        print("  ")
    for j in 1:n
        if d[1, j] != 0
            print("   $(d[1, j])  ")
        else
            print("      ")
        end
    end
    println()

    # Bordure supérieure
    println("  +" * ("-----+" ^ n))

    for i in 1:n
        # Indices de gauche (left)
        if d[2, i] != 0
            print("$(d[2, i]) |")
        else
            print("  |")
        end

        # Contenu des cellules
        for j in 1:n
            if g[i, j] != 0
                print("  $(g[i, j])  |")
            else
                print("     |")
            end
        end

        # Indices de droite (right)
        if d[3, i] != 0
            println(" $(d[3, i])")
        else
            println()
        end

        # Bordure intermédiaire
        if i < n
            println("  +" * ("-----+" ^ n))
        end
    end

    # Bordure inférieure
    println("  +" * ("-----+" ^ n))

    # Afficher les indices du bas (bottom)
    print("  ")
    for j in 1:n
        if d[4, j] != 0
            print("   $(d[4, j])  ")
        else
            print("      ")
        end
    end
    println()
end


function displaySolution(n::Int, d::Matrix{Int}, sol::Matrix{Int})
    displayGrid(n, d, sol)
end
"""
Create a pdf file which contains a performance diagram associated to the results of the ../res folder
Display one curve for each subfolder of the ../res folder.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function saveInstance(n::Int, d::Matrix{Int}, g::Matrix{Int}, outputFile::String)
    fout = open(outputFile, "w")
    for i in 1:4
        line = join([d[i, j] == 0 ? " " : string(d[i, j]) for j in 1:n], ",")
        println(fout, line)
    end
    println(fout, "")
    for i in 1:n
        line = join([g[i, j] == 0 ? " " : string(g[i, j]) for j in 1:n], ",")
        println(fout, line)
    end

    close(fout)
end

function performanceDiagram(outputFile::String)

    resultFolder = "../res/"
    maxSize = 0
    subfolderCount = 0
    folderName = Array{String, 1}()

    for file in readdir(resultFolder)
        path = resultFolder * file
        if isdir(path)
            folderName = vcat(folderName, file)
            subfolderCount += 1
            folderSize = size(readdir(path), 1)
            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end
    if subfolderCount == 0
        println("Eror : no files finded in ", resultFolder)
        return
    end

    # 2. Collecte des données de résolution
    results = Array{Float64}(undef, subfolderCount, maxSize)
    for i in 1:subfolderCount, j in 1:maxSize
        results[i, j] = Inf
    end

    folderCount = 0
    maxSolveTime = 0

    for file in readdir(resultFolder)
        path = resultFolder * file
        if isdir(path)
            folderCount += 1
            fileCount = 0
            for resultFile in filter(x->occursin(".txt", x), readdir(path))
                fileCount += 1
                include(path * "/" * resultFile)
                if isOptimal
                    results[folderCount, fileCount] = solveTime
                    if solveTime > maxSolveTime
                        maxSolveTime = solveTime
                    end 
                end 
            end 
        end
    end 

    results = sort(results, dims=2)
    println("Max solve time: ", maxSolveTime)

    p = plot(legend = :bottomright, xaxis = "Time (s)", yaxis = "Solved instances")

    for dim in 1:size(results, 1)
        x = [0.0]
        y = [0.0]
        previousX = 0.0
        currentId = 1

        while currentId <= size(results, 2) && results[dim, currentId] != Inf
            append!(x, [results[dim, currentId], results[dim, currentId]])
            append!(y, [currentId - 1, currentId])
            previousX = results[dim, currentId]
            currentId += 1
        end

        append!(x, maxSolveTime)
        append!(y, currentId - 1)

        plot!(p, x, y, label = folderName[dim], linewidth=3)
    end

    savefig(p, outputFile)
    println("Graph downloaded on : ", outputFile)
end

"""
Create a latex file which contains an array with the results of the ../res folder.
Each subfolder of the ../res folder contains the results of a resolution method.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function resultsArray(outputFile::String)
    
    resultFolder = "../res/"
    dataFolder = "../data/"
    
    # Maximal number of files in a subfolder
    maxSize = 0

    # Number of subfolders
    subfolderCount = 0

    # Open the latex output file
    fout = open(outputFile, "w")

    # Print the latex file output
    println(fout, raw"""\documentclass{article}

\usepackage[french]{babel}
\usepackage [utf8] {inputenc} % utf-8 / latin1 
\usepackage{multicol}

\setlength{\hoffset}{-18pt}
\setlength{\oddsidemargin}{0pt} % Marge gauche sur pages impaires
\setlength{\evensidemargin}{9pt} % Marge gauche sur pages paires
\setlength{\marginparwidth}{54pt} % Largeur de note dans la marge
\setlength{\textwidth}{481pt} % Largeur de la zone de texte (17cm)
\setlength{\voffset}{-18pt} % Bon pour DOS
\setlength{\marginparsep}{7pt} % Séparation de la marge
\setlength{\topmargin}{0pt} % Pas de marge en haut
\setlength{\headheight}{13pt} % Haut de page
\setlength{\headsep}{10pt} % Entre le haut de page et le texte
\setlength{\footskip}{27pt} % Bas de page + séparation
\setlength{\textheight}{668pt} % Hauteur de la zone de texte (25cm)

\begin{document}""")

    header = raw"""
\begin{center}
\renewcommand{\arraystretch}{1.4} 
 \begin{tabular}{l"""

    # Name of the subfolder of the result folder (i.e, the resolution methods used)
    folderName = Array{String, 1}()

    # List of all the instances solved by at least one resolution method
    solvedInstances = Array{String, 1}()

    # For each file in the result folder
    for file in readdir(resultFolder)

        path = resultFolder * file
        
        # If it is a subfolder
        if isdir(path)

            # Add its name to the folder list
            folderName = vcat(folderName, file)
             
            subfolderCount += 1
            folderSize = size(readdir(path), 1)

            # Add all its files in the solvedInstances array
            for file2 in filter(x->occursin(".txt", x), readdir(path))
                solvedInstances = vcat(solvedInstances, file2)
            end 

            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end

    # Only keep one string for each instance solved
    unique(solvedInstances)

    # For each resolution method, add two columns in the array
    for folder in folderName
        header *= "rr"
    end

    header *= "}\n\t\\hline\n"

    # Create the header line which contains the methods name
    for folder in folderName
        header *= " & \\multicolumn{2}{c}{\\textbf{" * folder * "}}"
    end

    header *= "\\\\\n\\textbf{Instance} "

    # Create the second header line with the content of the result columns
    for folder in folderName
        header *= " & \\textbf{Temps (s)} & \\textbf{Optimal ?} "
    end

    header *= "\\\\\\hline\n"

    footer = raw"""\hline\end{tabular}
\end{center}

"""
    println(fout, header)

    # On each page an array will contain at most maxInstancePerPage lines with results
    maxInstancePerPage = 30
    id = 1

    # For each solved files
    for solvedInstance in solvedInstances

        # If we do not start a new array on a new page
        if rem(id, maxInstancePerPage) == 0
            println(fout, footer, "\\newpage")
            println(fout, header)
        end 

        # Replace the potential underscores '_' in file names
        print(fout, replace(solvedInstance, "_" => "\\_"))

        # For each resolution method
        for method in folderName

            path = resultFolder * method * "/" * solvedInstance

            # If the instance has been solved by this method
            if isfile(path)

                include(path)

                println(fout, " & ", round(solveTime, digits=2), " & ")

                if isOptimal
                    println(fout, "\$\\times\$")
                end 
                
            # If the instance has not been solved by this method
            else
                println(fout, " & - & - ")
            end
        end

        println(fout, "\\\\")

        id += 1
    end

    # Print the end of the latex file
    println(fout, footer)

    println(fout, "\\end{document}")

    close(fout)
    
end 
