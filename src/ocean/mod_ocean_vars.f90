!-------------------------------------------------------------------------------
!> module OCEAN Variables
!!
!! @par Description
!!          Container for ocean variables
!!
!! @author Team SCALE
!!
!<
!-------------------------------------------------------------------------------
module mod_ocean_vars
  !-----------------------------------------------------------------------------
  !
  !++ used modules
  !
  use gtool_file_h, only: &
     File_HSHORT, &
     File_HMID,   &
     File_HLONG
  use mod_stdio, only: &
     IO_FID_LOG, &
     IO_L,       &
     IO_SYSCHR,  &
     IO_FILECHR
  use mod_time, only: &
     TIME_rapstart, &
     TIME_rapend
  !-----------------------------------------------------------------------------
  implicit none
  private
  !-----------------------------------------------------------------------------
  !
  !++ included parameters
  !
  include "inc_precision.h"
  include 'inc_index.h'

  !-----------------------------------------------------------------------------
  !
  !++ Public procedure
  !
  public :: OCEAN_vars_setup
  public :: OCEAN_vars_fillhalo
  public :: OCEAN_vars_restart_read
  public :: OCEAN_vars_restart_write
  public :: OCEAN_vars_history
  public :: OCEAN_vars_total

  !-----------------------------------------------------------------------------
  !
  !++ Public parameters & variables
  !
  real(RP), public, save :: SST(1,IA,JA) !< sea surface prognostics container (with HALO)

  integer,                    public, save :: I_SST = 1
  character(len=File_HSHORT), public, save :: OP_NAME(1) !< name  of the ocean variables
  character(len=File_HMID),   public, save :: OP_DESC(1) !< desc. of the ocean variables
  character(len=File_HSHORT), public, save :: OP_UNIT(1) !< unit  of the ocean variables

  data OP_NAME / 'SST' /
  data OP_DESC / 'sea surface temp.' /
  data OP_UNIT / 'K' /

  character(len=IO_SYSCHR),  public, save :: OCEAN_TYPE_PHY = 'OFF' !< Ocean physics type
  logical,                   public, save :: OCEAN_sw_phy           !< do ocean physics update?
  logical,                   public, save :: OCEAN_sw_restart       !< output restart?

  character(len=IO_FILECHR), public, save :: OCEAN_RESTART_IN_BASENAME = '' !< basename of the input file

  !-----------------------------------------------------------------------------
  !
  !++ Private procedure
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private parameters & variables
  !
  logical,                   private, save :: OCEAN_RESTART_OUTPUT       = .false.                !< output restart file?
  character(len=IO_FILECHR), private, save :: OCEAN_RESTART_OUT_BASENAME = 'restart_out'          !< basename of the output file
  character(len=IO_SYSCHR),  private, save :: OCEAN_RESTART_OUT_TITLE    = 'SCALE3 OCEANIC VARS.' !< title    of the output file
  character(len=IO_SYSCHR),  private, save :: OCEAN_RESTART_OUT_DTYPE    = 'DEFAULT'              !< REAL4 or REAL8

  logical,                   private, save :: OCEAN_VARS_CHECKRANGE      = .false.

  !-----------------------------------------------------------------------------
