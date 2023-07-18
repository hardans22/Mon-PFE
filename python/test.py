import numpy as np 
from docplex.mp.model import Model
import random as rd
import cplex

nbr = 10
rd.seed(21)
a = [rd.randint(1,20) for _ in range(nbr)]
b = [rd.randint(5,15) for _ in range(nbr)]
c = [rd.randint(10,60) for _ in range(nbr)]

mdl = Model()

x = mdl.continuous_var_list(nbr, name='x')
y = mdl.continuous_var_list(nbr, name='y')

ct1 = mdl.add_constraints(mdl.sum(a[i]*x[i] for i in range(nbr)) <= 23+j for j in range(5))
ct2 = mdl.add_constraint(mdl.sum(b[i]*y[i] for i in range(nbr)) <= 15)

mdl.obj = mdl.sum(c[i]*(x[i]+y[i]) for i in range(nbr))
mdl.maximize(mdl.obj)
print(mdl.get_cplex().variables.get_names())
print(mdl.export_as_lp_string())
mdl.solve(log_output = True)
obj_ex = mdl.get_objective_expr()
print(mdl.iter_constraints())

ct1[0].get_left_expr().remove_term(x[5])


obj_ex.remove_term(x[5])
#mdl.cplex.variables.delete(x[5].name)
print(mdl.obj)
print(mdl.get_cplex().variables.get_names())

mdl.print_solution()

print(mdl.export_as_lp_string())
mdl.solve(log_output = True)
#mdl.get_cplex().variables.delete(x[2].name)
mdl.print_solution()


"""
        print(master_variables['z'])   
        var_name = None
        for var_z in master_variables["z"]:
            print(var_z)
            var_basis = master.var_basis_statuses([var_z])
            print(var_basis)
            if var_basis[0].value == 1 and rd.random() < var_delete_proba:
                #master.get_objective_expr().remove_term(var_z)
                #master_constraints['ct4'].get_left_expr().remove_term(var_z) 
                #for ct in master_constraints['cts5']:
                #    ct.get_right_expr().remove_term(var_z)
                print(master.get_cplex().variables.get_names())
                var_index = master.get_cplex().variables.get_indices(var_z.name)
                print(var_z.__dict__, var_index, var_z.index, len(master.get_cplex().variables.get_names()), master.get_cplex().variables.__dict__)
                master.get_cplex().variables.delete(var_z.index)
                print(master.get_cplex().variables.get_names())
                print("variable ", var_z.name, "supprimée")

        

                print("Après suppression")
                print()
                print(master.export_as_lp_string())
                print()

                master_sol = master.solve()
                master_obj = master_sol.get_objective_value()
                print("RMP_obj = ",master_obj)
                #print(master.get_objective_expr())
                
        print(master_variables['z'])   
    
        if var_name != None:
            master.get_cplex().variables.delete(var_name)
        print(master_variables['z'])
        """
