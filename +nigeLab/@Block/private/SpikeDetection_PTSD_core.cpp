/*=================================================================
 *
 * SpikeDetection_PTSD.C	.MEX file for PTSD spike detection core
 *
 * The calling syntax is:
 *
 *		[spkValues, spkTimeStamps] = SpikeDetection_PTSD_core(data, thresh, peakDuration, refrTime)
 *
 *      spkValues:      array of spike values as difference of peak amplitude
 *      spkTimeStamps:  array of spike timestamps
 *      
 *      data:           raw data to analyze
 *      thresh:         theshold used to identify spikes
 *      peakDuration:   maximum duration of peaks in number of frames used while scanning for spikes
 *      refrTime:       refractory time, i.e. minimum distance between two consecutive spikes
 *
 * Created on 11/02/2009 by Mauro Gandolfo
 * Modified on 02/03/2017 by Max Murphy
 *=================================================================*/

#include <math.h>
#include "mex.h"

/* Input Arguments */

#define	DATA	prhs[0]
#define	THRESH	prhs[1]
#define	PLP	    prhs[2]
#define	RP	    prhs[3]
#define	ALIGN_FLAG prhs[4]


/* Output Arguments */

#define	SPK_VALUES	    plhs[0]
#define	SPK_TIMESTAMPS	plhs[1]

#if !defined(MAX)
#define	MAX(A, B)	((A) > (B) ? (A) : (B))
#endif

#if !defined(MIN)
#define	MIN(A, B)	((A) < (B) ? (A) : (B))
#endif

#if !defined(ABS)
#define	ABS(A)	((A) > (0) ? (A) : (-A))
#endif

/* Constants and Signatures */

static int OVERLAP = 5;

static void SpikeDetection_PTSD_CR(
		   double	spkValues[],
           double   spkTimeStamps[],
		   double	data[],
           int      nFrames,
 		   double	thresh,
           int      peakDuration,
           int      refrTime,
           int      alignmentFlag
		   );

static void SpikeDetection_PTSD_Kelly(
		   double	spkValues[],
           double   spkTimeStamps[],
		   double	data[],
           int      nFrames,
 		   double	thresh,
           int      peakDuration,
           int      refrTime,
           int      alignmentFlag
		   );


///////////////////////////////////////////////////////////////////////////
/* MEX Gateway Routine */
///////////////////////////////////////////////////////////////////////////

void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray *prhs[] )
     
{ 
    /* Pointers to output and input arrays */
    double *spkValues, *spkTimeStamps;
    double *data;
    double thresh;
    int    nFrames;
    int    peakDuration, refrTime, alignFlag;
    
    mwSize m,n; 
    
    /* Check for proper number of arguments */    
    if (nrhs != 5) 
    { 
        mexErrMsgTxt("Five input arguments required."); 
    } 
    else if (nlhs != 2) 
    {
        mexErrMsgTxt("Two output arguments required."); 
    } 
    
    /* Check the dimensions of DATA (has to be a 1 by n matrix) */    
    m = mxGetM(DATA); 
    n = mxGetN(DATA);
    if (!mxIsDouble(DATA) || mxIsComplex(DATA) || (MIN(m,n) != 1)) 
    { 
        mexErrMsgTxt("DATA has to be a 1xN double array."); 
    } 
    
//    printf("%d, %d, %4.2f, %4.2f\n",ABS(1 - -5),ABS( (-1 - 4) ),ABS(1.0 - -5.0),ABS(-1.0 - 5.0));
    
    /* Create matrices for the return argument */ 
    SPK_VALUES = mxCreateDoubleMatrix(m, n, mxREAL);
    SPK_TIMESTAMPS = mxCreateDoubleMatrix(m, n, mxREAL);
    
    /* Assign pointers to the various parameters */ 
    spkValues = mxGetPr(SPK_VALUES);
    spkTimeStamps = mxGetPr(SPK_TIMESTAMPS);
    
    data = mxGetPr(DATA);
    nFrames = MAX(m,n);
    thresh = *mxGetPr(THRESH);
    peakDuration = (int)*mxGetPr(PLP);
    refrTime = (int)*mxGetPr(RP);
    alignFlag = (int)*mxGetPr(ALIGN_FLAG);
        
    /* Compute */
   SpikeDetection_PTSD_CR(spkValues, spkTimeStamps, data, nFrames, thresh, peakDuration, refrTime, alignFlag); 
//    SpikeDetection_PTSD_Kelly(spkValues, spkTimeStamps, data, nFrames, thresh, peakDuration, refrTime, alignFlag); 
    return;
}

