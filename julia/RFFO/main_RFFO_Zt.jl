using PyCall, Statistics

include("RelaxAndFix _ FixAndOptimize_Zt.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "../")
init  = pyimport("__init__")

option_instance = "ABC"

if option_instance == "ABC"
    path_file = "result_RFFO_Zt_ABC.txt"
    path_f = "result_RFFO_Zt_1_ABC.txt"
else
    path_file = "result_RFFO_Zt.txt"
    path_f = "result_RFFO_Zt_1.txt"
end 

file = open(path_file, "w")
file1 = open(path_f, "w")


#Les informations necessaires 

list_p = [5, 20] 
list_t = [5, 10]

if option_instance == "ABC"
    all_milp_obj = Dict("5_5" => [14028.0, 11378.0, 11392.0, 13043.0, 13358.0, 12370.0, 9292.0, 11934.0, 13044.0, 9475.0],
                "5_10" => [22940.81, 22286.0, 19925.78, 22155.21, 19613.0, 22532.32, 20632.31, 23396.85, 20817.44, 25502.0],
                "5_25" => [51668.68, 54104.92, 52065.72, 48545.16, 48423.88, 59280.69, 50906.0, 52130.44, 54922.47, 54197.88],
                "20_5" => [34940.0, 33986.0, 38217.0, 37979.0, 40884.0, 38477.0, 42836.0, 41040.0, 38223.0, 42004.0],
                "20_10" => [75649.0, 75318.0, 70349.0, 73523.0, 75122.0, 76450.95, 72585.0, 73843.0, 77075.0, 74180.0],
                "20_25" => [175442.21, 174472.0, 167159.5, 185668.0, 189345.0, 180328.87, 181632.0, 185645.03, 176057.0, 178614.11],
                "50_5" => [90943.0, 95048.0, 89542.0, 93758.0, 94161.0, 90810.0, 93807.0, 93849.0, 97470.0, 97952.0],
                "50_10" => [170951.0, 174940.0, 175891.0, 169347.0, 176409.0, 180842.0, 170723.0, 178499.0, 182400.0, 177565.0],
                "50_25" => [430921.0, 430022.0, 428524.12, 423512.72, 436813.15, 425615.6, 430211.38, 423116.53, 431499.0, 434110.52],
                "100_5" => [185195.0, 182236.0, 177036.0, 189982.0, 188292.0, 178896.0, 188937.0, 196587.0, 192981.0, 189321.0],
                "100_10" => [350597.0, 357445.0, 358249.0, 356076.0, 351212.0, 349209.0, 358300.0, 344891.0, 357238.0, 360524.0],
                "100_25" => [863450.0, 849901.15, 872649.53, 861565.0, 862420.6, 863857.36, 858350.0, 866143.0, 881055.0, 879120.16]
    )
else
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
                "100_25" => [1.59665988e6, 1.60209204e6, 1.60952352e6, 1.57197976e6, 1.58084695e6, 1.59750359e6, 1.5840202e6, 1.59290364e6, 1.58795656e6, 1.6108116e6] 
)
end


all_size = Dict("5_5" => 3, "20_5" => 3, "50_5" => 3, "100_5" => 3, "5_10" =>5, "20_10" => 6, "50_10" => 5, "100_10" => 5,
                "5_25" => 12, "20_25" => 12, "50_25" => 12, "100_25" => 12
)

all_step = Dict("5_5" => 1, "20_5" => 1, "50_5" => 1, "100_5" => 1, "5_10" => 1, "20_10" => 2, "50_10" => 1, "100_10" => 2,
                "5_25" => 2, "20_25" => 2, "50_25" => 2, "100_25" => 2)


