using  PyCall

include("methods.jl")


pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 20
t = 10 
version = 1
println("p = ", p)
println("t = ", t)

println("\nEssai pour compilation\n")
file_p = "instances/instances_alpha0.8/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
instance = init.gen_instance(p,t, fp=file_p); 
instance["P"] = 1:p;
instance["T"] = 1:t;
instance["t"] = t
instance["p"] = p 
wSize = 50
overlap= 0.8
sLimit = 55
increment = 5
@time sol =  RF_IFO(wSize, overlap, wSize, overlap, increment, sLimit, instance)

println("\n\n EXPÉRIMENTATION")
for version in 1:1
	println("\n--------------------INSTANCE ", version, "------------------------\n")
	file_path = "instances/instances_alpha0.8/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
	instance_dict = init.gen_instance(p,t, fp=file_path); 
	instance_dict["P"] = 1:p;
	instance_dict["T"] = 1:t;
	instance_dict["t"] = t
	instance_dict["p"] = p 
	alpha = instance_dict["alpha"]
	cmax = instance_dict["cmax"]
	mtn_cost = instance_dict["mtn_cost"]
	set_up_cost = instance_dict["set_up_cost"]

    rfSize = 50
	rfOverlap = 0.8
	
	foSize = 75
	foOverlap = 0.6
    inc = 5
	sizeLimit = round(Int, p*t*0.9)
	
	println("\n\nRELAX AND FIX - FIX AND OPTIMIZE")
	@time best_sol1 =  RF_IFO(rfSize, rfOverlap, foSize, foOverlap, inc, sizeLimit, instance_dict )

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
