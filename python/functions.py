def RMP(col: list):
    if col != 0:
        z.append(master.continuous_var(0.0, 1.0,name='z_'+str(len(z))))
        # On ajoute la variable dans toutes les contraintes concernées
        sct = col[0]
        Mc = col[1]
        contrainte4.left_expr += z[-1]
        for t in period_set:
            contraintes5[t].right_expr += sct[t]*z[-1]
            #print(contraintes5[t])
            
        
        #Ajout à la fonction objective
        master.obj += Mc*z[-1]
        master.minimize(master.obj)

        #print(master.export_as_lp_string())
        # Résolution
        master_sol = master.solve(log_output = False)
        objectives.append(master_sol.get_objective_value())
        master.print_solution()
        
        #Valeurs du dual
        pi = master.dual_values(contraintes5)
        pi.append(contrainte4.dual_value)
        print(pi)
        return(pi)
    else:
        master_sol = master.solve(log_output = True)
        objectives.append(master_sol.get_objective_value())
        master.print_solution()
        
        #Valeurs du dual
        pi = master.dual_values(contraintes5)
        pi.append(contrainte4.dual_value)
        print(pi)
        return(pi)
    
def SP_MIP(pricing, pi: list):
    cost1 = sum(mtn_cost[t]*zt[t] + pi[t]*ct[t] for t in period_set)
    pricing.obj = cost1 - pi[-1]
    pricing.minimize(pricing.obj)
    
    ct1 = pricing.add_constraints(ct[t] <= cmax for t in period_set)
    ct2 = pricing.add_constraints(ct[t] <= alpha*ct[t-1] + cmax*zt[t] for t in period_set)

    # Résolution
    pricing_sol = pricing.solve(log_output = False)
    Z_SP = pricing_sol.get_objective_value()
    pricing.print_solution()
    sct = pricing_sol.get_values(ct)
    szt = pricing_sol.get_values(zt)
    Mc = sum(mtn_cost[t]*szt[t]for t in period_set)
    col = [sct,Mc]
    if Z_SP >= -1E-10:
        Z_SP = 0
    if Z_SP >=0 :
        print("RMP optimal")
        return(0)
    else:
        print("nouvelle colonne : ",szt)
        print("Z_SP =" ,Z_SP)
        return(col)