using PyCall, Statistics

include("RelaxAndFix _ FixAndOptimize3.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")

path_file = "result_output.txt"
file = open(path_file, "w")

p = 20
t = 5
version = 1
println("p = ", p)
println("t = ", t)
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

all_milp_obj = Dict("20_5" => [34940.0, 33986.0, 38217.0, 37979.0, 40884.0, 38477.0, 42836.0, 41040.0, 38223.0, 42004.0],
                "20_10" => [75649.0, 75318.0, 70349.0, 73523.0, 75122.0, 76450.95, 72585.0, 73843.0, 77075.0, 74180.0],
                "20_25" => [175442.21, 174472.0, 167159.5, 185668.0, 189345.0, 180328.87, 181632.0, 185645.03, 176057.0, 178614.11],
                "50_5" => [90943.0, 95048.0, 89542.0, 93758.0, 94161.0, 90810.0, 93807.0, 93849.0, 97470.0, 97952.0],
                "50_10" => [170951.0, 174940.0, 175891.0, 169347.0, 176409.0, 180842.0, 170723.0, 178499.0, 182400.0, 177565.0],
                "50_25" => [430921.0, 430022.0, 428524.12, 423512.72, 436813.15, 425615.6, 430211.38, 423116.53, 431499.0, 434110.52],
                "100_5" => [185195.0, 182236.0, 177036.0, 189982.0, 188292.0, 178896.0, 188937.0, 196587.0, 192981.0, 189321.0],
                "100_10" => [350597.0, 357445.0, 358249.0, 356076.0, 351212.0, 349209.0, 358300.0, 344891.0, 357238.0, 360524.0],
                "100_25" => [863450.0, 849901.15, 872649.53, 861565.0, 862420.6, 863857.36, 858350.0, 866143.0, 881055.0, 879120.16])

key = string(p)*"_"*string(t)
milp_obj = all_milp_obj[key]

allgap = Dict()
alltimes = Dict()
nbr_instance = 10


list_rfSize = []
list_rfStep = []
list_gap = []
list_temps = []
for rfSize in 8:8
    println("rfSize = ", rfSize)
    write(file, "\nSize = "*string(rfSize))
    for rfStep in 2:2
        println("rfStep = ", rfStep)
        write(file, "\nStep = "*string(rfStep))

        foSize = 12
        foStep = 2
        rfObjectifs = []
        foObjectifs = []
        rf_times = []
        fo_times = []
        rf_gap_value = []
        fo_gap_value = [] 
        for version in 1:nbr_instance
            println("\n\n--------------------INSTANCE ", version, "------------------------\n")
            write(file, "\n\n--------------------INSTANCE "*string(version)*"------------------------")
            
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
            write(file, "\nRELAX AND FIX")
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
            println("Objectif = ", rf_obj)
            write(file, "\nObjectif = "*string(rf_obj))

            push!(rfObjectifs, rf_obj)
            push!(rf_times, rf_timeElapsed)

            println("FIX AND OPTIMIZE ")
            write(file, "\nFIX AND OPTIMIZE")

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
            println("Objectif = ", fo_obj)
            write(file, "\nObjectif = "*string(fo_obj))
            println("Feasibility of solution : ", verify_solution(sx, sI, sy, sz, sc, instance_dict))
            write(file, "\nFeasibility of solution : "*string(verify_solution(sx, sI, sy, sz, sc, instance_dict)))
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

        time_total = rft_mean + fot_mean
        push!(list_rfSize, rfSize)
        push!(list_rfStep, "step = " * string(rfStep))
        push!(list_gap, fog_mean)
        push!(list_temps, time_total)
        println("Les objectifs avec FO : ", foObjectifs)
    end
end
println("\nListe des Size")
write(file, "\n\nListe des Size")
println(list_rfSize)
write(file, "\n"*string(list_rfSize))

println("\nListe des Step")
write(file, "\nListe des Step")
println(list_rfStep)
write(file, "\n"*string(list_rfStep))

println("\nListe des gap")
write(file, "\nListe des gap")
println(list_gap)
write(file, "\n"*string(list_gap))
println("\nListe des temps")
write(file, "\nListe des temps")
println(list_temps)
write(file, "\n"*string(list_temps))