using JuMP, Random, PyCall, Profile

include("./genetic_algorithm.jl")
include("RelaxAndFix _ FixAndOptimize.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 20
t = 20
version = 2
println("p = ", p)
println("t = ", t)

println("\nLes pararmètres choisis")
println("Mise à jour des contraintes pour l'évaluation d'une solution")
println("Les deux tiers premiers pour la sélection")
println("Stop au bout de 15 itération sans amélioration")
println("Sans restart")
println("len_clonage = div(len_pop, 3)*2")
println("nbr_crossover = div(len_pop, 3)")
println("nbr_mutation = div(len_pop, 3)")
best_sol_obj = [] 
sol_opt_obj = []

#version = 1
println("\n--------------------------------------------------INSTANCE ", version, "-----------------------------------------------------------\n")
file_path = "my_instances/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
instance_dict = init.gen_instance(p,t, fp=file_path); 
instance_dict["P"] = 1:p;
instance_dict["T"] = 1:t;
instance_dict["t"] = t
instance_dict["p"] = p
alpha = instance_dict["alpha"]
cmax = instance_dict["cmax"]
mtn_cost = instance_dict["mtn_cost"]
set_up_cost = instance_dict["set_up_cost"]

println("Algorithme génétique")
len_pop = 200
nbr_iteration = 200
println("len_pop = ", len_pop)
println("nbr_iteration = ", nbr_iteration)

rst = true

@time result =  genetic_algorithm(instance_dict, len_pop, nbr_iteration, rst)   

objectives = result["objectives"]
best_sol = result["best_sol"]
#push!(best_sol_list, best_sol.obj)
push!(best_sol_obj, best_sol.obj)
println(best_sol.obj)
println(sum(best_sol.z))
l = []
for i in 1:p
	push!(l, sum(best_sol.y[i,:]))
end

println("Feasibility of solution : ", verify_solution(best_sol.x, best_sol.I, best_sol.y, best_sol.z, best_sol.c, instance_dict))
sz = best_sol.z
sc = best_sol.c
sy = best_sol.y
println("Maintenance : ",best_sol.z)
println("Surplus : ",best_sol.u) 
println("Matrice des setup : ")
display(best_sol.y)
println(l)

println("\nFIX AND OPTIMIZE")
windowSize = 15
overlap = 0.4
timeLimit = 70

#=
rf_or_fo = "FO"
mdl = buildM(sz, sc, instance_dict, "FO")
sol_y = sy
@time result1 = FixAndOptimize(mdl, sol_y, windowSize, overlap, timeLimit, instance_dict)
=#
tolerance = 1
increment = 2
@time result1 = general_FO(best_sol, windowSize, overlap, timeLimit, tolerance, increment, instance_dict)
sx = result1["sx"]
sI = result1["sI"]
sy = result1["sy"]
su = result1["su"]

println("Feasibility of solution : ", verify_solution(sx, sI, sy, sz, sc, instance_dict))

#=
model = build_model(instance_dict)
r = resolve_CLSP(model,sy,sc,instance_dict,1)
cost = sum(set_up_cost .* sy) + dot(mtn_cost,sz)
println(r["clsp_obj"] + cost)
println(r["z_prime"])
println(r["z"])
	=#

#=
println("Capacité : ",best_sol.c) 
println("Surplus : ",best_sol.u) 
println("x")
display(best_sol.x)
println("I")
display(best_sol.I)
println("Demand")
display(instance_dict["demand"])
println(l)
println() 
=#