contains
  !-----------------------------------------------------------------------------
  !> Setup
  subroutine OCEAN_vars_setup
    use mod_stdio, only: &
       IO_FID_CONF
    use mod_process, only: &
       PRC_MPIstop
    implicit none

    NAMELIST / PARAM_OCEAN / &
       OCEAN_TYPE_PHY

    NAMELIST / PARAM_OCEAN_VARS /  &
       OCEAN_RESTART_IN_BASENAME,  &
       OCEAN_RESTART_OUTPUT,       &
       OCEAN_RESTART_OUT_BASENAME, &
       OCEAN_RESTART_OUT_TITLE,    &
       OCEAN_VARS_CHECKRANGE

    integer :: ierr
    integer :: ip
    !---------------------------------------------------------------------------

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '+++ Module[OCEAN VARS]/Categ[OCEAN]'

    !--- read namelist
    rewind(IO_FID_CONF)
    read(IO_FID_CONF,nml=PARAM_OCEAN,iostat=ierr)

    if( ierr < 0 ) then !--- missing
       if( IO_L ) write(IO_FID_LOG,*) '*** Not found namelist. Default used.'
    elseif( ierr > 0 ) then !--- fatal error
       write(*,*) 'xxx Not appropriate names in namelist PARAM_OCEAN. Check!'
       call PRC_MPIstop
    endif
    if( IO_L ) write(IO_FID_LOG,nml=PARAM_OCEAN)

    if( IO_L ) write(IO_FID_LOG,*) '*** [OCEAN] selected components'

    if ( OCEAN_TYPE_PHY /= 'OFF' .AND. OCEAN_TYPE_PHY /= 'NONE' ) then
       if( IO_L ) write(IO_FID_LOG,*) '*** Ocean physics : ON'
       OCEAN_sw_phy = .true.
    else
       if( IO_L ) write(IO_FID_LOG,*) '*** Ocean physics : OFF'
       OCEAN_sw_phy = .false.
    endif

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '+++ Module[OCEAN VARS]/Categ[OCEAN]'

    !--- read namelist
    rewind(IO_FID_CONF)
    read(IO_FID_CONF,nml=PARAM_OCEAN_VARS,iostat=ierr)

    if( ierr < 0 ) then !--- missing
       if( IO_L ) write(IO_FID_LOG,*) '*** Not found namelist. Default used.'
    elseif( ierr > 0 ) then !--- fatal error
       write(*,*) 'xxx Not appropriate names in namelist PARAM_OCEAN_VARS. Check!'
       call PRC_MPIstop
    endif
    if( IO_L ) write(IO_FID_LOG,nml=PARAM_OCEAN_VARS)

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '*** [OCEAN] prognostic variables'
    if( IO_L ) write(IO_FID_LOG,'(1x,A,A8,A,A32,3(A))') &
               '***       |',' VARNAME','|', 'DESCRIPTION                     ','[', 'UNIT            ',']'
    do ip = 1, 1
       if( IO_L ) write(IO_FID_LOG,'(1x,A,i3,A,A8,A,A32,3(A))') &
                  '*** NO.',ip,'|',trim(OP_NAME(ip)),'|', OP_DESC(ip),'[', OP_UNIT(ip),']'
    enddo

    if( IO_L ) write(IO_FID_LOG,*) 'Output...'
    if ( OCEAN_RESTART_OUTPUT ) then
       if( IO_L ) write(IO_FID_LOG,*) '  Ocean restart output : YES'
       OCEAN_sw_restart = .true.
    else
       if( IO_L ) write(IO_FID_LOG,*) '  Ocean restart output : NO'
       OCEAN_sw_restart = .false.
    endif
    if( IO_L ) write(IO_FID_LOG,*)

    return
  end subroutine OCEAN_vars_setup

  !-----------------------------------------------------------------------------
  !> fill HALO region of land variables
  subroutine OCEAN_vars_fillhalo
    use mod_comm, only: &
       COMM_vars8, &
       COMM_wait
    implicit none
    !---------------------------------------------------------------------------

    ! fill IHALO & JHALO
    call COMM_vars8( SST(:,:,:), 1 )

    call COMM_wait ( SST(:,:,:), 1 )

    return
  end subroutine OCEAN_vars_fillhalo

  !-----------------------------------------------------------------------------
  !> Read ocean restart
  subroutine OCEAN_vars_restart_read
    use mod_fileio, only: &
       FILEIO_read
    use mod_const, only: &
       CONST_Tstd
    use mod_comm, only: &
       COMM_vars8, &
       COMM_wait
    implicit none
    !---------------------------------------------------------------------------

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '*** Input restart file (ocean) ***'

    call TIME_rapstart('FILE I NetCDF')

    if ( OCEAN_RESTART_IN_BASENAME /= '' ) then

       call FILEIO_read( SST(1,:,:),                                    & ! [OUT]
                         OCEAN_RESTART_IN_BASENAME, 'SST', 'XY', step=1 ) ! [IN]

       ! fill IHALO & JHALO
       call OCEAN_vars_fillhalo
    else
       if( IO_L ) write(IO_FID_LOG,*) '*** restart file for ocean is not specified.'

       SST(:,:,:) = CONST_Tstd
    endif

    call TIME_rapend  ('FILE I NetCDF')

    return
  end subroutine OCEAN_vars_restart_read

  !-----------------------------------------------------------------------------
  !> Write ocean restart
  subroutine OCEAN_vars_restart_write
    use mod_time, only: &
       NOWSEC => TIME_NOWDAYSEC
    use mod_fileio, only: &
       FILEIO_write
    implicit none

    character(len=IO_FILECHR) :: bname

    integer :: n
    !---------------------------------------------------------------------------

    call TIME_rapstart('FILE O NetCDF')

    if ( OCEAN_RESTART_OUT_BASENAME /= '' ) then

       if( IO_L ) write(IO_FID_LOG,*)
       if( IO_L ) write(IO_FID_LOG,*) '*** Output restart file (ocean) ***'

       bname = ''
       write(bname(1:15), '(F15.3)') NOWSEC
       do n = 1, 15
          if ( bname(n:n) == ' ' ) bname(n:n) = '0'
       end do
       write(bname,'(A,A,A)') trim(OCEAN_RESTART_OUT_BASENAME), '_', trim(bname)

       call FILEIO_write( SST(1,:,:), bname,                        OCEAN_RESTART_OUT_TITLE, & ! [IN]
                          OP_NAME(1), OP_DESC(1), OP_UNIT(1), 'XY', OCEAN_RESTART_OUT_DTYPE  ) ! [IN]

    endif

    call TIME_rapend  ('FILE O NetCDF')

    return
  end subroutine OCEAN_vars_restart_write

  !-----------------------------------------------------------------------------
  !> History output set for ocean variables
  subroutine OCEAN_vars_history
    use mod_misc, only: &
       MISC_valcheck
    use mod_time, only: &
       TIME_DTSEC_OCEAN
    use mod_history, only: &
       HIST_in
    implicit none
    !---------------------------------------------------------------------------

    if ( OCEAN_VARS_CHECKRANGE ) then
       call MISC_valcheck( SST(:,:,:),    0.0_RP, 1000.0_RP, OP_NAME(I_SST) )
    endif

    call HIST_in( SST(1,:,:), 'O_SST', OP_DESC(I_SST), OP_UNIT(I_SST), TIME_DTSEC_OCEAN )

    return
  end subroutine OCEAN_vars_history

  !-----------------------------------------------------------------------------
  !> Budget monitor for ocean
  subroutine OCEAN_vars_total
!    use mod_comm, only: &
!       STAT_checktotal, &
!       STAT_total
    implicit none

    real(RP) :: total ! dummy
    !---------------------------------------------------------------------------

!    if ( STAT_checktotal ) then
!
!       call STAT_total( total, SST(:,:,:), OP_NAME(I_SST) )
!
!    endif

    return
  end subroutine OCEAN_vars_total

end module mod_ocean_vars
