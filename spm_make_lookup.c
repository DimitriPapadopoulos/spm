#ifndef lint
static char sccsid[]="%W% (c) John Ashburner %E%";
#endif

#include <math.h>
#define PI 3.14159265358979

/* Generate a lookup table for Lagrange interpolation
   See page 98 of `Fundamentals of Digital Image Processing'
*/
void make_lookup_poly(coord,q,dim, d1, table,ptpend)
double coord;
double table[], **ptpend;
int q, dim, *d1;
{
	register int d2, fcoord;
	register int k, m;
	register double *tp, *tpend, *p, num, x;

	static int oq = 0, k0, k1;
	static double denom[256];

	if (q != oq)
	{
		double v;
		oq = q;
		if (q%2)
		{
			/* Odd number */
			k0 = -(q-1)/2;
			k1 = (q-1)/2;
		}
		else
		{
			/* Even number */
			k0 = -(q-2)/2;
			k1 = q/2;
		}

		/* generate \prod{k-m} which is the same for all
		   resamplings */
		for(k=k0, p=denom; k<=k1; k++, p++)
		{
			/* two seperate inner loops - so m!=k */
			v = 1.0;
			for (m=k0; m<k; m++)
				v = v*(k-m);
			for (m=k+1; m<=k1; m++)
				v = v*(k-m);
			*p = v;
		}
	}

	if (fabs(coord-rint(coord))<0.00001)
	{
		/* Close enough to use nearest neighbour */
		*d1=rint(coord);
		if (*d1<1 || *d1>dim) /* Pixel location outside image */
			*ptpend = table-1;
		else
		{
			table[0]=1.0;
			*ptpend = table;
		}
	}
	else
	{
		fcoord = floor(q%2 ? coord+0.5 : coord);
		*d1 = fcoord+k0;
		if (*d1>=1)
		{
			p = denom;
			k = k0;
		}
		else
		{
			p = denom+1-(*d1);
			k = k0+1-(*d1);
			*d1=1;
		}

		d2 = fcoord+k1;
		if (d2>dim) d2 = dim;

		*ptpend = tpend = table+(d2 - *d1);
		tp = table;

		if (tp<tpend)
		{
			x = coord-fcoord;

			num = 1.0;
			for (m=k0; m<k; m++)
				num = num*(x-m);
			for (m=k+1; m<=k1; m++)
				num = num*(x-m);
			*(tp++) = num/(double)(*(p++));

			while (tp <= tpend)
			{
				k++;
				num = num*(x-k+1)/(x-k);
				*(tp++) = num/(double)(*(p++));
			}
		}
	}
}

