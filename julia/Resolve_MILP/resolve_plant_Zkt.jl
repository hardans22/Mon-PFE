using PyCall, Statistics, DataFrames, XLSX

include("model_plant.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "../")
init  = pyimport("__init__")

option_instance = ""

if option_instance == "ABC"
    path_file = "result_plant_Zkt_ABC.txt"
else
    path_file = "result_plant_Zkt.txt"
end 

file = open(path_file, "w") 


list_p = [5, 20]
list_t = [5, 10]
group_instances = []
means_obj = []
means_gap = []
means_time = []
means_nodes = []
means_bounds = []

list_instances = []
list_obj = []
list_gap = []
list_time = []
list_nodes = []
list_bounds = []

for p in list_p
    for t in list_t
        allobj = []
        alltime = []
        allgap = []
        allnodes = []
        allbounds = []
        println("\n-------------------------------NOUVELLE TAILLE D'INSTANCES-------------------------")
        write(file, "\n-------------------------------NOUVELLE TAILLE D'INSTANCES-------------------------")
        println("p = ", p)
        println("t = ", t)
        
        write(file, "\np = "*string(p))
        write(file, "\nt = "*string(t))

        instance = string(p)*"_"*string(t)
        push!(group_instances, instance)

        for version in 1:10
            push!(list_instances, instance*"_"*string(version))
            #println("\n----------------------------INSTANCE ", version, "------------------------------------\n")
            #write(file, "\n----------------------------INSTANCE "*string(version)*"------------------------------------\n")
            if option_instance == "ABC"
                file_path = "../instances/instances_alpha0.8_ABC/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
            else
                file_path = "../instances/instances_alpha0.8/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
            end
            instance_dict = init.gen_instance(p,t, fp=file_path); 
            instance_dict["P"] = 1:p;
            instance_dict["T"] = 1:t;
            instance_dict["t"] = t
            instance_dict["p"] = p
            alpha = instance_dict["alpha"]
            #println("alpha = ", alpha)
            #write(file, "\nalpha = "*string(alpha))

            result = model_mip_zkt(instance_dict)

            x = result["x"]

            z = result["z"]
            y = result["y"]
            obj = result["obj"]
            time = result["time"]
            gap = result["gap"]
            nodes = result["nbr_nodes"]
            dual_objs = result["dual_obj"]
            push!(allobj, round(obj, digits = 2))
            push!(alltime, round(time, digits = 4))
            push!(allgap,round(gap, digits = 4))
            push!(allnodes, nodes)
            push!(allbounds, round(dual_objs, digits = 2))
            z_prime = [floor(Int, z[t,t]) for t in 1:t]
            #=
            println("\nNombre de maintenance : ", sum(z_prime))
            write(file, "\nNombre de maintenance : "*string(z_prime))
            println("Plan de maintenance optimal : ")
            write(file, "\nPlan de maintenance optimal : "*string(z_prime))
            println(z_prime)
            =#
            nbr_setup = []
            for i in 1:p
                push!(nbr_setup, floor(Int,sum(y[i,:])))
            end
            #println("Nombre de setup par produit : ")
            #write(file, "\nNombre de setup par produit : ", string(nbr_setup))
            #println(nbr_setup)
        end
    
        append!(list_obj, allobj)
        append!(list_gap, allgap)
        append!(list_time, alltime)
        append!(list_nodes, allnodes)
        append!(list_bounds, allbounds)

        m_obj = round(mean(allobj), digits = 2)
        m_gap = round(mean(allgap), digits = 4)
        m_time = round(mean(alltime), digits = 4)
        m_nodes = round(mean(allnodes), digits = 4)
        m_bounds = round(mean(allbounds), digits = 4)

        push!(means_obj, m_obj)
        push!(means_gap, m_gap)
        push!(means_time, m_time)
        push!(means_nodes, m_nodes)
        push!(means_bounds, m_bounds)

        println("\nListe des objectifs de chaque instance: ", allobj)
        println("\nMoyenne des objectifs : ",m_obj)
        println("\n \nListe des gaps de chaque instance: ", allgap)
        println("\nMoyenne des gaps : ", m_gap)
        println("\nListe des objective_bound de chaque instance: ", allbounds)
        println("\nMoyenne des objective_bound : ",m_bounds)
        println("\n \nListe des nombres de noeuds explorés pour chaque instance: ", allnodes)
        println("\nMoyenne du nombre de noeuds explorés : ", m_nodes)
        println("\n\nListe des temps de résolution de chaque instance: ", alltime)
        println("\nMoyenne des temps : ", m_time)
        
        write(file, "\nListe des objectifs de chaque instance : "*string(allobj))
        write(file, "\nMoyenne des objectifs : "*string(m_obj))
        write(file, "\nListe des gaps de chaque instance : "*string(allgap))
        write(file, "\nMoyenne des gaps : "*string(m_gap))
        write(file, "\nListe des objective_bound de chaque instance: "*string(allbounds))
        write(file, "\nMoyenne des objective_bound : "*string(m_bounds))
        write(file, "\nListe des nombres de noeuds explorés pour chaque instance : "*string(allnodes))
        write(file, "\nMoyenne du nombre de noeuds explorés : "*string(m_nodes))
        write(file, "\nListe des temps de résolution de chaque instance : "*string(alltime))
        write(file, "\nMoyenne des temps : "*string(m_time))

    end
end
dataframe = DataFrames.DataFrame(Instances = group_instances, ZktObjectif = means_obj, ZktBounds = means_bounds, ZktGap = means_gap, ZktNodes = means_nodes, ZktTime = means_time)
if option_instance == "ABC"
    XLSX.writetable("result_plant_Zkt_ABC.xlsx", dataframe, overwrite=true)
else
    XLSX.writetable("result_plant_Zkt.xlsx", dataframe, overwrite=true)
end 

dataframe = DataFrames.DataFrame(Instances = list_instances, ZktObjectif = list_obj, ZktBounds = list_bounds, ZktGap = list_gap, ZktNodes = list_nodes, ZktTime = list_time)
if option_instance == "ABC"
    XLSX.writetable("all_instances_result_plant_Zkt_ABC.xlsx", dataframe, overwrite=true)
else
    XLSX.writetable("all_instances_result_plant_Zkt.xlsx", dataframe, overwrite=true)
end