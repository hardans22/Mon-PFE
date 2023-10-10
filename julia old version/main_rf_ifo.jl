using  PyCall

include("RelaxAndFix _ FixAndOptimize2.jl")
include("functions.jl")


pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 25
t = 15 
cst = 5  #COÛT DE PÉNÉLISATION DES SOLUTIONS INFAISABLES
version = 1
println("p = ", p)
println("t = ", t)

println("\nEssai pour compilation\n")
file_p = "instances/instances_alpha0.8/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt"
instance = init.gen_instance(p,t, fp=file_p)
instance["P"] = 1:p
instance["T"] = 1:t
instance["t"] = t
instance["p"] = p 
instance["cst"] = cst
mdl = buildM(instance,"RF")
wSize = 20
wType = 0
olap = 0.6
tLimit = 15
inc = 5
@time rslt_rf = RelaxAndFix(mdl, wSize, wType, olap, instance)

bsol = create_solution(rslt_rf)

@time rslt_fo = general_FO(bsol, wSize, olap, tLimit, inc, instance)

for version in 1:1
	println("\n--------------------INSTANCE ", version, "------------------------\n")
	file_path = "instances/instances_alpha0.8/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
	instance_dict = init.gen_instance(p,t, fp=file_path); 
	instance_dict["P"] = 1:p;
	instance_dict["T"] = 1:t;
	instance_dict["t"] = t
	instance_dict["p"] = p 
	instance_dict["cst"] = cst
	alpha = instance_dict["alpha"]
	cmax = instance_dict["cmax"]
	mtn_cost = instance_dict["mtn_cost"]
	set_up_cost = instance_dict["set_up_cost"]

    windowSize = 15
    windowType = 0
	overlap = 0.6
	

	increment = 10

	
	println("\nRELAX AND FIX")
	print("increment = ", increment, "\n \n")
	print("overlap = ", overlap, "\n \n")
    model = buildM(instance_dict,"RF")
    @time result_rf = RelaxAndFix(model, windowSize, windowType, overlap, instance_dict)

    best_sol = create_solution(rslt_rf)
    sx = best_sol.x
	sI = best_sol.I
	sy = best_sol.y
	su = best_sol.u
	sz = best_sol.z
    sc = best_sol.c
    println(sum(sz))
	println("Feasibility of solution : ", verify_solution(sx, sI, sy, sz, sc, instance_dict))
	println("Maintenance : ",sz)
	println("Surplus : ",su) 
	#println("Matrice des setup : ")
	#display(sy)
    l = []
	for i in 1:p
		push!(l, sum(sy[i,:]))
	end
	println(l)

    timeLimit = 60
    @time best_sol = general_FO(best_sol, wSize, olap, timeLimit, increment, instance)
    
    increment = 5
    timeLimit = 240
    @time best_sol1 = general_FO(best_sol, wSize, olap, timeLimit, increment, instance)
    sx = best_sol1.x
	sI = best_sol1.I
	sy = best_sol1.y
	su = best_sol1.u
	sz = best_sol1.z
    sc = best_sol1.c
    println(sum(sz))
	println("Feasibility of solution : ", verify_solution(sx, sI, sy, sz, sc, instance_dict))
	println("Maintenance : ",sz)
	println("Surplus : ",su) 
	#println("Matrice des setup : ")
	#display(sy)
    l = []
	for i in 1:p
		push!(l, sum(sy[i,:]))
	end
	println(l)
end 