/* Generate a lookup table for Lagrange interpolation
   and also one for the derivatives (produced numerically)
   See page 98 of `Fundamentals of Digital Image Processing'
*/
void make_lookup_poly_grad(coord,q,dim, d1, table,dtable,ptpend)
double coord;
double table[], dtable[], **ptpend;
int q, dim, *d1;
{
	register int d2, fcoord;
	register int k, m;
	register double *tp, *dtp, *tpend, *p, num, dnum, x, dx;

	static int oq = 0, k0, k1;
	static double denom[256];

	if (q != oq)
	{
		double v;
		oq = q;
		if (q%2)
		{
			/* Odd number */
			k0 = -(q-1)/2;
			k1 = (q-1)/2;
		}
		else
		{
			/* Even number */
			k0 = -(q-2)/2;
			k1 = q/2;
		}

		/* generate \prod{k-m} which is the same for all
		   resamplings */
		for(k=k0, p=denom; k<=k1; k++, p++)
		{
			/* two seperate inner loops - so m!=k */
			v = 1.0;
			for (m=k0; m<k; m++)
				v = v*(k-m);
			for (m=k+1; m<=k1; m++)
				v = v*(k-m);
			*p = v;
		}
	}

	fcoord = floor(q%2 ? coord+0.5 : coord);
	*d1 = fcoord+k0;
	if (*d1>=1)
	{
		p = denom;
		k = k0;
	}
	else
	{
		p = denom+1-(*d1);
		k = k0+1-(*d1);
		*d1=1;
	}

	d2 = fcoord+k1;
	if (d2>dim) d2 = dim;

	*ptpend = tpend = table+(d2 - *d1);
	tp  =  table;
	dtp = dtable;

	if (tp<tpend)
	{
		x  = coord-fcoord;
		dx = x + 0.00001;

		if (fabs(x)>0.0001)
		{
			/* do it the faster way */
			num  = 1.0;
			dnum = 1.0;

			for (m=k0; m<k; m++)
			{
				num  =  num*( x-m);
				dnum = dnum*(dx-m);
			}
			for (m=k+1; m<=k1; m++)
			{
				num  =  num*( x-m);
				dnum = dnum*(dx-m);
			}
			*( tp++) = num/(double)(*p);
			*(dtp++) = (dnum-num)/0.00001/(double)(*(p++));

			while (tp <= tpend)
			{
				k++;
				num  =  num*( x-k+1)/( x-k);
				dnum = dnum*(dx-k+1)/(dx-k);
				*( tp++) = num/(double)(*p);
				*(dtp++) = (dnum-num)/0.00001/(double)(*(p++));
			}
		}
		else
		{
			/* do it the slow way */
			while(tp <= tpend)
			{
				num  = 1.0;
				dnum = 1.0;
				for (m=k0; m<k; m++)
				{
					num  = num *( x-m);
					dnum = dnum*(dx-m);
				}
				for (m=k+1; m<=k1; m++)
				{
					num  = num *( x-m);
					dnum = dnum*(dx-m);
				}
				*( tp++) = num/(double)(*p);
				*(dtp++) = (dnum-num)/0.00001/(double)(*(p++));
				k++;
			}
		}
	}
}

/* Generate a sinc lookup table with a Hanning filter envelope
   The function now integrates to unity. */
void make_lookup_sinc(coord,q,dim, d1, table,ptpend)
double coord;
double table[], **ptpend;
int q, dim, *d1;
{
	register int d2, d, fcoord;
	register double *tp, *tpend, dtmp, sm;
	static int oq = 0, k0, k1;

	if (fabs(coord-rint(coord))<0.00001)
	{
		/* Close enough to use nearest neighbour */
		*d1=rint(coord);
		if (*d1<1 || *d1>dim) /* Pixel location outside image */
			*ptpend = table-1;
		else
		{
			table[0]=1.0;
			*ptpend = table;
		}
	}
	else
	{

		if (q != oq)
		{
			oq = q;
			if (q%2)
			{
				/* Odd number */
				k0 = -(q-1)/2;
				k1 = (q-1)/2;
			}
			else
			{
				/* Even number */
				k0 = -(q-2)/2;
				k1 = q/2;
			}
		}
		fcoord = floor(q%2 ? coord+0.5 : coord);
		*d1 = fcoord+k0;
		if (*d1<1) *d1=1;
		d2 = fcoord+k1;
		if (d2>dim) d2 = dim;

		*ptpend = tpend = table+(d2 - *d1);
		d = *d1, tp = table;
		sm = 0;
		while (tp <= tpend)
		{
			dtmp = PI*(coord-(d++));
			sm += (*(tp++) = sin(dtmp)/dtmp* 0.5*(1.0 + cos(2*dtmp/q)));
		}
		tp = table;
		while (tp <= tpend)
			*(tp++) /= sm;
	}
}

/* Generate a sinc lookup table with a Hanning filter envelope + a lookup of the
   derivatives.
   The function now integrates to unity. */
