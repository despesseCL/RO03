using JuMP
using CPLEX

m = Model(CPLEX.Optimizer)

# Définition d’une variable binaire
@variable(m, x, Bin)
# Définition d’une variable réelle
@variable(m, y >= 0)
# Définition d’un vecteur de 10 variables entières
@variable(m, z[1:10] >= 0, Int)
# Définition d’une matrice de 5x4 variables
@variable(m, w[1:5,1:4] >= 0)

@constraint(m, x + y >=1)
@constraint(m, [i in 1:10], z[i] >= i)
@constraint(m, sum(z[i] for i in 1:10) <= 70)
# Définition d’une contrainte avec condition dans une somme
@constraint(m, sum(z[i] for i in 1:10 if rem(i, 2) == 0) >= 40)
# Définition d’une contrainte pour tout i avec une condition sur i
@constraint(m, [i in 1:10; rem(i, 3) == 1], z[i] >= 3)


@objective(m, Min, x - y)
@objective(m, Max, sum(z[i] for i in 1:10))

