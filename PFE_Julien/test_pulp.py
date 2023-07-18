# -*- encoding: utf-8 -*-

from __future__ import print_function

try:
    from pulp import LpProblem, LpMinimize, LpVariable

except ImportError:
    print('Module \'pulp\' non trouvé - Contacter un intervenant.')
    exit(1)



def test_pulp():

	print('=== Programme de test (ENAC) ===')

	print('Résolution d\'un PLNE basique... ', end='')

	try:
	    p = LpProblem('Programme de test', LpMinimize)

	    x1 = LpVariable('x_1', 0)
	    x2 = LpVariable('x_2', 0)

	    p += x1 + x2 <= 2
	    p += 4 * x1 + x2 <= 4
	    p += x1 - x2 <= 2
	    p += -x1 - 4 * x2 <= 4
	    p += -x1 - x2 <= -1
	    p += -x1 + x2 <= 2
	    p += 4 * x1 + x2 == 2

	    p += -3 * x1 - x2
	    p.solve()

	    print('Ok: x1 = {}, x2 = {}.'.format(x1.value(), x2.value()))
	except:
	    print('Échec.')

	print('=== Fin du programme ===')