///////////////////////////////////////////////////////////////////////////
/* MEX Computational Routine */
///////////////////////////////////////////////////////////////////////////

static void SpikeDetection_PTSD_CR(
		   double	spkValues[],
           double   spkTimeStamps[],
		   double	data[],
           int      nFrames,
 		   double	thresh,
           int      peakDuration,
           int      refrTime,
           int      alignmentFlag
		   )
{
    int newIndex = 1;
    int indexPeak = 1;
    double interval;
    int sTimePeak, eTimePeak;
    double sValuePeak, eValuePeak;
    
    long index, i;
    
    // cycle for each data value
    for (index = 2; index < nFrames; index++)
    {
        if (index < newIndex)
        {
            continue; // jump to the new position for scanning data
        }

        // if there is a peak, i.e. a relative max (or min)
        if ((ABS(data[index]) > ABS(data[index-1])) && (ABS(data[index]) >= ABS(data[index+1])))
        {
            sTimePeak  = index;       // collect the start peak time
            sValuePeak = data[index]; // collect the start peak value
            
            //control on the end of the array
            if ((index + peakDuration) > nFrames)
            {
                interval = nFrames - index;
            } 
            else
            {
                interval = peakDuration;
            }
            
            // If start peak value is positive, search for a minimum 
            // within the interval of possible peak duration
            if (sValuePeak > 0)
            {
                // Initialize value and time for the ending peak
                eTimePeak = index + 1;
                eValuePeak = sValuePeak;
                // Find the minimum within the interval
                for (i = (index + 1); i <= (index + interval); i++)
                {
                    if (data[i] < eValuePeak)
                    {
                        eTimePeak = i;
                        eValuePeak = data[i];
                    }
                }
                // Maximaze finding a new max inside the interval if there is
                for (i = (index + 1); i < eTimePeak; i++)
                {
                    if (data[i] > sValuePeak)
                    {
                        sTimePeak = i;
                        sValuePeak = data[i];
                    }
                }
                // When the min is found at the end of the interval check if signal continues to decrease
                if ((eTimePeak == (index + interval)) && ((index + interval + OVERLAP) < nFrames))
                {
                    for (i = (eTimePeak + 1); i <= (index + interval + OVERLAP); i++)
                    {
                        if (data[i] < eValuePeak)
                        {
                            eTimePeak = i;
                            eValuePeak = data[i];
                        }
                    }
                }
            }
            // if instead it is negative, search for a maximum
            else 
            {
                // Initialize value and time for the ending peak
                eTimePeak = index + 1;
                eValuePeak = sValuePeak;
                // Find the maximum within the interval
                for (i = (index + 1); i <= (index + interval); i++)
                {
                    if (data[i] > eValuePeak)
                    {
                        eTimePeak = i;
                        eValuePeak = data[i];
                    }
                }
                // Maximaze finding a new min inside the interval if there is
                for (i = (index + 1); i < eTimePeak; i++)
                {
                    if (data[i] < sValuePeak)
                    {
                        sTimePeak = i;
                        sValuePeak = data[i];
                    }
                }
                // When the max is found at the end of the interval check if signal continues to raise
                if ((eTimePeak == (index + interval)) && ((index + interval + OVERLAP) < nFrames))
                {
                    for (i = (eTimePeak + 1); i <= (index + interval + OVERLAP); i++)
                    {
                        if (data[i] > eValuePeak)
                        {
                            eTimePeak = i;
                            eValuePeak = data[i];
                        }
                    }
                }
            }
            
            // The difference overtake the threshold and a spike is found
            if (ABS( (sValuePeak - eValuePeak) ) >= thresh ) // necessary to put parentheses for C syntax
            {
//                 printf("%d (%2.1f-%2.1f), ",index,sValuePeak,eValuePeak);
                spkValues[indexPeak] = ABS( (sValuePeak - eValuePeak) ); // value is assumed to be the difference
                if (alignmentFlag == 0){
                    // With the following code the timestamp is assigned to the higher peak
                    ////////////////////////////////////////////////////////////////////////////
                    if (ABS(sValuePeak) > ABS(eValuePeak))
                    {
                        spkTimeStamps[indexPeak] = sTimePeak;
                    }
                    else
                    {
                        spkTimeStamps[indexPeak] = eTimePeak;
                    }
                }
                else {
					////////////////////////////////////////////////////////////////////////////
					// UPDATE 02/03/2017 MM - Check to make sure that the positive peak is not 
					//  					  so much higher that it should be aligned instead.
                    ////////////////////////////////////////////////////////////////////////////

                    if ( (sValuePeak < eValuePeak ) && ( abs(sValuePeak) > ( 0.5 * abs(eValuePeak) ) ) )
                    {
                        spkTimeStamps[indexPeak] = sTimePeak;
                    }
                    else
                    {
						if ( (sValuePeak < eValuePeak) && (abs(sValuePeak) < ( 0.5 * abs(sValuePeak) ) ) ) 
                        {
							spkTimeStamps[indexPeak] = eTimePeak;
						}
						else
						{
							if ( (eValueValuePeak < sValuePeak) && ( abs(eValuePeak) > (0.5 * abs(sValuePeak) ) ) )
							{
								spkTimeStamps[indexPeak] = eTimePeak;
							}
								else
								{
									spkTimeStamps[indexPeak] = sTimePeak;
								}
							}
						}	
                    }
                }
                /////////////////
				// END UPDATE //
				////////////////
                // Set the newIndex
                if (((spkTimeStamps[indexPeak] + refrTime) > eTimePeak) && ((spkTimeStamps[indexPeak] + refrTime) < nFrames))
                {
                    newIndex = spkTimeStamps[indexPeak] + refrTime;
                }
                else
                {
                    newIndex = eTimePeak + 1;
                }
                
                // increase index to fill spikes arrays
                indexPeak = indexPeak + 1;
            }
        }
    }
        
    return;
}



