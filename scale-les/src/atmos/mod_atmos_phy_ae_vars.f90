!-------------------------------------------------------------------------------
!> module ATMOSPHERE / Physics Aerosol Microphysics
!!
!! @par Description
!!          Container for mod_atmos_phy_ae
!!
!! @author Team SCALE
!!
!! @par History
!! @li      2014-05-04 (H.Yashiro)    [new]
!<
!-------------------------------------------------------------------------------
#include "inc_openmp.h"
module mod_atmos_phy_ae_vars
  !-----------------------------------------------------------------------------
  !
  !++ used modules
  !
  use scale_precision
  use scale_stdio
  use scale_prof
  use scale_grid_index
  use scale_tracer
  !-----------------------------------------------------------------------------
  implicit none
  private
  !-----------------------------------------------------------------------------
  !
  !++ Public procedure
  !
  public :: ATMOS_PHY_AE_vars_setup
  public :: ATMOS_PHY_AE_vars_fillhalo
  public :: ATMOS_PHY_AE_vars_restart_read
  public :: ATMOS_PHY_AE_vars_restart_write

  !-----------------------------------------------------------------------------
  !
  !++ included parameters
  !
#include "scalelib.h"

  !-----------------------------------------------------------------------------
  !
  !++ Public parameters & variables
  !
  real(RP), public, allocatable :: ATMOS_PHY_AE_QTRC_t(:,:,:,:) ! tendency QTRC [kg/kg/s]

  real(RP), public, allocatable :: ATMOS_PHY_AE_CCN(:,:,:) ! cloud condensation nuclei [/m3]

  !-----------------------------------------------------------------------------
  !
  !++ Private procedure
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private parameters & variables
  !
  logical,               private, save :: ATMOS_PHY_AE_RESTART_OUTPUT        = .false.
  character(len=H_LONG), private, save :: ATMOS_PHY_AE_RESTART_IN_BASENAME   = ''
  character(len=H_LONG), private, save :: ATMOS_PHY_AE_RESTART_OUT_BASENAME  = ''
  character(len=H_MID),  private, save :: ATMOS_PHY_AE_RESTART_OUT_TITLE     = 'ATMOS_PHY_AE restart'
  character(len=H_MID),  private, save :: ATMOS_PHY_AE_RESTART_OUT_DTYPE     = 'DEFAULT'              !< REAL4 or REAL8

  integer,                private, parameter :: VMAX = 1       !< number of the variables
  character(len=H_SHORT), private, save      :: VAR_NAME(VMAX) !< name  of the variables
  character(len=H_MID),   private, save      :: VAR_DESC(VMAX) !< desc. of the variables
  character(len=H_SHORT), private, save      :: VAR_UNIT(VMAX) !< unit  of the variables

  data VAR_NAME / 'CCN' /
  data VAR_DESC / 'cloud condensation nuclei' /
  data VAR_UNIT / '/m3' /

  !-----------------------------------------------------------------------------
