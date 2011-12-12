#! /bin/bash -x

export HMDIR=~/GCMresults/sol/latest/output
export BIN=~/Dropbox/Inbox/scale3/bin/MacOSX-ifort
export EXE=scale3

export OUTDIR=${HMDIR}/coldbubble

# Run Command
export MPIRUN="/usr/local/mpich213/bin/mpiexec -np 4 -f /Users/yashiro/libs/mpilib/machines_local"

mkdir -p $OUTDIR
cd $OUTDIR

########################################################################
cat << End_of_SYSIN > ${OUTDIR}/${EXE}.cnf

#####
#
# Scale3 benchmark configuration
#
#####

&PARAM_TIME
 TIME_STARTDATE             =  2000, 1, 1, 0, 0, 0,
 TIME_STARTMS               =  0.D0,
 TIME_DURATION              =  30D0,
 TIME_DURATION_UNIT         = 'SEC',
 TIME_DT                    =  300.D0,
 TIME_DT_UNIT               = 'MSEC',
 TIME_DT_ATMOS_DYN          =  300.D0,
 TIME_DT_ATMOS_DYN_UNIT     = 'MSEC',
 TIME_DT_ATMOS_RESTART      =  300.D0,
 TIME_DT_ATMOS_RESTART_UNIT = 'SEC',
/

&PARAM_PRC
 PRC_NUM_X = 2,
 PRC_NUM_Y = 2,
 PRC_PERIODIC_X  = .true.,
 PRC_PERIODIC_Y  = .true.,
/

&PARAM_GRID
 GRID_IMAX = 100,
 GRID_JMAX = 100,
 GRID_KMAX = 40,
 GRID_DX   = 200.D0,
 GRID_DY   = 200.D0,
 GRID_DZ   = 200.D0,
/

&PARAM_ATMOS
 ATMOS_TYPE_DYN    = 'fent_fct',
 ATMOS_TYPE_PHY_TB = 'smagorinsky',
 ATMOS_TYPE_PHY_MP = 'NDW6',
 ATMOS_TYPE_PHY_RD = 'mstrnX',
/

&PARAM_ATMOS_VARS
 ATMOS_QTRC_NMAX = 11,
 ATMOS_RESTART_IN_BASENAME = '../init_coldbubble/init_coldbubble_63072000000.000',
/

&PARAM_ATMOS_DYN
 ATMOS_DYN_NUMERICAL_DIFF = 1.D-4
/

&PARAM_ATMOS_REFSTATE
 TEMP_SFC = 300.D0
/

&PARAM_ATMOS_BOUNDARY
 ATMOS_BOUNDARY_UPPERSPONGE_DZ   = 1.5D3,
 ATMOS_BOUNDARY_UPPERSPONGE_TAUZ = 75.D0,
/

End_of_SYSIN
########################################################################

# run
echo "job ${RUNNAME} started at " `date`
$MPIRUN $BIN/$EXE ${EXE}.cnf > STDOUT 2>&1
echo "job ${RUNNAME} end     at " `date`

exit