// Kelly Updates 7.19.15

///////////////////////////////////////////////////////////////////////////
/* MEX Computational Routine */
///////////////////////////////////////////////////////////////////////////

static void SpikeDetection_PTSD_Kelly(
	double	spkValues[],
	double   spkTimeStamps[],
	double	data[],
	int      nFrames,
	double	thresh,
	int      peakDuration,
	int      refrTime,
	int      alignmentFlag
	)
{
	int newIndex = 1;
	int indexPeak = 1;
	double interval;
	int sTimePeak, eTimePeak;
	double sValuePeak, eValuePeak;

	long index, i;

	// cycle for each data value
	for (index = 1; index < nFrames; index++) // REMEMBER HERE index is changed since c++ starts at 0 not 1 
	{
		if (index < newIndex)
		{
			continue; // jump to the new position for scanning data
		}

		// if there is a peak, i.e. a relative max (or min)
		if ((ABS(data[index]) > ABS(data[index - 1])) && (ABS(data[index]) >= ABS(data[index + 1])))
		{
			sTimePeak = index;       // collect the start peak time
			sValuePeak = data[index]; // collect the start peak value

			//control on the end of the array
			
			//UPDATE 1 on 7.19.2015 : Code optimization
			
/*			if ((index + peakDuration) > nFrames)
			{
				interval = nFrames - index;
			}
			else
			{
				interval = peakDuration;
			}
*/
			interval = MIN(peakDuration, nFrames - index);

			//END UPDATE 1 on 7.19.2015

			// If start peak value is positive, search for a minimum 
			// within the interval of possible peak duration
			if (sValuePeak > 0)
			{
				// Initialize value and time for the ending peak
				eTimePeak = index + 1;
				eValuePeak = sValuePeak;
				// Find the minimum within the interval
				for (i = (index + 1); i <= (index + interval); i++)
				{
					if (data[i] < eValuePeak)
					{
						eTimePeak = i;
						eValuePeak = data[i];
					}
				}
				// Maximaze finding a new max inside the interval if there is
				//UPDATE 2 on 7.19.2015 :Searches for replacement of original positive peak 
				// within entire interval and not only before the second peak found 
				// interval length previously update st the for loop stop at end of nFrames

/*				for (i = (index + 1); i < eTimePeak; i++)
				{
					if (data[i] > sValuePeak)
					{
						sTimePeak = i;
						sValuePeak = data[i];
					}
				}
*/
				for (i = (index + 1); i < index + interval; i++)
				{
					if (data[i] > sValuePeak)
					{
						sTimePeak = i;
						sValuePeak = data[i];
					}
				}

				//Additional change needs to compare which peak comes first 
				// thus updating sValuePeak and eValuePeak if need be

				if (eTimePeak < sTimePeak)
				{
					int temp = sTimePeak;
					sTimePeak = eTimePeak;
					eTimePeak = temp;

					sValuePeak = data[sTimePeak];
					eValuePeak = data[eTimePeak];

				}
				
				//END UPDATE 2 on 7.19.2015

				// When the min is found at the end of the interval check if signal continues to decrease
				if ((eTimePeak == (index + interval)) && ((index + interval + OVERLAP) < nFrames))
				{
					for (i = (eTimePeak + 1); i <= (index + interval + OVERLAP); i++)
					{
						if (data[i] < eValuePeak)
						{
							eTimePeak = i;
							eValuePeak = data[i];
						}
					}
				}
			}
			// if instead it is negative, search for a maximum
			else
			{
				// Initialize value and time for the ending peak
				eTimePeak = index + 1;
				eValuePeak = sValuePeak;
				// Find the maximum within the interval
				for (i = (index + 1); i <= (index + interval); i++)
				{
					if (data[i] > eValuePeak)
					{
						eTimePeak = i;
						eValuePeak = data[i];
					}
				}
				// Maximaze finding a new min inside the interval if there is
				

				//UPDATE 3 on 7.19.2015 :Searches for replacement of original negative peak 
				// within entire interval and not only before the second peak found 
				// interval length previously update st the for loop stop at end of nFrames

/*				for (i = (index + 1); i < eTimePeak; i++)
				{
					if (data[i] < sValuePeak)
					{
						sTimePeak = i;
						sValuePeak = data[i];
					}
				}
*/
				for (i = (index + 1); i < index + interval; i++)
				{
					if (data[i] < sValuePeak)
					{
						sTimePeak = i;
						sValuePeak = data[i];
					}
				}

				//Additional change needs to compare which peak comes first 
				// thus updating sValuePeak and eValuePeak if need be

				if (eTimePeak < sTimePeak)
				{
					int temp = sTimePeak;
					sTimePeak = eTimePeak;
					eTimePeak = temp;

					sValuePeak = data[sTimePeak];
					eValuePeak = data[eTimePeak];

				}

				//END UPDATE 3 on 7.19.2015



				// When the max is found at the end of the interval check if signal continues to raise
				if ((eTimePeak == (index + interval)) && ((index + interval + OVERLAP) < nFrames))
				{
					for (i = (eTimePeak + 1); i <= (index + interval + OVERLAP); i++)
					{
						if (data[i] > eValuePeak)
						{
							eTimePeak = i;
							eValuePeak = data[i];
						}
					}
				}
			}

			// The difference overtake the threshold and a spike is found
			if (ABS((sValuePeak - eValuePeak)) >= thresh) // necessary to put parentheses for C syntax
			{
				//                 printf("%d (%2.1f-%2.1f), ",index,sValuePeak,eValuePeak);
				spkValues[indexPeak] = ABS((sValuePeak - eValuePeak)); // value is assumed to be the difference
				if (alignmentFlag == 0){
					// With the following code the timestamp is assigned to the higher peak
					////////////////////////////////////////////////////////////////////////////
					if (ABS(sValuePeak) > ABS(eValuePeak))
					{
						spkTimeStamps[indexPeak] = sTimePeak;
					}
					else
					{
						spkTimeStamps[indexPeak] = eTimePeak;
					}
				}
				else {
					////////////////////////////////////////////////////////////////////////////
					// With the following code the timestamp is assigned to the negative peak
					////////////////////////////////////////////////////////////////////////////
					if (sValuePeak < eValuePeak)
					{
						spkTimeStamps[indexPeak] = sTimePeak;
					}
					else
					{
						spkTimeStamps[indexPeak] = eTimePeak;
					}
				}
				////////////////////////////////////////////////////////////////////////////

				// Set the newIndex
				if (((spkTimeStamps[indexPeak] + refrTime) > eTimePeak) && ((spkTimeStamps[indexPeak] + refrTime) < nFrames))
                {
                //DISMISS UPDATE 4 on 7.19.2015 :If peaks do not meet refractory period then move to next point 
					// do not disregard entire window. Second peak might meet requirements with other peak
/*
					newIndex = spkTimeStamps[indexPeak] + refrTime;
*/
					newIndex = spkTimeStamps[indexPeak] + refrTime;
				
                //END UPDATE 4 on 7.19.2015
                }
                else
				{
					newIndex = eTimePeak + 1;
				}

				// increase index to fill spikes arrays
				indexPeak = indexPeak + 1;
			}
		}
	}

	return;
}

