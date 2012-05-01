#! /bin/bash -x
#
# for Local machine (MacOSX 8core+ifort+MPICH2)
#
postfix=${1}

export HMDIR=~/GCMresults/sol/latest
export BIN=~/Dropbox/Inbox/scale3/bin/${SCALE_SYS}
export EXE=scale3_init_030m88x8x8_ndw6_${postfix}

export OUTDIR=${HMDIR}/output/${postfix}/DYCOMS2RF01_030m

mkdir -p ${OUTDIR}
cd ${OUTDIR}

########################################################################
cat << End_of_SYSIN > ${OUTDIR}/${EXE}.cnf

#####
#
# Scale3 mkinit configulation
#
#####

&PARAM_PRC
 PRC_NUM_X       = 1,
 PRC_NUM_Y       = 1,
/

&PARAM_GRID
 GRID_OUT_BASENAME = "grid_030m_88x8x8",
/

&PARAM_COMM
 COMM_total_doreport  = .true.,
 COMM_total_globalsum = .true.,
/

&PARAM_ATMOS_VARS
 ATMOS_RESTART_OUTPUT         = .true.,
 ATMOS_RESTART_OUT_BASENAME   = "init_DYCOMS2RF01",
/

&PARAM_MKINIT
 MKINIT_initname = "DYCOMS2_RF01",
/

End_of_SYSIN
########################################################################

# run
echo "job ${RUNNAME} started at " `date`
/usr/local/mpich213/bin/mpiexec -np 1 -f /Users/yashiro/libs/mpilib/machines_local $BIN/$EXE ${EXE}.cnf > STDOUT 2>&1
echo "job ${RUNNAME} end     at " `date`

export EXE=DYCOMS2RF01_030m88x8x8_ndw6_${postfix}

########################################################################
cat << End_of_SYSIN > ${OUTDIR}/${EXE}.cnf

#####
#
# Scale3 configulation
#
#####

&PARAM_PRC
 PRC_NUM_X       = 1,
 PRC_NUM_Y       = 1,
/

&PARAM_TIME
 TIME_STARTDATE             = 2000, 1, 1, 0, 0, 0,
 TIME_STARTMS               = 0.D0,
 TIME_DURATION              = 3600.D0,
 TIME_DURATION_UNIT         = "SEC",
 TIME_DT                    = 0.6D0,
 TIME_DT_UNIT               = "SEC",
 TIME_DT_ATMOS_DYN          = 0.03D0,
 TIME_DT_ATMOS_DYN_UNIT     = "SEC",
 TIME_NSTEP_ATMOS_DYN       = 20,
 TIME_DT_ATMOS_PHY_TB       = 0.6D0,
 TIME_DT_ATMOS_PHY_TB_UNIT  = "SEC",
 TIME_DT_ATMOS_PHY_MP       = 0.6D0,
 TIME_DT_ATMOS_PHY_MP_UNIT  = "SEC",
 TIME_DT_ATMOS_PHY_RD       = 0.6D0,
 TIME_DT_ATMOS_PHY_RD_UNIT  = "SEC",
 TIME_DT_ATMOS_RESTART      = 3600.0D0,
 TIME_DT_ATMOS_RESTART_UNIT = "SEC",
 TIME_DT_OCEAN              = 7200.D0,
 TIME_DT_OCEAN_UNIT         = "SEC",
 TIME_DT_OCEAN_RESTART      = 7200.D0,
 TIME_DT_OCEAN_RESTART_UNIT = "SEC",
/

&PARAM_GRID
 GRID_IN_BASENAME  = "",
 GRID_OUT_BASENAME = "",
/

&PARAM_GEOMETRICS
 GEOMETRICS_OUT_BASENAME = "",
/

&PARAM_COMM
 COMM_total_doreport  = .true.,
 COMM_total_globalsum = .true.,
/

&PARAM_ATMOS
 ATMOS_TYPE_DYN    = "fent_pdfct",
 ATMOS_TYPE_PHY_TB = "smagorinsky",
 ATMOS_TYPE_PHY_MP = "NDW6",
 ATMOS_TYPE_PHY_RD = "mstrnX",
/

&PARAM_ATMOS_VARS
 ATMOS_RESTART_IN_BASENAME      = "./init_DYCOMS2RF01_63072000000.000",
 ATMOS_RESTART_OUTPUT           = .false.,
 ATMOS_RESTART_CHECK            = .false.,
/

