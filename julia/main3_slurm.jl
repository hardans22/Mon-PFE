using PyCall, Statistics

include("RelaxAndFix _ FixAndOptimize3.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")

path_file = "result_output0.txt"
file = open(path_file, "w")

p = 20
t = 25
version = 1
#println("p = ", p)
#println("t = ", t)
write(file, "p = "*string(p))
write(file, "\nt = "*string(t))

#println("\nEssai pour compilation")
for version in 1:2
    file_p = "instances/instances_alpha0.8/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt"
    instance = init.gen_instance(p,t, fp=file_p)
    instance["P"] = 1:p
    instance["T"] = 1:t
    instance["t"] = t
    instance["p"] = p 

    wSize = 3
    step = 1

    model = buildM(instance,"RF")

    @time rslt = RelaxAndFix(model, wSize, step, instance)
    sl = create_solution(rslt)
    ssy = rslt["sy"]
    ssz = rslt["sz"]
    mdl = buildM(instance,"FO")

    @time rslt_rf = FixAndOptimize(mdl, ssy, ssz, wSize, step, instance)
end    

all_milp_obj = Dict("5_5" => [15460.0, 20440.0, 19552.0, 18307.0, 20538.4, 17449.0, 18948.48, 21885.0, 22656.4, 19269.88],
                "5_10" => [34436.85, 38259.34, 41255.23, 35847.0, 39499.0, 37237.66, 36087.56, 35852.42, 36894.1, 41932.44],
                "5_25" => [92401.67, 99333.12, 93637.56, 100558.76, 88732.32, 85800.5, 92300.99, 88980.42, 89422.03, 95953.45],
                "20_5" => [65821.0, 71523.0, 72914.0, 77234.8, 64474.0, 74472.0, 64012.0, 67394.0, 66733.0, 69388.0],
                "20_10" => [131695.0, 132328.0, 132119.0, 130755.0, 126487.0, 131454.76, 135600.0, 129495.0, 132536.0, 130459.41],
                "20_25" => [332225.78, 312747.79, 329088.83, 338021.59, 324334.15, 334620.0, 338631.0, 330110.68, 338707.53, 320031.27],
                "50_5" => [164257.0, 170422.0, 177472.0, 173467.0, 165798.0, 171770.0, 180896.0, 161965.0, 172486.0, 161851.0],
                "50_10" => [325130.0, 324754.0, 329134.0, 329527.0, 328015.0, 332403.32, 331663.0, 343003.0, 311613.0, 333907.0],
                "50_25" => [818459.77, 818381.56, 807283.88, 793525.6, 805575.0, 801661.9, 809611.18, 814712.0, 795287.56, 818040.84],
                "100_5" => [332011.0, 339338.6, 331254.0, 327350.0, 339097.0, 334298.0, 327358.0, 335512.0, 328290.0, 340441.0],
                "100_10" => [657875.0, 660381.0, 674392.0, 648278.0, 628996.0, 621788.0, 625850.0, 644203.0, 643854.0, 660441.0],
                "100_25" => [1.59665988e6, 1.60209204e6, 1.60952352e6, 1.57197976e6, 1.58084695e6, 1.59750359e6, 1.5840202e6, 1.59290364e6, 1.58795656e6, 1.6108116e6] )

key = string(p)*"_"*string(t)
milp_obj = all_milp_obj[key]

allgap = Dict()
alltimes = Dict()
nbr_instance = 10


