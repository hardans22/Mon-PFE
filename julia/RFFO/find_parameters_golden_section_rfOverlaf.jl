using PyCall, Statistics

include("methods.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


p = 20
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

wSize = 25
olap = 0.6
sLimit = 0

inc = 5
@time rslt = RF_IFO(wSize, olap, wSize, olap, inc, sLimit, instance)

println("\n\nTEST DE PARAMÈTRE ")

phi = 1.618

milp_obj = [131695.0, 132328.0, 132119.0, 130755.0, 126487.0, 131454.76, 135600.0, 129495.0, 132536.0, 130459.41]

allgap = Dict()
alltimes = Dict()
nbr_instance = 10
for windowType in [0 1]
    println("windowType = ", windowType)
    for rfSize in 30:15:200
        y_l = 0.2
        y_r = 0.9
        f_overlap = Dict() 
        temp_y = (y_r - y_l)/phi
        y_1 = y_r - temp_y
        y_2 = y_l + temp_y
            
        for k in 1:25
            println("K = ", k)
            println("y_l = ", y_l)
            println("y_r = ", y_r)
            println("rfSize = ", rfSize)

            temp_overlap = []
            temp_y1 = round(y_1, digits = 1)
            temp_y2 = round(y_2, digits = 1)
            if !(temp_y1 in keys(f_overlap))
                push!(temp_overlap, temp_y1)
            end 
            if !(temp_y2 in keys(f_overlap))
                push!(temp_overlap, temp_y2)
            end 
            for rfOverlap in temp_overlap
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
                g = round(mean(gap_value),digits = 2)
                allgap[key] = g
                tm = round(mean(times), digits = 4)
                alltimes[key] =  tm
                f_overlap[rfOverlap] = g 
            end
            if f_overlap[temp_y1] < f_overlap[temp_y2]
                y_r = y_2
                y_2 = y_1
                y_1 = y_r - (y_r - y_l)/phi
            else
                y_l = y_1
                y_1 = y_2
                y_2 = y_l + (y_r - y_l)/phi
            end 
            
            if (y_r - y_l) <= 0.05
                break
            end   
        end
        println("f_overlap = ", f_overlap)
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