contains
  !-----------------------------------------------------------------------------
  !> Setup
  subroutine ATMOS_PHY_AE_vars_setup
    use scale_process, only: &
       PRC_MPIstop
    implicit none

    NAMELIST / PARAM_ATMOS_PHY_AE_VARS / &
       ATMOS_PHY_AE_RESTART_IN_BASENAME, &
       ATMOS_PHY_AE_RESTART_OUTPUT,      &
       ATMOS_PHY_AE_RESTART_OUT_BASENAME

    integer :: v, ierr
    !---------------------------------------------------------------------------

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '+++ Module[ATMOS_PHY_AE VARS]/Categ[ATMOS]'
    !--- read namelist
    rewind(IO_FID_CONF)
    read(IO_FID_CONF,nml=PARAM_ATMOS_PHY_AE_VARS,iostat=ierr)
    if( ierr < 0 ) then !--- missing
       if( IO_L ) write(IO_FID_LOG,*) '*** Not found namelist. Default used.'
    elseif( ierr > 0 ) then !--- fatal error
       write(*,*) 'xxx Not appropriate names in namelist PARAM_ATMOS_PHY_AE_VARS. Check!'
       call PRC_MPIstop
    endif
    if( IO_L ) write(IO_FID_LOG,nml=PARAM_ATMOS_PHY_AE_VARS)

    allocate( ATMOS_PHY_AE_QTRC_t(KA,IA,JA,QA) )

    allocate( ATMOS_PHY_AE_CCN(KA,IA,JA) )

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '*** [ATMOS_PHY_AE] prognostic/diagnostic variables'
    if( IO_L ) write(IO_FID_LOG,'(1x,A,A8,A,A32,3(A))') &
               '***       |',' VARNAME','|', 'DESCRIPTION                     ','[', 'UNIT            ',']'
    do v = 1, VMAX
       if( IO_L ) write(IO_FID_LOG,'(1x,A,i3,A,A8,A,A32,3(A))') &
                  '*** NO.',v,'|',trim(VAR_NAME(v)),'|',VAR_DESC(v),'[',VAR_UNIT(v),']'
    enddo

    ! restart switch
    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) 'Output...'
    if ( ATMOS_PHY_AE_RESTART_OUTPUT ) then
       if( IO_L ) write(IO_FID_LOG,*) '  Restart output (ATMOS_PHY_AE) : YES'
    else
       if( IO_L ) write(IO_FID_LOG,*) '  Restart output (ATMOS_PHY_AE) : NO'
    endif
    if( IO_L ) write(IO_FID_LOG,*)

    return
  end subroutine ATMOS_PHY_AE_vars_setup

  !-----------------------------------------------------------------------------
  !> Communication
  subroutine ATMOS_PHY_AE_vars_fillhalo
    use scale_comm, only: &
       COMM_vars8, &
       COMM_wait
    implicit none
    !---------------------------------------------------------------------------

    ! fill IHALO & JHALO
    call COMM_vars8( ATMOS_PHY_AE_CCN(:,:,:), 1 )
    call COMM_wait ( ATMOS_PHY_AE_CCN(:,:,:), 1 )

    return
  end subroutine ATMOS_PHY_AE_vars_fillhalo

  !-----------------------------------------------------------------------------
  !> Read restart
  subroutine ATMOS_PHY_AE_vars_restart_read
    use scale_fileio, only: &
       FILEIO_read
    use scale_const, only: &
       CONST_UNDEF
    implicit none
    !---------------------------------------------------------------------------

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '*** Input restart file (ATMOS_PHY_AE) ***'

    if ( ATMOS_PHY_AE_RESTART_IN_BASENAME /= '' ) then

       call FILEIO_read( ATMOS_PHY_AE_CCN(:,:,:),                                     & ! [OUT]
                         ATMOS_PHY_AE_RESTART_IN_BASENAME, VAR_NAME(1), 'ZXY', step=1 ) ! [IN]

       call ATMOS_PHY_AE_vars_fillhalo

    else

       if( IO_L ) write(IO_FID_LOG,*) '*** restart file for ATMOS_PHY_AE is not specified.'

       ATMOS_PHY_AE_CCN(:,:,:) = CONST_UNDEF

    endif

    return
  end subroutine ATMOS_PHY_AE_vars_restart_read

  !-----------------------------------------------------------------------------
  !> Write restart
  subroutine ATMOS_PHY_AE_vars_restart_write
    use scale_time, only: &
       TIME_gettimelabel
    use scale_fileio, only: &
       FILEIO_write
    implicit none

    character(len=15)     :: timelabel
    character(len=H_LONG) :: bname

    integer :: n
    !---------------------------------------------------------------------------

    if ( ATMOS_PHY_AE_RESTART_OUT_BASENAME /= '' ) then

       if( IO_L ) write(IO_FID_LOG,*)
       if( IO_L ) write(IO_FID_LOG,*) '*** Output restart file (ATMOS_PHY_AE) ***'

       call TIME_gettimelabel( timelabel )
       write(bname,'(A,A,A)') trim(ATMOS_PHY_AE_RESTART_OUT_BASENAME), '_', trim(timelabel)

       call FILEIO_write( ATMOS_PHY_AE_CCN(:,:,:), bname,               ATMOS_PHY_AE_RESTART_OUT_TITLE,        & ! [IN]
                          VAR_NAME(1), VAR_DESC(1), VAR_UNIT(1), 'ZXY', ATMOS_PHY_AE_RESTART_OUT_DTYPE, .true. ) ! [IN]

    endif

    return
  end subroutine ATMOS_PHY_AE_vars_restart_write

end module mod_atmos_phy_ae_vars