void make_lookup_sinc_grad(coord,q,dim, d1, table,dtable,ptpend)
double coord;
double table[], dtable[], **ptpend;
int q, dim, *d1;
{
	register int d2, d, fcoord;
	register double *tp, *dtp, *tpend, dtmp0, dtmp1, sdtmp,cdtmp, sm, sm1;
	static int oq = 0, k0, k1;

	if (q != oq)
	{
		oq = q;
		if (q%2)
		{
			/* Odd number */
			k0 = -(q-1)/2;
			k1 = (q-1)/2;
		}
		else
		{
			/* Even number */
			k0 = -(q-2)/2;
			k1 = q/2;
		}
	}
	fcoord = floor(q%2 ? coord+0.5 : coord);
	*d1 = fcoord+k0;
	if (*d1<1) *d1=1;
	d2 = fcoord+k1;
	if (d2>dim) d2 = dim;

	*ptpend = tpend = table+(d2 - *d1);
	d = *d1, tp = table, dtp = dtable;
	sm1 = 0, sm = 0;
	while (tp <= tpend)
	{
		dtmp0 = coord-d;
		if (fabs(dtmp0)>1e-12)
		{
			dtmp1 = PI*dtmp0;
			sdtmp = sin(dtmp1);
			cdtmp = cos(2*dtmp1/q);
			sm += (*( tp++) = sdtmp/dtmp1* 0.5*(1.0 + cdtmp));
		}
		else
		{
			*( tp++) = 1.0;
			sm += 1.0;
		}
		dtmp0 = coord-(d++)+0.000001;
		if (fabs(dtmp0)>1e-12)
		{
			dtmp1 = PI*dtmp0;
			sdtmp = sin(dtmp1);
			cdtmp = cos(2*dtmp1/q);
			sm1 += (*( dtp++) = sdtmp/dtmp1* 0.5*(1.0 + cdtmp));
		}
		else
		{
			*(dtp++) = 1.0;
			sm1 += 1.0;
		}
	}
	tp = table, dtp = dtable;
	while (tp <= tpend)
	{
		*tp /= sm;
		*dtp = (*dtp/sm1 - *tp)/0.000001;
		tp++;
		dtp++;
	}

	/* This is not used anymore, since it would take too long to work out the
	   derivatives properly when the function is normalized to sum to unity
	   - however, I have chosen to keep it for historical reasons.
	while (tp <= tpend)
	{
		dtmp0 = coord-(d++);
		if (fabs(dtmp0)>1e-12)
		{
			dtmp1 = PI*dtmp0;
			sdtmp = sin(dtmp1);
			cdtmp = cos(2*dtmp1/q);
			*( tp++) = sdtmp/dtmp1* 0.5*(1.0 + cdtmp);
			*(dtp++) = (dtmp0*q/2.0*PI*cos(dtmp1)*(1.0+cdtmp)
				- sdtmp*(q/2.0+q/2.0*cdtmp+sin(2*dtmp1/q)*dtmp0*PI))
				/ (dtmp0*dtmp0*q*PI);
		}
		else
		{
			*( tp++) = 1.0;
			*(dtp++) = 0.0;
		}
	}
	*/
}

short getshort(x)
short x;
{
	char *p1, *p2; short y;
	p1 = (char *)(&x); p2 = (char *)(&y);
	p2[1] = p1[0]; p2[0] = p1[1];
	return(y);
}

int getint(x)
int x;
{
	char *p1, *p2; int y;
	p1 = (char *)(&x); p2 = (char *)(&y);
	p2[3] = p1[0]; p2[2] = p1[1];
	p2[1] = p1[2]; p2[0] = p1[3];
	return(y);
}

float getfloat(x)
float x;
{
	char *p1, *p2; float y;
	p1 = (char *)(&x); p2 = (char *)(&y);
	p2[3] = p1[0]; p2[2] = p1[1];
	p2[1] = p1[2]; p2[0] = p1[3];
	return(y);
}

double getdouble(x)
double x;
{
	char *p1, *p2; double y;
	p1 = (char *)(&x); p2 = (char *)(&y);
	p2[7] = p1[0]; p2[6] = p1[1];
	p2[5] = p1[2]; p2[4] = p1[3];
	p2[3] = p1[4]; p2[2] = p1[5];
	p2[1] = p1[6]; p2[0] = p1[7];
	return(y);
}
