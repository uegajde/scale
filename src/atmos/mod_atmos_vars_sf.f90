!-------------------------------------------------------------------------------
!> module ATMOSPHERIC Surface Variables
!!
!! @par Description
!!          Container for atmospheric surface variables
!!
!! @author Team SCALE
!!
!! @par History
!! @li      2012-03-27 (H.Yashiro)  [new]
!! @li      2013-08-31 (T.Yamaura)  [mod]
!!
!<
!-------------------------------------------------------------------------------
module mod_atmos_vars_sf
  !-----------------------------------------------------------------------------
  !
  !++ used modules
  !
  use mod_stdio, only: &
     IO_FID_LOG, &
     IO_L,       &
     IO_SYSCHR,  &
     IO_FILECHR
  use gtool_file_h, only: &
     File_HSHORT, &
     File_HMID,   &
     File_HLONG
  !-----------------------------------------------------------------------------
  implicit none
  private
  !-----------------------------------------------------------------------------
  !
  !++ Public procedure
  !
  public :: ATMOS_vars_sf_setup
  public :: ATMOS_vars_sf_restart_read
  public :: ATMOS_vars_sf_restart_write

  !-----------------------------------------------------------------------------
  !
  !++ included parameters
  !
# include "scale-les.h"
  include "inc_precision.h"
  include 'inc_index.h'

  !-----------------------------------------------------------------------------
  !
  !++ Public parameters & variables
  !
  real(RP), public, save :: PREC(IA,JA) ! surface precipitation rate [kg/m2/s]
  real(RP), public, save :: SWD (IA,JA) ! downward short-wave radiation flux (upward positive) [W/m2]
  real(RP), public, save :: LWD (IA,JA) ! downward long-wave radiation flux (upward positive) [W/m2]

  real(RP), public, save :: SFLX_MOMZ (IA,JA) ! momentum z [kg/s/m2]
  real(RP), public, save :: SFLX_MOMX (IA,JA) ! momentum x [kg/s/m2]
  real(RP), public, save :: SFLX_MOMY (IA,JA) ! momentum y [kg/s/m2]
  real(RP), public, save :: SFLX_SWU  (IA,JA) ! upward short-wave radiation flux (upward positive) [W/m2]
  real(RP), public, save :: SFLX_LWU  (IA,JA) ! upward long-wave radiation flux (upward positive) [W/m2]
  real(RP), public, save :: SFLX_SH   (IA,JA) ! sensible heat flux (upward positive) [W/m2]
  real(RP), public, save :: SFLX_LH   (IA,JA) ! latent heat flux (upward positive) [W/m2]
  real(RP), public, save :: SFLX_QVAtm(IA,JA) ! moisture flux for atmosphere [kg/m2/s]

  !-----------------------------------------------------------------------------
  !
  !++ Private procedure
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private parameters & variables
  !
  logical,                   private, save :: ATMOS_SF_RESTART_OUTPUT        = .false.
  character(len=IO_FILECHR), private, save :: ATMOS_SF_RESTART_IN_BASENAME   = 'restart_in'
  character(len=IO_FILECHR), private, save :: ATMOS_SF_RESTART_OUT_BASENAME  = 'restart_out'
  character(len=File_HLONG), private, save :: ATMOS_SF_RESTART_OUT_TITLE     = 'SCALE3 PROGNOSTIC VARS.'
  character(len=File_HLONG), private, save :: ATMOS_SF_RESTART_OUT_SOURCE    = 'SCALE-LES ver. '//VERSION
  character(len=File_HLONG), private, save :: ATMOS_SF_RESTART_OUT_INSTITUTE = 'AICS/RIKEN'

  !-----------------------------------------------------------------------------
