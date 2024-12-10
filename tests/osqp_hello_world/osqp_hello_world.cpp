#include <stdlib.h>
#include "osqp.h"

int main(int argc, char **argv) {
    /* Load problem data */
    OSQPFloat P_x[3] = {4.0, 1.0, 2.0, };
    OSQPInt P_nnz = 3;
    OSQPInt P_i[3] = {0, 0, 1, };
    OSQPInt P_p[3] = {0, 1, 3, };
    OSQPFloat q[2] = {1.0, 1.0, };
    OSQPFloat A_x[4] = {1.0, 1.0, 1.0, 1.0, };
    OSQPInt A_nnz = 4;
    OSQPInt A_i[4] = {0, 1, 0, 2, };
    OSQPInt A_p[3] = {0, 2, 4, };
    OSQPFloat l[3] = {1.0, 0.0, 0.0, };
    OSQPFloat u[3] = {1.0, 0.7, 0.7, };
    OSQPInt n = 2;
    OSQPInt m = 3;

    /* Exitflag */
    OSQPInt exitflag = 0;

    /* Solver, settings, matrices */
    OSQPSolver   *solver;
    OSQPSettings *settings;
    OSQPCscMatrix* P = malloc(sizeof(OSQPCscMatrix));
    OSQPCscMatrix* A = malloc(sizeof(OSQPCscMatrix));

    /* Populate matrices */
    csc_set_data(A, m, n, A_nnz, A_x, A_i, A_p);
    csc_set_data(P, n, n, P_nnz, P_x, P_i, P_p);

    /* Set default settings */
    settings = (OSQPSettings *)malloc(sizeof(OSQPSettings));
    if (settings) {
        osqp_set_default_settings(settings);
        settings->alpha = 1.0; /* Change alpha parameter */
    }

    /* Setup solver */
    exitflag = osqp_setup(&solver, P, q, A, l, u, m, n, settings);

    /* Solve problem */
    if (!exitflag) exitflag = osqp_solve(solver);

    /* Cleanup */
    osqp_cleanup(solver);
    if (A) free(A);
    if (P) free(P);
    if (settings) free(settings);

    return (int)exitflag;
};