&PARAM_ATMOS_REFSTATE
 ATMOS_REFSTATE_IN_BASENAME  = "",
 ATMOS_REFSTATE_OUT_BASENAME = "",
 ATMOS_REFSTATE_TYPE         = "ISA",
 ATMOS_REFSTATE_POTT_UNIFORM = 300.D0
 ATMOS_REFSTATE_TEMP_SFC     = 289.D0     
/

&PARAM_ATMOS_BOUNDARY
 ATMOS_BOUNDARY_OUT_BASENAME = "boundary",
! ATMOS_BOUNDARY_VALUE_VELZ   =   0.D0,
 ATMOS_BOUNDARY_TAUZ         =  10.D0,
/

&PARAM_ATMOS_DYN
 ATMOS_DYN_NUMERICAL_DIFF = 1.D-3,
! ATMOS_DYN_LSsink_D = 3.75D-6
/

&PARAM_ATMOS_PHY_SF
 ATMOS_PHY_SF_CM_min = 0.0011D0,
 ATMOS_PHY_SF_CH_min = 0.0011D0,
 ATMOS_PHY_SF_CE_min = 0.0011D0,
/

&PARAM_ATMOS_PHY_MP
! DOAUTOCONVERSION = .false.,
! DOPRECIPITATION  = .false.,
! MP_ssw_lim       = 0.01D0,
/

&PARAM_OCEAN
 OCEAN_TYPE = "FIXEDSST",
/

&PARAM_OCEAN_VARS
 OCEAN_RESTART_OUTPUT       = .false.,
/

&PARAM_OCEAN_FIXEDSST
 OCEAN_FIXEDSST_STARTSST = 292.5D0,
/

&PARAM_HISTORY
 HISTORY_OUT_BASENAME      = "history",
 HISTORY_DEFAULT_TINTERVAL = 60.D0,
! HISTORY_DEFAULT_TINTERVAL = 0.6D0,
 HISTORY_DEFAULT_TUNIT     = "SEC",
 HISTORY_DEFAULT_AVERAGE   = .false.,
 HISTORY_DATATYPE          = "REAL4",
/

&HISTITEM item='DENS' /
#&HISTITEM item='MOMX' /
#&HISTITEM item='MOMY' /
#&HISTITEM item='MOMZ' /
#&HISTITEM item='RHOT' /

&HISTITEM item='U'    /
&HISTITEM item='V'    /
&HISTITEM item='W'    /
&HISTITEM item='PT'   /
&HISTITEM item='PRES' /
&HISTITEM item='T'    /

&HISTITEM item='RH'  /
#&HISTITEM item='VOR'  /
#&HISTITEM item='ENGP' /
#&HISTITEM item='ENGK' /
#&HISTITEM item='ENGI' /

&HISTITEM item='QV'   /
&HISTITEM item='QTOT' /
&HISTITEM item='QC'   /
&HISTITEM item='QR'   /
#&HISTITEM item='QI'   /
#&HISTITEM item='QS'   /
#&HISTITEM item='QG'   /
&HISTITEM item='NC'   /
&HISTITEM item='NR'   /
#&HISTITEM item='NI'   /
#&HISTITEM item='NS'   /
#&HISTITEM item='NG'   /

&HISTITEM item='TKE'  /
&HISTITEM item='NU'   /
#&HISTITEM item='Pr'   /
#&HISTITEM item='Ri'   /

#&HISTITEM item='SST'   /

&HISTITEM item='sink'    /
&HISTITEM item='EFLX_rd' /
&HISTITEM item='TEMP_t_rd' /
&HISTITEM item='QT'      /
&HISTITEM item='QL'      /
&HISTITEM item='LWPT'    /
&HISTITEM item='LWPT_v'  /
&HISTITEM item='VELZ_v'  /
&HISTITEM item='VELX_v'  /
&HISTITEM item='VELY_v'  /

&HISTITEM item='LWP'   /
&HISTITEM item='SHFLX' /
&HISTITEM item='LHFLX' /
&HISTITEM item='Zi'    /
&HISTITEM item='Zb'    /

End_of_SYSIN
########################################################################

# run
echo "job ${RUNNAME} started at " `date`
/usr/local/mpich213/bin/mpiexec -np 1 -f /Users/yashiro/libs/mpilib/machines_local $BIN/$EXE ${EXE}.cnf > STDOUT 2>&1
echo "job ${RUNNAME} end     at " `date`

exit