contains

  !-----------------------------------------------------------------------------
  !> Setup atmospheric surface variables
  !-----------------------------------------------------------------------------
  subroutine ATMOS_vars_sf_setup
    use mod_stdio, only: &
       IO_FID_CONF
    use mod_process, only: &
       PRC_MPIstop
    implicit none

    NAMELIST / PARAM_ATMOS_SF_VARS / &
       ATMOS_SF_RESTART_IN_BASENAME, &
       ATMOS_SF_RESTART_OUTPUT,      &
       ATMOS_SF_RESTART_OUT_BASENAME

    integer :: ierr
    !---------------------------------------------------------------------------

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '+++ Module[Variables]/Categ[ATMOS]'

    !--- read namelist
    rewind(IO_FID_CONF)
    read(IO_FID_CONF,nml=PARAM_ATMOS_SF_VARS,iostat=ierr)

    if( ierr < 0 ) then !--- missing
       if( IO_L ) write(IO_FID_LOG,*) '*** Not found namelist. Default used.'
    elseif( ierr > 0 ) then !--- fatal error
       write(*,*) 'xxx Not appropriate names in namelist PARAM_ATMOS_SF_VARS. Check!'
       call PRC_MPIstop
    endif
    if( IO_L ) write(IO_FID_LOG,nml=PARAM_ATMOS_SF_VARS)

    PREC(:,:) = 0.0_RP
    SWD (:,:) = 0.0_RP
    LWD (:,:) = 0.0_RP

    SFLX_MOMZ (:,:) = 0.0_RP
    SFLX_MOMX (:,:) = 0.0_RP
    SFLX_MOMY (:,:) = 0.0_RP
    SFLX_SWU  (:,:) = 0.0_RP
    SFLX_LWU  (:,:) = 0.0_RP
    SFLX_SH   (:,:) = 0.0_RP
    SFLX_LH   (:,:) = 0.0_RP
    SFLX_QVAtm(:,:) = 0.0_RP

    return
  end subroutine ATMOS_vars_sf_setup

  !-----------------------------------------------------------------------------
  !> Read restart of atmospheric surface variables
  !-----------------------------------------------------------------------------
  subroutine ATMOS_vars_sf_restart_read
    use mod_comm, only: &
       COMM_vars8, &
       COMM_wait
    use gtool_file, only: &
       FileRead
    implicit none

!    real(RP) :: restart_atmos(KMAX,IMAX,JMAX) !> restart file (no HALO)

!    character(len=IO_FILECHR) :: bname
!    character(len=8)          :: lname

!    integer :: i, j
    !---------------------------------------------------------------------------

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '*** Input restart file (atmos) ***'

!    bname = ATMOS_SF_RESTART_IN_BASENAME
!    write(lname,'(A,I4.4)') 'ZDEF', KMAX

!    call FileRead( restart_atmos(:,:,:), bname, 'DENS', 1, PRC_myrank )
!    DENS(KS:KE,IS:IE,JS:JE) = restart_atmos(1:KMAX,1:IMAX,1:JMAX)

    ! fill IHALO & JHALO
!    call COMM_vars8( DENS(:,:,:), 1 )
!    call COMM_wait ( RHOT(:,:,:), 5 )

    return
  end subroutine ATMOS_vars_sf_restart_read

  !-----------------------------------------------------------------------------
  !> Write restart of atmospheric surface variables
  !-----------------------------------------------------------------------------
  subroutine ATMOS_vars_sf_restart_write
!    use mod_time, only: &
!       NOWSEC => TIME_NOWDAYSEC
!    use gtool_file_h, only: &
!       File_REAL4, &
!       File_REAL8
!    use gtool_file, only: &
!       FileCreate, &
!       FileAddVariable, &
!       FilePutAxis, &
!       FileWrite, &
!       FielClose
    implicit none

!    real(RP) :: restart_atmos(KMAX,IMAX,JMAX) !> restart file (no HALO)

!    character(len=IO_FILECHR) :: bname
!    integer :: n
    !---------------------------------------------------------------------------

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '*** Output restart file (atmos) ***'

!    write(bname(1:15), '(F15.3)') NOWSEC
!    do n = 1, 15
!      if ( bname(n:n) == ' ' ) bname(n:n) = '0'
!    end do
!    write(bname,'(A,A,A)') trim(ATMOS_SF_RESTART_OUT_BASENAME), '_', basename

    return
  end subroutine ATMOS_vars_sf_restart_write

end module mod_ATMOS_vars_sf