for p in list_p
    for t in list_t
        println("\n-------------------------------NOUVELLE TAILLE D'INSTANCES-------------------------")
        write(file, "\n-------------------------------NOUVELLE TAILLE D'INSTANCES-------------------------")

        version = 1
        println("p = ", p)
        println("t = ", t)
        write(file, "\np = "*string(p))
        write(file, "\nt = "*string(t))

        write(file1, "\n"*string(p))
        write(file1, "\n"*string(t))


        #println("\nEssai pour compilation")
        for version in 1:2
            if option_instance == "ABC"
                file_p = "../instances/instances_alpha0.8_ABC/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt"
            else
                file_p = "../instances/instances_alpha0.8/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt"
            end    
            instance = init.gen_instance(p,t, fp=file_p)
            instance["P"] = 1:p
            instance["T"] = 1:t
            instance["t"] = t
            instance["p"] = p 

            wSize = 3
            step = 1

            model = buildM(instance,"RF")

            rslt = RelaxAndFix(model, wSize, step, instance)
            
            ssy = rslt["sy"]
            ssz = rslt["sz"]
            mdl = buildM(instance,"FO")

            rslt_rf = FixAndOptimize(mdl, ssy, ssz, wSize, step, instance)
        end    


        instance_key = string(p)*"_"*string(t)
        milp_obj = all_milp_obj[instance_key]

        allgap = Dict()
        alltimes = Dict()
        nbr_instance = 10

        rfSize = all_size[instance_key]
        rfStep = all_step[instance_key]
        foSize = rfSize
        foStep = rfStep
        rfObjectifs = []
        foObjectifs = []
        rf_times = []
        fo_times = []
        rf_gap_value = []
        fo_gap_value = [] 

        write(file, "\nrfSize = "*string(rfSize))
        write(file, "\nrfStep = "*string(rfStep))
        write(file, "\nfoSize = "*string(foSize))
        write(file, "\nfoStep = "*string(foStep))

        write(file1, "\n"*string(rfSize))
        write(file1, "\n"*string(rfStep))
        write(file1, "\n"*string(foSize))
        write(file1, "\n"*string(foStep))

        println("rfSize = ", rfSize)
        println("rfStep = ", rfStep)
        println("foSize = ", foSize)
        println("foStep = ", foStep)
        list_instances = []
        for version in 1:nbr_instance
            #=
            println("\n\n--------------------INSTANCE ", version, "------------------------\n")
            write(file, "\n\n--------------------INSTANCE "*string(version)*"------------------------")
            =#
            push!(list_instances, instance_key*"_"*string(version))
            if option_instance == "ABC"
                file_path = "../instances/instances_alpha0.8_ABC/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt"
            else
                file_path = "../instances/instances_alpha0.8/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt"
            end    
            instance_dict = init.gen_instance(p,t, fp=file_path); 
            instance_dict["P"] = 1:p;
            instance_dict["T"] = 1:t;
            instance_dict["t"] = t
            instance_dict["p"] = p 
            alpha = instance_dict["alpha"]
            cmax = instance_dict["cmax"]
            mtn_cost = instance_dict["mtn_cost"]
            set_up_cost = instance_dict["set_up_cost"]
            #=
            println("RELAX AND FIX ")
            write(file, "\nRELAX AND FIX")
            =#
            rfmodel = buildM(instance_dict,"RF")
            
            begin_time = time()
            result_rf = RelaxAndFix(rfmodel, rfSize, rfStep, instance_dict)
            rf_timeElapsed = round(time() - begin_time, digits = 4)

            sx = result_rf["sx"]
            sI = result_rf["sI"]
            sy = result_rf["sy"]
            su = result_rf["su"]
            sz = result_rf["sz"]
            sc = result_rf["sc"]

            rf_obj = round(result_rf["obj"], digits = 2)
            #=
            println("Objectif = ", rf_obj)
            write(file, "\nObjectif = "*string(rf_obj))
            =#
            push!(rfObjectifs, rf_obj)
            push!(rf_times, rf_timeElapsed)
            #=
            println("FIX AND OPTIMIZE ")
            write(file, "\nFIX AND OPTIMIZE")
            =#
            fomodel = buildM(instance_dict,"FO")
            
            begin_time = time()
            result_fo = FixAndOptimize(fomodel, sy, sz, foSize, foStep, instance_dict)
            fo_timeElapsed = round(time() - begin_time, digits = 4)

            sx = result_fo["sx"]
            sI = result_fo["sI"]
            sy = result_fo["sy"]
            su = result_fo["su"]
            sz = result_fo["sz"]
            sc = result_fo["sc"]
            fo_obj = round(result_fo["obj"], digits  = 2)
            #=
            println("Objectif = ", fo_obj)
            write(file, "\nObjectif = "*string(fo_obj))
            println("Feasibility of solution : ", verify_solution(sx, sI, sy, sz, sc, instance_dict))
            write(file, "\nFeasibility of solution : "*string(verify_solution(sx, sI, sy, sz, sc, instance_dict)))
            =#
            push!(foObjectifs, fo_obj)
            push!(fo_times, fo_timeElapsed)     
            rf_temp = round((rf_obj-milp_obj[version])/milp_obj[version]*100, digits = 2)
            fo_temp = round((fo_obj-milp_obj[version])/milp_obj[version]*100, digits = 2)
            push!(rf_gap_value, rf_temp)
            push!(fo_gap_value, fo_temp)
            
        end 
        
        
        rf_obj_mean = round(mean(rfObjectifs), digits = 2)
        rfg_mean = round(mean(rf_gap_value),digits = 2)
        rft_mean = round(mean(rf_times), digits = 4)
        fo_obj_mean = round(mean(foObjectifs), digits = 2)
        fog_mean = round(mean(fo_gap_value),digits = 2)
        fot_mean = round(mean(fo_times), digits = 4)
        time_total = rft_mean + fot_mean
        
        write(file, "\n\n--------------------RESULTATS--------------------")
        write(file, "\nListe des instances = "*string(list_instances))
        write(file, "\nMoyenne des objectifs pour le relax-and-fix = "*string(rf_obj_mean))
        write(file, "\nMoyenne des gaps pour le relax-and-fix = "*string(rfg_mean))
        write(file, "\nMoyenne des temps pour le relax-and-fix = "*string(rft_mean))
        write(file, "\nLes objectifs avec RF :  "*string(rfObjectifs))
        write(file, "\n\n\nMoyenne des objectifs pour le fix-and-optimize = "*string(fo_obj_mean))
        write(file, "\nMoyenne des temps pour le fix-and-optimize = "*string(fot_mean))
        write(file, "\nMoyenne des gaps pour le fix-and-optimize = "*string(fog_mean))
        write(file, "\nLes objectifs avec FO :  "*string(foObjectifs))
        write(file, "\nTemps total = "*string(time_total))

        write(file1, "\n"*string(list_instances))
        write(file1, "\n"*string(rf_obj_mean))
        write(file1, "\n"*string(rfg_mean))
        write(file1, "\n"*string(rft_mean))
        write(file1, "\n"*string(rfObjectifs))
        write(file1, "\n"*string(fo_obj_mean))
        write(file1, "\n"*string(fot_mean))
        write(file1, "\n"*string(fog_mean))
        write(file1, "\n"*string(foObjectifs))
        write(file1, "\n"*string(time_total))

        println("\nListe des instances = "*string(list_instances))
        println("\nMoyenne des objectifs pour le relax-and-fix = ", rf_obj_mean)
        println("Moyenne des gaps pour le relax-and-fix = ", rfg_mean)
        println("Moyenne des temps pour le relax-and-fix = ", rft_mean)
        println("\nLes objectifs avec RF : ", rfObjectifs)
        println("\nMoyenne des objectifs pour le fix-and-optimize = ", fo_obj_mean)
        println("Moyenne des gaps pour le fix-and-optimize = ", fog_mean)
        println("Moyenne des temps pour le fix-and-optimize = ", fot_mean)
        println("\nLes objectifs avec FO : ", foObjectifs)
        #show(foObjectifs)
        println("\nTemps total = ",time_total)
    end
end