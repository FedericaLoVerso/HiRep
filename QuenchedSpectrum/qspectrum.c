/***************************************************************************\
* Copyright (c) 2008, Claudio Pica                                          *   
* All rights reserved.                                                      * 
\***************************************************************************/


/*******************************************************************************
*
* Computation of quenched quark propagator
*
*******************************************************************************/

#define MAIN_PROGRAM

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "io.h"
#include "random.h"
#include "error.h"
#include "geometry.h"
#include "memory.h"
#include "statistics.h"
#include "update.h"
#include "global.h"
#include "observables.h"
#include "suN.h"
#include "suN_types.h"
#include "dirac.h"
#include "linear_algebra.h"
#include "inverters.h"
#include "representation.h"
#include "utils.h"
#include "logger.h"

int nhb,nor,nit,nth,nms,level,seed;
float beta;

float mass;

void read_cmdline(int argc, char*argv[])
{
	int i, ai=0, ao=0;
	FILE *in=NULL, *out=NULL;
	for (i=1;i<argc;i++){
		if (strcmp(argv[i],"-i")==0)
			ai=i+1;
		else if (strcmp(argv[i],"-o")==0)
			ao=i+1;
	}

	if (ao!=0)
		out=freopen(argv[ao],"w",stdout);
	else
		out=stdout;

	error(ai==0,1,"suN.c",
			"Syntax: suN -i <input file> [-o <output file>]");

	in=freopen(argv[ai],"r",stdin);
	error(in==NULL,1,"run1.c","Cannot open input file");

	scanf("beta %f nhb %d nor %d nit %d nth %d nms %d level %d seed %d",
			&beta,&nhb,&nor,&nit,&nth,&nms,&level,&seed);
	fclose(in);

}

int main(int argc,char *argv[])
{
	int i,n;

	char propname[256];
	FILE *propfile;
	double *m;

	double kappa[]={0.156,0.1575,0.159,0.160,0.161};
	int nm=sizeof(kappa)/sizeof(float);
	m = malloc(sizeof(kappa));
	for (i=0; i<nm; ++i)
	{
		m[i] = 0.5/kappa[i] - 4.0;
	}

	read_cmdline(argc, argv); 

	logger_setlevel(0,10000);
	/* uncomment the following if redirection of inverter output is desired */
	/* logger_map("INVERTER","inverter.out"); */

	lprintf("MAIN",0,"Gauge group: SU(%d)\n",NG);
	lprintf("MAIN",0,"Fermion representation: " REPR_NAME " [dim=%d]\n",NF);
	lprintf("MAIN",0,"The lattice size is %dx%dx%dx%d\n",T,X,Y,Z);
	lprintf("MAIN",0,"beta = %2.4f\n",beta);
	lprintf("MAIN",0,"nth  = %d\tNumber of thermalization cycles\n",nth);
	lprintf("MAIN",0,"nms  = %d\tNumber of measure cycles\n",nms);
	lprintf("MAIN",0,"nit  = %d\tNumber of hb-or iterations per cycle\n",nit);
	lprintf("MAIN",0,"nhb  = %d\tNumber of heatbaths per iteration\n",nhb);   
	lprintf("MAIN",0,"nor  = %d\tNumber or overrelaxations per iteration\n",nor);
	lprintf("MAIN",0,"ranlux: level = %d, seed = %d\n",level,seed); 
	lprintf("MAIN",0,"Computing quark prop for %d masses:\n",nm);
	for(i=0;i<nm;++i)
		lprintf("MAIN",0,"m[%d] = %1.8e => k[%d] = %1.8e\n",i,m[i],i,kappa[i]);

	rlxd_init(level,seed);

	geometry_eo_lexi();
	/*geometry_blocked();*/
	test_geometry();

	u_gauge=alloc_gfield();
#ifndef REPR_FUNDAMENTAL
	u_gauge_f=alloc_gfield_f();
#endif

	sprintf(propname,"quark_prop_qmr_%3.5f_%d_%d_%d_%d",beta,T,X,Y,Z);
	error((propfile = fopen(propname, "wb"))==NULL,1,"Main",
			"Failed to open propagator file for writing");
	fwrite(&nm,(size_t) sizeof(int),1,propfile);
	for(i=0;i<nm;++i)
		fwrite(m+i,(size_t) sizeof(*m),1,propfile);

	/* Termalizzazione */
	/*
	for (i=0;i<nth;++i) {
		update(beta,nhb,nor);
		if ((i%10)==0)
			lprintf("MAIN",0,"%d",i);
		else
			lprintf("MAIN",0,".");
		fflush(stdout);
	}
	if(i) lprintf("MAIN",0,"%d\nThemalization done.\n",i);
	*/
	/* or read configuration from file */
	read_gauge_field("confname");
	assign_u2ud();

	represent_gauge_field();

	/* Misure */
	for (i=0;i<nms;++i){ /* nms misure */
		lprintf("MAIN",0,"conf #%d <p> = %1.6f\n",i,avr_plaquette());
		quark_propagator_QMR_eo(propfile,0,nm,m,1.e-9);
		lprintf("MAIN",0,"MVM for last propagator: %ld\n",getMVM());

		for (n=0;n<nit;n++) /* nit updates */
			update(beta,nhb,nor);
		represent_gauge_field();

   write_gauge_field("confname.loc"); 

	}

	fclose(propfile);


	free_field(u_gauge);
#ifndef REPR_FUNDAMENTAL
	free_field(u_gauge_f);
#endif

	return 0;
}
