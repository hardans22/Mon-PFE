from functions import gen_instance
import numpy as np
from models_MIP import *
from model_MIP_bis import * 
from pfe_column_generation import * 
import matplotlib.pyplot as plt
from verify import *
import time 

P = 60
T = 40

nb_iteration = 500
var_delete_proba = 0.3
epsilon = 1e-7
resolve_mdl_mip = False
sp_MIP_vs_PD = 1
one_method = 0
sp_method = "PD"
plot_figure = 1
verbose = False
pl = 1
file_path = "instances/rd_instance{}_{}.txt".format(P, T)
if __name__ == '__main__':

    instance_dict = gen_instance(P, T fp=file_path)
    """
    print("\n\n\n\n\n\n\n")
    print("Model initial")
    initial_model(instance_dict,pl)
    
    print("\n\n\n\n\n\n\n\n")
    print("Modele étendu")
    initial_model_bis(instance_dict,pl)
    """
    period_set = [i for i in range(T)]
    mtn_cost = instance_dict["mtn_cost"]
    if resolve_mdl_mip: 
        print("-----------------------------------Résolution du MILP--------------------------------")
        plan_mtn_opt, milp_obj = initial_model(instance_dict)
        print("PLan de maintenance optimal : ", plan_mtn_opt)
        #initial_model_modified(instance_dict)
    
    z_init = [1 for _ in period_set]
    capacities = [instance_dict['cmax'] for _ in period_set]
    Mc = sum(mtn_cost[t] for t in period_set)
    first_column = {"z" : z_init, "c" : capacities, "Mc" : Mc}
    
    if sp_MIP_vs_PD:
        print()
        print("---------------------------------------Columns Generation------------------------------------")
        sp_method = "MIP"
        print("------------------------------MIP-----------------------------")
        master, master_variables, master_constraints = create_column_generation_model(instance_dict)
        iteration_mip, master_objectives_mip, pricing_objectives_mip, best_bounds_mip, new_cols, master_sol_dict_mip, rmp_run_time_mip, sp_run_time_mip, cg_time_mip = run_column_generation(
            instance_dict, master, master_variables, master_constraints, first_column, nb_iteration, sp_method, epsilon, var_delete_proba, verbose)
        print("Temps d'exécution :", cg_time_mip, "secondes")
        
        sp_method = "PD"
        print()
        print()
        print("------------------------------DYNAMIC PROGRAMING-----------------------------")
        master, master_variables, master_constraints = create_column_generation_model(instance_dict)
        iteration_pd, master_objectives_pd, pricing_objectives_pd, best_bounds_pd, new_cols, master_sol_dict_pd, rmp_run_time_pd, sp_run_time_pd, cg_time_pd = run_column_generation(
            instance_dict, master, master_variables, master_constraints, first_column, nb_iteration, sp_method, epsilon, var_delete_proba, verbose)
        print("Temps d'exécution :", cg_time_pd, "secondes")
    if one_method:
        print()
        print("---------------------------------------Columns Generation------------------------------------")
        master, master_variables, master_constraints = create_column_generation_model(instance_dict)
        iteration, master_objectives, pricing_objectives, best_bounds, new_cols, master_sol_dict, rmp_run_time, sp_run_time, cg_time = run_column_generation(
            instance_dict, master, master_variables, master_constraints, first_column, nb_iteration, sp_method, epsilon, var_delete_proba, verbose)
        print("Temps d'exécution :", cg_time, "secondes")
        
        print("Valeur objective du master = ", master_sol_dict["obj"])
        if resolve_mdl_mip:
            print("\nGAP par rapport à la fonction objective du MILP ", round((milp_obj-master_sol_dict["obj"])/milp_obj * 100, 2), "%")

      
        z_opt = master_sol_dict["z"]
        y_opt = master_sol_dict["y"]
        """
        print("\nVecteur z optimal dans le master = ", z_opt)
        #print("\nVecteur y optimal dans le master = ", y_opt)
        print("\nListe des colonnes générée ")
        liste = []
        for i in range(len(new_cols)):
           print(new_cols[i], " ",z_opt[i])
           for x in new_cols[i]:
               if z_opt[i] != 0: 
                   liste.append(x)
        print()
        liste = np.unique(np.array(liste))
        print(liste)
        
        if resolve_mdl_mip and plan_mtn_opt in new_cols:
            print("-------------YES-------------")
        else: 
            print("---------------NO---------------")
        """
        if verbose:
            print('Temps moyen de résolution du RMP : ', np.mean(rmp_run_time))
            print('Temps moyen de résolution du SP : ', np.mean(sp_run_time))
    
    
    print()
    print()
    

    if plot_figure:
        if sp_MIP_vs_PD:
            fig, (ax1, ax2) = plt.subplots(2, 2, figsize=(15, 10))

            # Plot 1
            ax1[0].plot(range(iteration_mip+1), master_objectives_mip, 'b')
            ax1[0].plot(range(iteration_mip+1), best_bounds_mip, 'b')
            ax1[0].set_xlabel("Itérations")
            ax1[0].set_ylabel("Objective value")
            ax1[0].set_title("RMP convergence pour sp_MIP")
            ax1[0].legend(["MIP"])

            # PLot 2 
            ax1[1].plot(range(iteration_pd+1), master_objectives_pd, 'r')
            ax1[1].plot(range(iteration_pd+1), best_bounds_pd, 'r')
            ax1[1].set_xlabel("Itérations")
            ax1[1].set_ylabel("Objective value")
            ax1[1].set_title("RMP convergence pour sp_PD")
            ax1[1].legend(["PD"])

            # Plot 3
            ax2[0].plot(range(iteration_mip+1), rmp_run_time_mip, 'b')
            ax2[0].plot(range(iteration_pd+1), rmp_run_time_pd, 'r')
            ax2[0].set_xlabel("Itérations")
            ax2[0].set_ylabel("RMP run time")
            ax2[0].set_title('RMP run time evolution')
            ax2[0].legend(["MIP", "PD"])

            # Plot 4
            ax2[1].plot(range(iteration_mip+1), sp_run_time_mip, 'b')
            ax2[1].plot(range(iteration_pd+1), sp_run_time_pd, 'r')
            
            ax2[1].set_xlabel("Itérations")
            ax2[1].set_ylabel("Pricing run time")
            ax2[1].set_title('Pricing run time evolution')
            ax2[1].legend(["MIP", "PD"])
            ax2[1].set_yscale('log')
            
            # Afficher la figure
            plt.show()

        if one_method:
            fig, (ax1, ax2) = plt.subplots(2, 2, figsize=(15, 10))

            # Plot 1
            ax1[0].plot(range(iteration+1), master_objectives)
            ax1[0].plot(range(iteration+1), best_bounds, 'b')
            ax1[0].set_xlabel("Itérations")
            ax1[0].set_ylabel("Objective value")
            ax1[0].set_title("RMP convergence")
            ax1[0].legend()

            # PLot 2 
            ax1[1].plot(range(iteration+1), pricing_objectives)
            ax1[1].set_xlabel("Itérations")
            ax1[1].set_ylabel("Objective value")
            ax1[1].set_title("Pricing convergence")
            ax1[1].legend()

            # Plot 3
            ax2[0].plot(range(iteration+1), rmp_run_time)
            ax2[0].set_xlabel("Itérations")
            ax2[0].set_ylabel("RMP run time")
            ax2[0].set_title('RMP run time evolution')
            ax2[0].legend()

            # Plot 4
            ax2[1].plot(range(iteration+1), sp_run_time)
            ax2[1].set_xlabel("Itérations")
            ax2[1].set_ylabel("Pricing run time")
            ax2[1].set_title('Pricing run time evolution')
            ax2[1].legend()

            # Afficher la figure
            plt.show()

    