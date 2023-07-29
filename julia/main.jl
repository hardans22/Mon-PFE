using JuMP, Random, PyCall, Profile

include("./genetic_algorithm.jl")
include("RelaxAndFix _ FixAndOptimize.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 25
t = 20
version = 9
println("p = ", p)
println("t = ", t)

best_sol_obj = [] 
sol_opt_obj = []

#version = 1
println("\n--------------------------------------------------INSTANCE ", version, "-----------------------------------------------------------\n")
file_path = "instances/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
instance_dict = init.gen_instance(p,t, fp=file_path); 
instance_dict["P"] = 1:p;
instance_dict["T"] = 1:t;
instance_dict["t"] = t
instance_dict["p"] = p
alpha = instance_dict["alpha"]
cmax = instance_dict["cmax"]
mtn_cost = instance_dict["mtn_cost"]
set_up_cost = instance_dict["set_up_cost"]

@time result =  genetic_algorithm(instance_dict, 10, 5)   

println("\n\nALGORITHME GÉNÉTIQUE")

len_pop = 300
timeAG = 130
println("len_pop = ", len_pop)
println("Temps d'exécution = ", timeAG)

@time result =  genetic_algorithm(instance_dict, len_pop,timeAG)   

objectives = result["objectives"]
best_sol = result["best_sol"]
#push!(best_sol_list, best_sol.obj)
push!(best_sol_obj, best_sol.obj)
println(best_sol.obj)
println(sum(best_sol.z))
l = []
sz = best_sol.z
sc = best_sol.c
sy = best_sol.y
su = best_sol.u
println("Feasibility of solution : ", verify_solution(best_sol.x, best_sol.I, sy, sz, sc, instance_dict))
println("Maintenance : ",sz)
println("Surplus : ",su) 
println("Matrice des setup : ")
display(sy)
for i in 1:p
	push!(l, sum(sy[i,:]))
end
println(l)

println("\nFIX AND OPTIMIZE")
windowSize = 15
overlap = 0.6
timeLimit = 70

tolerance = 1
increment = 2

result1 = general_FO(best_sol, windowSize, overlap, 5, tolerance, increment, instance_dict)

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
