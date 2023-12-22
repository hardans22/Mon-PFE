using PyCall, Statistics

include("model.jl")

pushfirst!(PyVector(pyimport("sys")."path"), "")
init  = pyimport("__init__")


path_file = "result_milp_Zt.txt"
path_f = "result_milp_Zt_1.txt"

file = open(path_file, "w") 
file1 = open(path_f, "w") 


list_p = [5, 20]
list_t = [5, 10]

for p in list_p
    for t in list_t
        allobj = []
        alltime = []
        allgap = []

        println("\n-------------------------------NOUVELLE TAILLE D'INSTANCES-------------------------")
        write(file, "\n-------------------------------NOUVELLE TAILLE D'INSTANCES-------------------------")

        version = 1
        println("p = ", p)
        println("t = ", t)
        
        write(file, "\np = "*string(p))
        write(file, "\nt = "*string(t))

        write(file1, "\n"*string(p))
        write(file1, "\n"*string(t))


        for version in 1:10
            #println("\n----------------------------INSTANCE ", version, "------------------------------------\n")
            #write(file, "\n----------------------------INSTANCE "*string(version)*"------------------------------------\n")
            file_path = "instances/instances_alpha0.8/rd_instance" * string(p) * "_" * string(t) * "_" * string(version) *".txt";
            instance_dict = init.gen_instance(p,t, fp=file_path); 
            instance_dict["P"] = 1:p;
            instance_dict["T"] = 1:t;
            instance_dict["t"] = t
            instance_dict["p"] = p
            alpha = instance_dict["alpha"]
            #println("alpha = ", alpha)
            #write(file, "\nalpha = "*string(alpha))

            result = model_mip_zt(instance_dict)

            x = result["x"]
            I = result["I"]
            z = result["z"]
            y = result["y"]
            obj = result["obj"]
            time = result["time"]
            gap = result["gap"]
            push!(allobj, round(obj, digits = 2))
            push!(alltime, round(time, digits = 4))
            push!(allgap,round(gap, digits = 4))
            z_prime = [floor(Int, z[t]) for t in 1:t]
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
        m_obj = round(mean(allobj), digits = 2)
        m_gap = round(mean(allgap), digits = 4)
        m_time = round(mean(alltime), digits = 4)

        println("\nListe des objectifs de chaque instance: ", allobj)
        println("\nMoyenne des objectifs : ",m_obj)
        println("\n \nListe des gaps de chaque instance: ", allgap)
        println("\nMoyenne des gaps : ", m_gap)
        println("\n\nListe des temps de résolution de chaque instance: ", alltime)
        println("\nMoyenne des temps : ", m_time)
        
        write(file, "\nListe des objectifs de chaque instance : "*string(allobj))
        write(file, "\nMoyenne des objectifs : "*string(m_obj))
        write(file, "\nListe des gaps de chaque instance : "*string(allgap))
        write(file, "\nMoyenne des gaps : "*string(m_gap))
        write(file, "\nListe des temps de résolution de chaque instance : "*string(alltime))
        write(file, "\nMoyenne des temps : "*string(m_time))

        write(file1, "\n"*string(allobj))
        write(file1, "\n"*string(m_obj))
        write(file1, "\n"*string(allgap))
        write(file1, "\n"*string(m_gap))
        write(file1, "\n"*string(alltime))
        write(file1, "\n"*string(m_time))
    end
end
