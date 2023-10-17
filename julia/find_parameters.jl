using PyCall, Statistics

include("methods.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 50
t = 5
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

wSize = 100
olap = 0.6
sLimit = 0

inc = 5
@time rslt = RF_IFO(wSize, olap, wSize, olap, inc, sLimit, instance)

println("\n\nTEST DE PARAMÈTRE ")

phi = 1.618

milp_obj = [164257.0, 170422.0, 177472.0, 173467.0, 165798.0, 171770.0, 180896.0, 161965.0, 172486.0, 161851.0]
allgap = Dict()
alltimes = Dict()
nbr_instance = 10
for windowType in [0 1]
    println("windowType = ", windowType)
    rfSize = 75
    y_l = 0.1
    y_r = 1
    for k in 1:25
        println("K = ", k)
        temp = (y_r - y_l)/phi
        y_1 = round(y_r - temp, digits = 1)
        y_2 = round(y_l + temp, digits = 1)
        println("rfSize = ", rfSize)
        temp_list = []
        for rfOverlap in [y_1, y_2]
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
                #=
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
                =#

            end 
            #println("\nObjectifs : ", Objectifs)
            #println("Times : ", times)
            for j in 1:nbr_instance
                push!(gap_value, round((Objectifs[j]-milp_obj[j])/milp_obj[j]*100, digits = 2))
            end
            #println("Les gap :", gap_value)
            g = round(mean(gap_value),digits = 2)
            #println("La moyenne du gap est : ", g)
            allgap[key] = g
            push!(temp_list, g)
            tm = round(mean(times), digits = 4)
            #println("La moyenne du temps est : ", tm)
            alltimes[key] =  tm
            if (y_r - y_l) < 0.001
                break
            end   
        end
        if temp_list[1] < temp_list[2]
            y_r = y_2
            y_2 = y_1
        else
            y_r = y_2
            y_2 = y_1
        end 
       
         
    end
end

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
