using PyCall, Statistics

include("methods.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 100
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
demand = instance["demand"]
for i in 1:p
    println("item ", i)
    println("moyenne de la demande = ", mean(demand[i,:]))
end

wSize = 25
olap = 0.6
sLimit = 0

inc = 5
@time rslt = RF_IFO(wSize, olap, wSize, olap, inc, sLimit, instance)

println("\n\nTEST DE PARAMÈTRE ")


milp_obj = [657875.0, 660381.0, 674392.0, 648278.0, 628996.0, 621788.0, 625850.0, 644203.0, 643854.0, 660441.0]

allgap = Dict()
alltimes = Dict()
nbr_instance = 10
dict_gap = Dict()
dict_temps = Dict()
for windowType in [0 1]
    println("windowType = ", windowType)
    list_rfSize = []
    list_rfoverlap = []
    list_gap = []
    list_temps = []
    for rfSize in 320:320
        println("rfSize = ", rfSize)
        for rfOverlap in 0.7:0.7
            
            println("rfOverlap = ", rfOverlap)
            
            if windowType == 0
                key ="H_" * string(rfSize) * "_" * string(rfOverlap)
            else 
                key ="V_" * string(rfSize) * "_" * string(rfOverlap)
            end
            Objectifs = []
            times = []
            gap_value = [] 
            for version in 1:nbr_instance
                #println("\n--------------------INSTANCE ", version, "------------------------\n")
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

                #println("RELAX AND FIX ")
                rfmodel = buildM(instance_dict,"RF")
                
                begin_time = time()
                @time result_rf = RelaxAndFix(rfmodel, rfSize, windowType, rfOverlap, instance_dict)
                timeElapsed = time() - begin_time
                push!(times, round(timeElapsed, digits = 4))
                sol = create_solution(result_rf)
                sx = sol.x
                sI = sol.I
                sy = sol.y
                su = sol.u
                sz = sol.z
                sc = sol.c
                obj = sol.obj
                push!(Objectifs, round(obj, digits = 2))
            end 
            for j in 1:nbr_instance
                push!(gap_value, round((Objectifs[j]-milp_obj[j])/milp_obj[j]*100, digits = 2))
            end
            push!(list_rfSize, rfSize)
            push!(list_rfoverlap, string(rfOverlap))

            g = round(mean(gap_value),digits = 2)
            allgap[key] = g
            tm = round(mean(times), digits = 4)
            alltimes[key] =  tm
            push!(list_gap, g)
            push!(list_temps, tm)
        end
    end
    if windowType == 0
        dict_gap["H"] = list_gap
        dict_temps["H"] = list_temps
    else 
        dict_gap["V"] = list_gap
        dict_temps["V"] = list_temps 
    end
    println("\nListe des rfSize")
    println(list_rfSize)
    println("\nListe des rfOverlap")
    println(list_rfoverlap)
end

println("Pour le parcours horizontal")
println("Liste des gaps")
println(dict_gap["H"])
println("Liste des temps")
println(dict_temps["H"])

println("\n\nPour le parcours vertical")
println("Liste des gaps")
println(dict_gap["V"])
println("Liste des temps")
println(dict_temps["V"])



"""
function print_dict(d)
    for k in collect(keys(d))
        println(k, " : ", d[k])
    end
end 

println("\n\nTEST DE PARAMÈTRE ")
println("p = ", p)
println("t = ", t)


allgap = sort(allgap, by=x -> allgap[x])
alltimes = sort(alltimes, by=x -> alltimes[x])

println("\n \nListes des gaps moyens de chaque valeur: \n")
print_dict(allgap)
dict_t = Dict()
for k in collect(keys(allgap))
    if allgap[k] == 0
        dict_t[k] = alltimes[k]
    end
end
dict_t = sort(dict_t, by=x -> dict_t[x])
println("\n \nListes des temps moyens pour les gap zéro: \n")
print_dict(dict_t)
println("\n \nListes des temps moyens de chaque valeur: \n")
print_dict(alltimes)
"""