list_rfSize = []
list_rfStep = []
list_gap = Dict()
list_temps = Dict()
for rfSize in 4:2:12
    #println("rfSize = ", rfSize)
    #write(file, "\nSize = "*string(rfSize))
    for rfStep in 2:4:6
        nkey = string(rfSize)*"_"*string(rfStep)
        #println("rfStep = ", rfStep)
        #write(file, "\nStep = "*string(rfStep))

        foSize = rfSize
        foStep = rfStep
        rfObjectifs = []
        foObjectifs = []
        rf_times = []
        fo_times = []
        rf_gap_value = []
        fo_gap_value = [] 
        for version in 1:nbr_instance
            #println("\n\n--------------------INSTANCE ", version, "------------------------\n")
            #write(file, "\n\n--------------------INSTANCE "*string(version)*"------------------------")
            
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
            #write(file, "\nRELAX AND FIX")
            rfmodel = buildM(instance_dict,"RF")
            
            begin_time = time()
            @time result_rf = RelaxAndFix(rfmodel, rfSize, rfStep, instance_dict)
            rf_timeElapsed = round(time() - begin_time, digits = 4)
    
            sx = result_rf["sx"]
            sI = result_rf["sI"]
            sy = result_rf["sy"]
            su = result_rf["su"]
            sz = result_rf["sz"]
            sc = result_rf["sc"]

            rf_obj = round(result_rf["obj"], digits = 2)
            #println("Objectif = ", rf_obj)
            #write(file, "\nObjectif = "*string(rf_obj))

            push!(rfObjectifs, rf_obj)
            push!(rf_times, rf_timeElapsed)

            #println("FIX AND OPTIMIZE ")
            #write(file, "\nFIX AND OPTIMIZE")

            fomodel = buildM(instance_dict,"FO")
            
            begin_time = time()
            @time result_fo = FixAndOptimize(fomodel, sy, sz, foSize, foStep, instance_dict)
            fo_timeElapsed = round(time() - begin_time, digits = 4)
        
            sx = result_fo["sx"]
            sI = result_fo["sI"]
            sy = result_fo["sy"]
            su = result_fo["su"]
            sz = result_fo["sz"]
            sc = result_fo["sc"]
            fo_obj = round(result_fo["obj"], digits  = 2)
            #println("Objectif = ", fo_obj)
            #write(file, "\nObjectif = "*string(fo_obj))
            #println("Feasibility of solution : ", verify_solution(sx, sI, sy, sz, sc, instance_dict))
            #write(file, "\nFeasibility of solution : "*string(verify_solution(sx, sI, sy, sz, sc, instance_dict)))
            push!(foObjectifs, fo_obj)
            push!(fo_times, fo_timeElapsed)     
            rf_temp = round((rf_obj-milp_obj[version])/milp_obj[version]*100, digits = 2)
            fo_temp = round((fo_obj-milp_obj[version])/milp_obj[version]*100, digits = 2)
            push!(rf_gap_value, rf_temp)
            push!(fo_gap_value, fo_temp)
            
        end 
        #=
        for j in 1:nbr_instance
            push!(fo_gap_value, round((foObjectifs[j]-milp_obj[j])/milp_obj[j]*100, digits = 2))
            push!(rf_gap_value, round((rfObjectifs[j]-milp_obj[j])/milp_obj[j]*100, digits = 2))
        end
        =#
        rf_obj_mean = round(mean(rfObjectifs), digits = 2)
        rfg_mean = round(mean(rf_gap_value),digits = 2)
        rft_mean = round(mean(rf_times), digits = 4)
        fo_obj_mean = round(mean(foObjectifs), digits = 2)
        fog_mean = round(mean(fo_gap_value),digits = 2)
        fot_mean = round(mean(fo_times), digits = 4)
        println("\nrfSize = ", rfSize)
        println("rfStep = ", rfStep)
        println("foSize = ", foSize)
        println("foStep = ", foStep)
        #=
        write(file, "\n\n--------------------RESULTATS--------------------")
        println("\nMoyenne des objectifs pour le relax-and-fix = ", rf_obj_mean)
        write(file, "\nMoyenne des objectifs pour le relax-and-fix = "*string(rf_obj_mean))
        
        println("Moyenne des gaps pour le relax-and-fix = ", rfg_mean)
        write(file, "\nMoyenne des gaps pour le relax-and-fix = "*string(rfg_mean))

        println("Moyenne des temps pour le relax-and-fix = ", rft_mean)
        write(file, "\nMoyenne des temps pour le relax-and-fix = "*string(rft_mean))

        println("\nMoyenne des objectifs pour le fix-and-optimize = ", fo_obj_mean)
        write(file, "\n\n\nMoyenne des objectifs pour le fix-and-optimize = "*string(fo_obj_mean))

        println("Moyenne des gaps pour le fix-and-optimize = ", fog_mean)
        write(file, "\nMoyenne des gaps pour le fix-and-optimize = "*string(fog_mean))

        println("Moyenne des temps pour le fix-and-optimize = ", fot_mean)
        write(file, "\nMoyenne des temps pour le fix-and-optimize = "*string(fot_mean))
        =#
        time_total = rft_mean + fot_mean
        push!(list_rfSize, rfSize)
        push!(list_rfStep, "step = " * string(rfStep))
        list_gap[nkey] = fog_mean
        list_temps[nkey] = time_total
        #println("Les objectifs avec FO : ", foObjectifs)
    end
end
#=
println("\nListe des Size")
write(file, "\n\nListe des Size")
println(list_rfSize)
write(file, "\n"*string(list_rfSize))

println("\nListe des Step")
write(file, "\nListe des Step")
println(list_rfStep)
write(file, "\n"*string(list_rfStep))
=#

list_gap = sort(list_gap, by=x -> list_gap[x])
list_key_zero = []
for key in keys(list_gap)
    if list_gap[key] == 0.0
        push!(list_key_zero, key)
    end
end

zero_time = Dict()
for key in list_key_zero
    zero_time[key] = list_temps[key]
end 
zero_time = sort(zero_time, by=x -> zero_time[x])

println("\nListe des gap")
write(file, "\nListe des gap")
println(list_gap)
write(file, "\n"*string(list_gap))
println("\nListe des temps")
write(file, "\nListe des temps")
println(zero_time)
write(file, "\n"*string(zero_time))
