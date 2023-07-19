using JuMP, PyCall, Base, BenchmarkTools

include("./RelaxAndFix _ FixAndOptimize.jl")

include("./genetic_algorithm.jl")
pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")

p = 10
t = 15
version = 1
println("p = ", p)
println("t = ", t)
file_path = "my_instances/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
instance_dict = init.gen_instance(p,t, fp=file_path); 
instance_dict["P"] = 1:p;
instance_dict["T"] = 1:t;
instance_dict["t"] = t
instance_dict["p"] = p
alpha = instance_dict["alpha"]
cmax = instance_dict["cmax"]
demand = instance_dict["demand"]
len_pop = 200

@time current_pop, model1 = generate_pop_initial(len_pop,instance_dict);
#print_pop(current_pop)

sol1, sol2 = current_pop[1], current_pop[2]

sc = sol1.c 

windowSize = 5
windowType = 0
overlap = 0.4
timeLimit = 10
rf_or_fo = "RF"
mdl = buildM(sc, instance_dict, rf_or_fo)
@time result = RelaxAndFix(mdl, windowSize, windowType, overlap, timeLimit, instance_dict)
sx = result["sx"]
sI = result["sI"]
sy = result["sy"]

println("\nMatrice y")
display(sy)
println("\nMatrice x")
display(sx)
println("\nMatrice I")
display(sI)
println("\nMatrice des demandes")
display(demand)
println("\n Capacité : ")
println(sc)

println("Feasibility : ", verify_solution(sx,sI,sy,sol1.z,sc,instance_dict))

#=
println("CROSSOVER")
list_fils_z, list_fils_y = crossover(sol1, sol2, instance_dict);
list_fils_sol = []
for fils_z in list_fils_z
    fils_c = construct_capacities(fils_z, t, alpha, cmax)  
    for fils_y in list_fils_y
        fils_sol, model2 = create_solution(model1,fils_y,fils_z,fils_c,instance_dict)
        push!(list_fils_sol, fils_sol)
    end
end

print(" y parent1 : ")
display(sol1.y)
print("\n y parent2 : ")
display(sol2.y)
print("\n y fils1 : ")
display(list_fils_sol[1].y)

print("\nx parent1 : ")
display(sol1.x)
println(sol1.u)
print("\n x parent2 : ")
display(sol2.x)
println(sol2.u)
print("\n x fils1 : ")
display(list_fils_sol[1].x)
println(list_fils_sol[1].u)

println("\nMUTATION")
fils_z, fils_y = mutation(sol1,instance_dict, false, 0.1)
fils_c = construct_capacities(fils_z, t, alpha, cmax) 
fils_sol, model1 = create_solution(model1,fils_y,fils_z,fils_c,instance_dict);
print("\n y parent 1 : ")
display(sol1.y)
print("\n y fils : ")
display(fils_sol.y)

print("\nx parent1 : ")
display(sol1.x)
println(sol1.u)
print("\nx fils : ")
display(fils_sol.x)
println(fils_sol.u)
=#