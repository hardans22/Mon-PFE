using PyCall, Statistics

include("methods.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 5
t = 10
version = 1
println("p = ", p)
println("t = ", t)

println("\nEssai pour compilation")
file_p = "instances/instances_alpha0.8/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt"
instance = init.gen_instance(p,t, fp=file_p)
instance["P"] = 1:p
instance["T"] = 1:t
instance["t"] = t
instance["p"] = p 

wSize = 15
olap = 0.6
sLimit = 0

inc = 5
@time rslt = RF_IFO(wSize, olap, wSize, olap, inc, sLimit, instance)

println("\n\nTEST DE PARAMÈTRE rfOverlap")
rfSize = 55
windowType = 1
if windowType == 0
    println("\nPARCOURS HORIZONTAL")
else
    println("\nPARCOURS VERTICAL")
end
println("windowType = ", windowType)
println("\nrfSize = ", rfSize)


#milp_obj = [15459.99 20440.0 19551.99 18307.0 20538.39 17449.0 18948.47 21884.99 22656.39 19269.87]
milp_obj = [34436.85, 38259.34, 41255.23, 35847.0, 39499.0, 37237.66, 36087.56, 35852.42, 36894.1, 41932.44]
allgap = []
alltimes = []
nbr_instance = 10

for rfOverlap in 0.2:0.1:0.9
    Objectifs = []
    times = []
    gap_value = [] 
    println("\nrfSize = ", rfSize)
    for version in 1:nbr_instance
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

        println("RELAX AND FIX ")
        rfmodel = buildM(instance_dict,"RF")
        
        begin_time = time()
        @time result_rf = RelaxAndFix(rfmodel, rfSize, windowType, rfOverlap, instance_dict)
        timeElapsed = time() - begin_time
        push!(times, round(timeElapsed, digits = 2))
        sol = create_solution(result_rf)
        sx = sol.x
        sI = sol.I
        sy = sol.y
        su = sol.u
        sz = sol.z
        sc = sol.c
        obj = sol.obj
        push!(Objectifs, round(obj, digits = 2))
        println(sum(sz))
        println("OBJECTIF =  ", obj)
        println("Feasibility of solution : ", verify_solution(sx, sI, sy, sz, sc, instance_dict))
        println("Maintenance : ",sz)
        println("Surplus : ",su) 
        l = []
        for i in 1:p
            push!(l, sum(sy[i,:]))
        end
        println(l)

        #=
        println("\n\nITERATED FIX AND OPTIMIZE")
        rfSize = 5
        rfOverlap = 0.6
        
        foSize = 120
        foOverlap = 0.6
        inc = 10
        sizeLimit = round(Int, p*t*0.8)
        @time best_sol1 =  iterated_FO(rfSize, rfOverlap, foSize, foOverlap, inc, sizeLimit, instance_dict )

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
        =#
    end 
    println("\nObjectifs : ", Objectifs)
    println("Times : ", times)
    for j in 1:nbr_instance
        push!(gap_value, round((Objectifs[j]-milp_obj[j])/milp_obj[j]*100, digits = 2))
    end
    println("Les gap :", gap_value)
    g = round(mean(gap_value),digits = 2)
    println("La moyenne du gap est : ", g)
    push!(allgap, g)
    tm = round(mean(times), digits = 4)
    println("La moyenne du temps est : ", tm)
    push!(alltimes, tm)
end

println("\n \nListes des gaps moyens de chaque valeur: ", allgap)
println("\n \nListes des temps moyens de chaque valeur: ", alltimes)
