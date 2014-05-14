!-------------------------------------------------------------------------------
!> module COUPLER Variables
!!
!! @par Description
!!          Container for coupler variables
!!
!! @author Team SCALE
!! @li      2013-08-31 (T.Yamaura)  [new]
!!
!<
!-------------------------------------------------------------------------------
module mod_cpl_vars
  !-----------------------------------------------------------------------------
  !
  !++ used modules
  !
  use scale_precision
  use scale_stdio
  use scale_prof
  use scale_debug
  use scale_grid_index
  !-----------------------------------------------------------------------------
  implicit none
  private
  !-----------------------------------------------------------------------------
  !
  !++ Public procedure
  !
  public :: CPL_vars_setup
  public :: CPL_vars_fillhalo
  public :: CPL_vars_restart_read
  public :: CPL_vars_restart_write
  public :: CPL_vars_history
  public :: CPL_vars_total

  public :: CPL_vars_merge
  public :: CPL_putAtm
  public :: CPL_putLnd
  public :: CPL_putUrb
  public :: CPL_putOcn
  public :: CPL_getCPL2Atm
  public :: CPL_getCPL2Lnd
  public :: CPL_getCPL2Urb
  public :: CPL_getCPL2Ocn

  !-----------------------------------------------------------------------------
  !
  !++ Public parameters & variables
  !
  logical,                public, save :: CPL_do          = .true.  ! main switch for the model

  character(len=H_SHORT), public, save :: CPL_TYPE_AtmOcn = 'OFF'   !< atmos-ocean coupler type
  character(len=H_SHORT), public, save :: CPL_TYPE_AtmLnd = 'OFF'   !< atmos-land coupler type
  logical,                public, save :: CPL_SST_UPDATE  = .false. !< is Sea  Surface Temperature updated?
  logical,                public, save :: CPL_LST_UPDATE  = .false. !< is Land Surface Temperature updated?

  logical,                public, save :: CPL_sw_AtmOcn             !< do atmos-ocean coupler calculation?
  logical,                public, save :: CPL_sw_AtmLnd             !< do atmos-land  coupler calculation?
  logical,                public, save :: CPL_sw_restart            !< output coupler restart?

  real(RP), public, save, allocatable :: SST  (:,:)   ! Sea Surface Temperature [K]
  real(RP), public, save, allocatable :: LST  (:,:)   ! Land Surface Temperature [K]
  real(RP), public, save, allocatable :: ALBW (:,:,:) ! Sea Surface albedo [0-1]
  real(RP), public, save, allocatable :: ALBG (:,:,:) ! Land Surface albedo [0-1]
  real(RP), public, save, allocatable :: Z0W  (:,:)   ! Sea Surface roughness length [m]
  real(RP), public, save, allocatable :: SkinT(:,:)   ! Ground Skin Temperature [K]
  real(RP), public, save, allocatable :: SkinW(:,:)   ! Ground Skin Water       [kg/m2]
  real(RP), public, save, allocatable :: SnowQ(:,:)   ! Ground Snow amount      [kg/m2]
  real(RP), public, save, allocatable :: SnowT(:,:)   ! Ground Snow Temperature [K]

  real(RP), public, save, allocatable :: XMFLX (:,:) ! x-momentum flux [kg/m2/s]
  real(RP), public, save, allocatable :: YMFLX (:,:) ! y-momentum flux [kg/m2/s]
  real(RP), public, save, allocatable :: ZMFLX (:,:) ! z-momentum flux [kg/m2/s]
  real(RP), public, save, allocatable :: SWUFLX(:,:) ! upward short-wave radiation flux (upward positive) [W/m2]
  real(RP), public, save, allocatable :: LWUFLX(:,:) ! upward long-wave radiation flux (upward positive) [W/m2]
  real(RP), public, save, allocatable :: SHFLX (:,:) ! sensible heat flux (upward positive) [W/m2]
  real(RP), public, save, allocatable :: LHFLX (:,:) ! latent heat flux (upward positive) [W/m2]
  real(RP), public, save, allocatable :: QVFLX (:,:) ! moisture flux for atmosphere [kg/m2/s]

  real(RP), public, save, allocatable :: Lnd_GHFLX  (:,:) ! ground heat flux (upward positive) [W/m2]
  real(RP), public, save, allocatable :: Lnd_PRECFLX(:,:) ! precipitation flux [kg/m2/s]
  real(RP), public, save, allocatable :: Lnd_QVFLX  (:,:) ! moisture flux for land [kg/m2/s]

  real(RP), public, save, allocatable :: Ocn_WHFLX  (:,:) ! water heat flux (upward positive) [W/m2]
  real(RP), public, save, allocatable :: Ocn_PRECFLX(:,:) ! precipitation flux [kg/m2/s]
  real(RP), public, save, allocatable :: Ocn_QVFLX  (:,:) ! moisture flux for ocean [kg/m2/s]

  ! surface fluxes from atmosphere-ocean coupler
  real(RP), public, save, allocatable :: AtmOcn_XMFLX (:,:) ! x-momentum flux [kg/m2/s]
  real(RP), public, save, allocatable :: AtmOcn_YMFLX (:,:) ! y-momentum flux [kg/m2/s]
  real(RP), public, save, allocatable :: AtmOcn_ZMFLX (:,:) ! z-momentum flux [kg/m2/s]
  real(RP), public, save, allocatable :: AtmOcn_SWUFLX(:,:) ! upward short-wave radiation flux (upward positive) [W/m2]
  real(RP), public, save, allocatable :: AtmOcn_LWUFLX(:,:) ! upward long-wave  radiation flux (upward positive) [W/m2]
  real(RP), public, save, allocatable :: AtmOcn_SHFLX (:,:) ! sensible heat flux (upward positive) [W/m2]
  real(RP), public, save, allocatable :: AtmOcn_LHFLX (:,:) ! latent   heat flux (upward positive) [W/m2]
  real(RP), public, save, allocatable :: AtmOcn_QVFLX (:,:) ! moisture flux for atmosphere [kg/m2/s]

  ! surface fluxes from atmosphere-land coupler
  real(RP), public, save, allocatable :: AtmLnd_XMFLX (:,:) ! x-momentum flux [kg/m2/s]
  real(RP), public, save, allocatable :: AtmLnd_YMFLX (:,:) ! y-momentum flux [kg/m2/s]
  real(RP), public, save, allocatable :: AtmLnd_ZMFLX (:,:) ! z-momentum flux [kg/m2/s]
  real(RP), public, save, allocatable :: AtmLnd_SWUFLX(:,:) ! upward short-wave radiation flux (upward positive) [W/m2]
  real(RP), public, save, allocatable :: AtmLnd_LWUFLX(:,:) ! upward long-wave  radiation flux (upward positive) [W/m2]
  real(RP), public, save, allocatable :: AtmLnd_SHFLX (:,:) ! sensible heat flux (upward positive) [W/m2]
  real(RP), public, save, allocatable :: AtmLnd_LHFLX (:,:) ! latent   heat flux (upward positive) [W/m2]
  real(RP), public, save, allocatable :: AtmLnd_QVFLX (:,:) ! moisture flux for atmosphere [kg/m2/s]

  ! Atmospheric values
  real(RP), public, save, allocatable :: CPL_DENS(:,:) ! air density [kg/m3]
  real(RP), public, save, allocatable :: CPL_MOMX(:,:) ! momentum x [kg/m2/s]
  real(RP), public, save, allocatable :: CPL_MOMY(:,:) ! momentum y [kg/m2/s]
  real(RP), public, save, allocatable :: CPL_MOMZ(:,:) ! momentum z [kg/m2/s]
  real(RP), public, save, allocatable :: CPL_RHOS(:,:) ! air density at the surface [kg/m3]
  real(RP), public, save, allocatable :: CPL_PRES(:,:) ! pressure at the surface [Pa]
  real(RP), public, save, allocatable :: CPL_TMPS(:,:) ! air temperature at the surface [K]
  real(RP), public, save, allocatable :: CPL_TMPA(:,:) ! air temperature at the 1st atmospheric layer [K]
  real(RP), public, save, allocatable :: CPL_QV  (:,:) ! ratio of mass of tracer to total mass [kg/kg]
  real(RP), public, save, allocatable :: CPL_PREC(:,:) ! surface precipitation rate [kg/m2/s]
  real(RP), public, save, allocatable :: CPL_SWD (:,:) ! downward short-wave radiation flux (upward positive) [W/m2]
  real(RP), public, save, allocatable :: CPL_LWD (:,:) ! downward long-wave radiation flux (upward positive) [W/m2]

  ! Ocean values
  real(RP), public, save, allocatable :: CPL_TW  (:,:) ! water temperature [K]

  ! Land values
  real(RP), public, save, allocatable :: CPL_TG  (:,:) ! soil temperature [K]
  real(RP), public, save, allocatable :: CPL_QVEF(:,:) ! efficiency of evaporation [0-1]
  real(RP), public, save, allocatable :: CPL_TCS (:,:) ! thermal conductivity for soil [W/m/K]
  real(RP), public, save, allocatable :: CPL_DZG (:,:) ! soil depth [m]
  real(RP), public, save, allocatable :: CPL_Z0M (:,:) ! roughness length for momemtum [m]
  real(RP), public, save, allocatable :: CPL_Z0H (:,:) ! roughness length for heat [m]
  real(RP), public, save, allocatable :: CPL_Z0E (:,:) ! roughness length for vapor [m]

  ! counter
  real(RP), public, save :: CNT_Atm_Ocn ! counter for atmos flux by ocean
  real(RP), public, save :: CNT_Atm_Lnd ! counter for atmos flux by land
  real(RP), public, save :: CNT_Ocn     ! counter for ocean flux
  real(RP), public, save :: CNT_Lnd     ! counter for land flux

  !-----------------------------------------------------------------------------
  !
  !++ Private procedure
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private parameters & variables
  !
  logical,                private, save      :: CPL_RESTART_OUTPUT       = .false.       !< output restart file?
  character(len=H_LONG),  private, save      :: CPL_RESTART_IN_BASENAME  = ''            !< basename of the input file
  character(len=H_LONG),  private, save      :: CPL_RESTART_OUT_BASENAME = ''            !< basename of the output file
  character(len=H_MID),   private, save      :: CPL_RESTART_OUT_TITLE    = 'CPL restart' !< title    of the output file
  character(len=H_MID),   private, save      :: CPL_RESTART_OUT_DTYPE    = 'DEFAULT'     !< REAL4 or REAL8

  logical,                private, save      :: CPL_VARS_CHECKRANGE      = .false.

  integer,                private, parameter :: VMAX          = 25
  integer,                private, parameter :: I_LST         =  1
  integer,                private, parameter :: I_SST         =  2
  integer,                private, parameter :: I_ALBW_SW     =  3
  integer,                private, parameter :: I_ALBW_LW     =  4
  integer,                private, parameter :: I_ALBG_SW     =  5
  integer,                private, parameter :: I_ALBG_LW     =  6
  integer,                private, parameter :: I_Z0W         =  7
  integer,                private, parameter :: I_SkinT       =  8
  integer,                private, parameter :: I_SkinW       =  9
  integer,                private, parameter :: I_SnowQ       = 10
  integer,                private, parameter :: I_SnowT       = 11
  integer,                private, parameter :: I_XMFLX       = 12
  integer,                private, parameter :: I_YMFLX       = 13
  integer,                private, parameter :: I_ZMFLX       = 14
  integer,                private, parameter :: I_SWUFLX      = 15
  integer,                private, parameter :: I_LWUFLX      = 16
  integer,                private, parameter :: I_SHFLX       = 17
  integer,                private, parameter :: I_LHFLX       = 18
  integer,                private, parameter :: I_QVFLX       = 19
  integer,                private, parameter :: I_Lnd_GHFLX   = 20
  integer,                private, parameter :: I_Lnd_PRECFLX = 21
  integer,                private, parameter :: I_Lnd_QVFLX   = 22
  integer,                private, parameter :: I_Ocn_WHFLX   = 23
  integer,                private, parameter :: I_Ocn_PRECFLX = 24
  integer,                private, parameter :: I_Ocn_QVFLX   = 25

  character(len=H_SHORT), private, save      :: VAR_NAME(VMAX) !< name  of the coupler variables
  character(len=H_MID),   private, save      :: VAR_DESC(VMAX) !< desc. of the coupler variables
  character(len=H_SHORT), private, save      :: VAR_UNIT(VMAX) !< unit  of the coupler variables

  data VAR_NAME / 'LST',         &
                  'SST',         &
                  'ALBW_SW',     &
                  'ALBW_LW',     &
                  'ALBG_SW',     &
                  'ALBG_LW',     &
                  'Z0W',         &
                  'SkinT',       &
                  'SkinW',       &
                  'SnowQ',       &
                  'SnowT',       &
                  'XMFLX',       &
                  'YMFLX',       &
                  'ZMFLX',       &
                  'SWUFLX',      &
                  'LWUFLX',      &
                  'SHFLX',       &
                  'LHFLX',       &
                  'QVFLX',       &
                  'Lnd_GHFLX',   &
                  'Lnd_PRECFLX', &
                  'Lnd_QVFLX',   &
                  'Ocn_WHFLX',   &
                  'Ocn_PRECFLX', &
                  'Ocn_QVFLX'    /

  data VAR_DESC / 'land surface temp.',               &
                  'sea surface temp.',                &
                  'sea surface albedo for SW',        &
                  'sea surface albedo for LW',        &
                  'land surface albedo for SW',       &
                  'land surface albedo for LW',       &
                  'sea surface roughness length',     &
                  'ground skin temp.',                &
                  'ground skin water',                &
                  'ground snow amount',               &
                  'ground snow temp.',                &
                  'x-momentum flux',                  &
                  'y-momentum flux',                  &
                  'z-momentum flux',                  &
                  'upward short-wave radiation flux', &
                  'upward long-wave radiation flux',  &
                  'sensible heat flux',               &
                  'latent heat flux',                 &
                  'moisture flux for atmosphere',     &
                  'ground heat flux',                 &
                  'precipitation flux for land',      &
                  'moisture flux for land',           &
                  'water heat flux',                  &
                  'precipitation flux for ocean',     &
                  'moisture flux for ocean'           /

  data VAR_UNIT / 'K',       &
                  'K',       &
                  '0-1',     &
                  '0-1',     &
                  '0-1',     &
                  '0-1',     &
                  'm',       &
                  'K',       &
                  'kg/m2',   &
                  'kg/m2',   &
                  'K',       &
                  'kg/m2/s', &
                  'kg/m2/s', &
                  'kg/m2/s', &
                  'W/m2',    &
                  'W/m2',    &
                  'W/m2',    &
                  'W/m2',    &
                  'kg/m2/s', &
                  'W/m2',    &
                  'kg/m2/s', &
                  'kg/m2/s', &
                  'W/m2',    &
                  'kg/m2/s', &
                  'kg/m2/s'  /

  !-----------------------------------------------------------------------------
contains
  !-----------------------------------------------------------------------------
  !> Setup
  subroutine CPL_vars_setup
    use scale_process, only: &
       PRC_MPIstop
    use scale_const, only: &
       NRAD => CONST_NRAD
    implicit none

    NAMELIST / PARAM_CPL / &
       CPL_do,          &
       CPL_TYPE_AtmLnd, &
       CPL_TYPE_AtmOcn, &
       CPL_LST_UPDATE,  &
       CPL_SST_UPDATE

    NAMELIST / PARAM_CPL_VARS /  &
       CPL_RESTART_IN_BASENAME,  &
       CPL_RESTART_OUTPUT,       &
       CPL_RESTART_OUT_BASENAME, &
       CPL_RESTART_OUT_TITLE,    &
       CPL_RESTART_OUT_DTYPE,    &
       CPL_VARS_CHECKRANGE

    integer :: ip, ierr
    !---------------------------------------------------------------------------

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '+++ Module[CPL VARS]/Categ[CPL]'
    !--- read namelist
    rewind(IO_FID_CONF)
    read(IO_FID_CONF,nml=PARAM_CPL,iostat=ierr)
    if( ierr < 0 ) then !--- missing
       if( IO_L ) write(IO_FID_LOG,*) '*** Not found namelist. Default used.'
    elseif( ierr > 0 ) then !--- fatal error
       write(*,*) 'xxx Not appropriate names in namelist PARAM_CPL. Check!'
       call PRC_MPIstop
    endif
    if( IO_L ) write(IO_FID_LOG,nml=PARAM_CPL)

    if( IO_L ) write(IO_FID_LOG,*) '*** [CPL] selected components'

    ! Atoms-Land Switch
    if ( CPL_TYPE_AtmLnd /= 'OFF' .AND. CPL_TYPE_AtmLnd /= 'NONE' ) then
       if( IO_L ) write(IO_FID_LOG,*) '*** Atmos-Land Coupler : ON'
       CPL_sw_AtmLnd = .true.
    else
       if( IO_L ) write(IO_FID_LOG,*) '*** Atmos-Land Coupler : OFF'
       CPL_sw_AtmLnd = .false.
    endif

    ! Atoms-Ocean Switch
    if ( CPL_TYPE_AtmOcn /= 'OFF' .AND. CPL_TYPE_AtmOcn /= 'NONE' ) then
       if( IO_L ) write(IO_FID_LOG,*) '*** Atmos-Ocean Coupler : ON'
       CPL_sw_AtmOcn = .true.
    else
       if( IO_L ) write(IO_FID_LOG,*) '*** Atmos-Ocean Coupler : OFF'
       CPL_sw_AtmOcn = .false.
    endif

    !--- read namelist
    rewind(IO_FID_CONF)
    read(IO_FID_CONF,nml=PARAM_CPL_VARS,iostat=ierr)
    if( ierr < 0 ) then !--- missing
       if( IO_L ) write(IO_FID_LOG,*) '*** Not found namelist. Default used.'
    elseif( ierr > 0 ) then !--- fatal error
       write(*,*) 'xxx Not appropriate names in namelist PARAM_CPL_VARS. Check!'
       call PRC_MPIstop
    endif
    if( IO_L ) write(IO_FID_LOG,nml=PARAM_CPL_VARS)

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '*** [CPL] prognostic variables'
    if( IO_L ) write(IO_FID_LOG,'(1x,A,A8,A,A32,3(A))') &
               '***       |',' VARNAME','|', 'DESCRIPTION                     ','[', 'UNIT            ',']'
    do ip = 1, VMAX
       if( IO_L ) write(IO_FID_LOG,'(1x,A,i3,A,A8,A,A32,3(A))') &
                  '*** NO.',ip,'|',trim(VAR_NAME(ip)),'|', VAR_DESC(ip),'[', VAR_UNIT(ip),']'
    enddo

    ! restart switch
    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) 'Output...'
    if ( CPL_RESTART_OUTPUT ) then
       if( IO_L ) write(IO_FID_LOG,*) '  Coupler restart output : YES'
       CPL_sw_restart = .true.
    else
       if( IO_L ) write(IO_FID_LOG,*) '  Coupler restart output : NO'
       CPL_sw_restart = .false.
    endif
    if( IO_L ) write(IO_FID_LOG,*)

    CNT_Atm_Lnd = 0.0_RP
    CNT_Atm_Ocn = 0.0_RP
    CNT_Lnd     = 0.0_RP
    CNT_Ocn     = 0.0_RP

    allocate( LST  (IA,JA)      )
    allocate( SST  (IA,JA)      )
    allocate( ALBW (IA,JA,NRAD) )
    allocate( ALBG (IA,JA,NRAD) )
    allocate( Z0W  (IA,JA)      )
    allocate( SkinT(IA,JA)      )
    allocate( SkinW(IA,JA)      )
    allocate( SnowQ(IA,JA)      )
    allocate( SnowT(IA,JA)      )

    allocate( XMFLX (IA,JA) )
    allocate( YMFLX (IA,JA) )
    allocate( ZMFLX (IA,JA) )
    allocate( SWUFLX(IA,JA) )
    allocate( LWUFLX(IA,JA) )
    allocate( SHFLX (IA,JA) )
    allocate( LHFLX (IA,JA) )
    allocate( QVFLX (IA,JA) )

    allocate( Lnd_GHFLX  (IA,JA) )
    allocate( Lnd_PRECFLX(IA,JA) )
    allocate( Lnd_QVFLX  (IA,JA) )

    allocate( Ocn_WHFLX  (IA,JA) )
    allocate( Ocn_PRECFLX(IA,JA) )
    allocate( Ocn_QVFLX  (IA,JA) )

    allocate( CPL_DENS(IA,JA) )
    allocate( CPL_MOMX(IA,JA) )
    allocate( CPL_MOMY(IA,JA) )
    allocate( CPL_MOMZ(IA,JA) )
    allocate( CPL_RHOS(IA,JA) )
    allocate( CPL_PRES(IA,JA) )
    allocate( CPL_TMPS(IA,JA) )
    allocate( CPL_TMPA(IA,JA) )
    allocate( CPL_QV  (IA,JA) )
    allocate( CPL_PREC(IA,JA) )
    allocate( CPL_SWD (IA,JA) )
    allocate( CPL_LWD (IA,JA) )

    allocate( CPL_TG  (IA,JA) )
    allocate( CPL_QVEF(IA,JA) )
    allocate( CPL_TCS (IA,JA) )
    allocate( CPL_DZG (IA,JA) )
    allocate( CPL_Z0M (IA,JA) )
    allocate( CPL_Z0H (IA,JA) )
    allocate( CPL_Z0E (IA,JA) )

    allocate( CPL_TW  (IA,JA) )

    allocate( AtmLnd_XMFLX (IA,JA) )
    allocate( AtmLnd_YMFLX (IA,JA) )
    allocate( AtmLnd_ZMFLX (IA,JA) )
    allocate( AtmLnd_SWUFLX(IA,JA) )
    allocate( AtmLnd_LWUFLX(IA,JA) )
    allocate( AtmLnd_SHFLX (IA,JA) )
    allocate( AtmLnd_LHFLX (IA,JA) )
    allocate( AtmLnd_QVFLX (IA,JA) )

    allocate( AtmOcn_XMFLX (IA,JA) )
    allocate( AtmOcn_YMFLX (IA,JA) )
    allocate( AtmOcn_ZMFLX (IA,JA) )
    allocate( AtmOcn_SWUFLX(IA,JA) )
    allocate( AtmOcn_LWUFLX(IA,JA) )
    allocate( AtmOcn_SHFLX (IA,JA) )
    allocate( AtmOcn_LHFLX (IA,JA) )
    allocate( AtmOcn_QVFLX (IA,JA) )

    return
  end subroutine CPL_vars_setup

  !-----------------------------------------------------------------------------
  !> fill HALO region of coupler variables
  subroutine CPL_vars_fillhalo
    use scale_const, only: &
       I_SW => CONST_I_SW, &
       I_LW => CONST_I_LW
    use scale_comm, only: &
       COMM_vars8, &
       COMM_wait
    implicit none
    !---------------------------------------------------------------------------

    ! fill IHALO & JHALO
    call COMM_vars8( LST  (:,:),       1 )
    call COMM_vars8( SST  (:,:),       2 )
    call COMM_vars8( ALBW (:,:,I_SW),  3 )
    call COMM_vars8( ALBW (:,:,I_LW),  4 )
    call COMM_vars8( ALBG (:,:,I_SW),  5 )
    call COMM_vars8( ALBG (:,:,I_LW),  6 )
    call COMM_vars8( Z0W  (:,:),       7 )
    call COMM_vars8( SkinT(:,:),       8 )
    call COMM_vars8( SkinW(:,:),       9 )
    call COMM_vars8( SnowQ(:,:),      10 )
    call COMM_vars8( SnowT(:,:),      11 )

    call COMM_wait ( LST  (:,:),       1 )
    call COMM_wait ( SST  (:,:),       2 )
    call COMM_wait ( ALBW (:,:,I_SW),  3 )
    call COMM_wait ( ALBW (:,:,I_LW),  4 )
    call COMM_wait ( ALBG (:,:,I_SW),  5 )
    call COMM_wait ( ALBG (:,:,I_LW),  6 )
    call COMM_wait ( Z0W  (:,:),       7 )
    call COMM_wait ( SkinT(:,:),       8 )
    call COMM_wait ( SkinW(:,:),       9 )
    call COMM_wait ( SnowQ(:,:),      10 )
    call COMM_wait ( SnowT(:,:),      11 )

    return
  end subroutine CPL_vars_fillhalo

  !-----------------------------------------------------------------------------
  !> Read coupler restart
  subroutine CPL_vars_restart_read
    use scale_const, only: &
       UNDEF => CONST_UNDEF, &
       I_SW  => CONST_I_SW,  &
       I_LW  => CONST_I_LW
    use scale_fileio, only: &
       FILEIO_read
    implicit none
    !---------------------------------------------------------------------------

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '*** Input restart file (coupler) ***'

    if ( CPL_RESTART_IN_BASENAME /= '' ) then

       call FILEIO_read( LST(:,:),                                        & ![OUT]
                         CPL_RESTART_IN_BASENAME, 'LST',     'XY', step=1 ) ![IN]
       call FILEIO_read( SST(:,:),                                        & ![OUT]
                         CPL_RESTART_IN_BASENAME, 'SST',     'XY', step=1 ) ![IN]
       call FILEIO_read( ALBW(:,:,I_SW),                                  & ![OUT]
                         CPL_RESTART_IN_BASENAME, 'ALBW_SW', 'XY', step=1 ) ![IN]
       call FILEIO_read( ALBW(:,:,I_LW),                                  & ![OUT]
                         CPL_RESTART_IN_BASENAME, 'ALBW_LW', 'XY', step=1 ) ![IN]
       call FILEIO_read( ALBG(:,:,I_SW),                                  & ![OUT]
                         CPL_RESTART_IN_BASENAME, 'ALBG_SW', 'XY', step=1 ) ![IN]
       call FILEIO_read( ALBG(:,:,I_LW),                                  & ![OUT]
                         CPL_RESTART_IN_BASENAME, 'ALBG_LW', 'XY', step=1 ) ![IN]
       call FILEIO_read( Z0W(:,:),                                        & ![OUT]
                         CPL_RESTART_IN_BASENAME, 'Z0W',     'XY', step=1 ) ![IN]
       call FILEIO_read( SkinT(:,:),                                      & ![OUT]
                         CPL_RESTART_IN_BASENAME, 'SkinT',   'XY', step=1 ) ![IN]
       call FILEIO_read( SkinW(:,:),                                      & ![OUT]
                         CPL_RESTART_IN_BASENAME, 'SkinW',   'XY', step=1 ) ![IN]
       call FILEIO_read( SnowQ(:,:),                                      & ![OUT]
                         CPL_RESTART_IN_BASENAME, 'SnowQ',   'XY', step=1 ) ![IN]
       call FILEIO_read( SnowT(:,:),                                      & ![OUT]
                         CPL_RESTART_IN_BASENAME, 'SnowT',   'XY', step=1 ) ![IN]

       call CPL_vars_fillhalo

       call CPL_vars_total
    else
       if( IO_L ) write(IO_FID_LOG,*) '*** restart file for coupler is not specified.'

       LST  (:,:)   = UNDEF
       SST  (:,:)   = UNDEF
       ALBW (:,:,:) = UNDEF
       ALBG (:,:,:) = UNDEF
       Z0W  (:,:)   = UNDEF
       SkinT(:,:)   = UNDEF
       SkinW(:,:)   = UNDEF
       SnowQ(:,:)   = UNDEF
       SnowT(:,:)   = UNDEF
    endif

    return
  end subroutine CPL_vars_restart_read

  !-----------------------------------------------------------------------------
  !> Write coupler restart
  subroutine CPL_vars_restart_write
    use scale_const, only: &
       I_SW => CONST_I_SW, &
       I_LW => CONST_I_LW
    use scale_time, only: &
       TIME_gettimelabel
    use scale_fileio, only: &
       FILEIO_write
    implicit none

    character(len=15)     :: timelabel
    character(len=H_LONG) :: basename

    integer :: n
    !---------------------------------------------------------------------------

    if ( CPL_RESTART_OUT_BASENAME /= '' ) then

       call TIME_gettimelabel( timelabel )
       write(basename,'(A,A,A)') trim(CPL_RESTART_OUT_BASENAME), '_', trim(timelabel)

       if( IO_L ) write(IO_FID_LOG,*)
       if( IO_L ) write(IO_FID_LOG,*) '*** Output restart file (coupler) ***'
       if( IO_L ) write(IO_FID_LOG,*) '*** filename: ', trim(basename)

       call CPL_vars_total

       call FILEIO_write( LST(:,:), basename,                                   CPL_RESTART_OUT_TITLE, & ! [IN]
                          VAR_NAME(I_LST), VAR_DESC(I_LST), VAR_UNIT(I_LST), 'XY', CPL_RESTART_OUT_DTYPE  ) ! [IN]
       call FILEIO_write( SST(:,:), basename,                                   CPL_RESTART_OUT_TITLE, & ! [IN]
                          VAR_NAME(I_SST), VAR_DESC(I_SST), VAR_UNIT(I_SST), 'XY', CPL_RESTART_OUT_DTYPE  ) ! [IN]

       call FILEIO_write( ALBW(:,:,I_SW),  basename, CPL_RESTART_OUT_TITLE,               & ! [IN]
                          VAR_NAME(I_ALBW_SW), VAR_DESC(I_ALBW_SW), VAR_UNIT(I_ALBW_SW),  & ! [IN]
                          'XY', CPL_RESTART_OUT_DTYPE, append=.true.                   ) ! [IN]
       call FILEIO_write( ALBW(:,:,I_LW),  basename, CPL_RESTART_OUT_TITLE,               & ! [IN]
                          VAR_NAME(I_ALBW_LW), VAR_DESC(I_ALBW_LW), VAR_UNIT(I_ALBW_LW),  & ! [IN]
                          'XY', CPL_RESTART_OUT_DTYPE, append=.true.                   ) ! [IN]
       call FILEIO_write( ALBG(:,:,I_SW),  basename, CPL_RESTART_OUT_TITLE,               & ! [IN]
                          VAR_NAME(I_ALBG_SW), VAR_DESC(I_ALBG_SW), VAR_UNIT(I_ALBG_SW),  & ! [IN]
                          'XY', CPL_RESTART_OUT_DTYPE, append=.true.                   ) ! [IN]
       call FILEIO_write( ALBG(:,:,I_LW),  basename, CPL_RESTART_OUT_TITLE,               & ! [IN]
                          VAR_NAME(I_ALBG_LW), VAR_DESC(I_ALBG_LW), VAR_UNIT(I_ALBG_LW),  & ! [IN]
                          'XY', CPL_RESTART_OUT_DTYPE, append=.true.                   ) ! [IN]
       call FILEIO_write( Z0W(:,:),        basename, CPL_RESTART_OUT_TITLE,               & ! [IN]
                          VAR_NAME(I_Z0W),     VAR_DESC(I_Z0W),     VAR_UNIT(I_Z0W),      & ! [IN]
                          'XY', CPL_RESTART_OUT_DTYPE, append=.true.                   ) ! [IN]
       call FILEIO_write( SkinT(:,:),      basename, CPL_RESTART_OUT_TITLE,               & ! [IN]
                          VAR_NAME(I_SkinT),   VAR_DESC(I_SkinT),   VAR_UNIT(I_SkinT),    & ! [IN]
                          'XY', CPL_RESTART_OUT_DTYPE, append=.true.                   ) ! [IN]
       call FILEIO_write( SkinW(:,:),      basename, CPL_RESTART_OUT_TITLE,               & ! [IN]
                          VAR_NAME(I_SkinW),   VAR_DESC(I_SkinW),   VAR_UNIT(I_SkinW),    & ! [IN]
                          'XY', CPL_RESTART_OUT_DTYPE, append=.true.                   ) ! [IN]
       call FILEIO_write( SnowQ(:,:),      basename, CPL_RESTART_OUT_TITLE,               & ! [IN]
                          VAR_NAME(I_SnowQ),   VAR_DESC(I_SnowQ),   VAR_UNIT(I_SnowQ),    & ! [IN]
                          'XY', CPL_RESTART_OUT_DTYPE, append=.true.                   ) ! [IN]
       call FILEIO_write( SnowT(:,:),      basename, CPL_RESTART_OUT_TITLE,               & ! [IN]
                          VAR_NAME(I_SnowT),   VAR_DESC(I_SnowT),   VAR_UNIT(I_SnowT),    & ! [IN]
                          'XY', CPL_RESTART_OUT_DTYPE, append=.true.                   ) ! [IN]

    endif

    return
  end subroutine CPL_vars_restart_write

  !-----------------------------------------------------------------------------
  !> History output set for coupler variables
  subroutine CPL_vars_history
    use scale_time, only: &
       TIME_DTSEC_CPL
    use scale_history, only: &
       HIST_in
    use scale_const, only: &
       I_SW => CONST_I_SW, &
       I_LW => CONST_I_LW
    implicit none
    !---------------------------------------------------------------------------

    if ( CPL_VARS_CHECKRANGE ) then
       call VALCHECK( LST  (:,:),      0.0_RP, 1000.0_RP, VAR_NAME(I_LST)    , __FILE__, __LINE__ )
       call VALCHECK( SST  (:,:),      0.0_RP, 1000.0_RP, VAR_NAME(I_SST)    , __FILE__, __LINE__ )
       call VALCHECK( ALBW (:,:,I_SW), 0.0_RP,    2.0_RP, VAR_NAME(I_ALBW_SW), __FILE__, __LINE__ )
       call VALCHECK( ALBW (:,:,I_LW), 0.0_RP,    2.0_RP, VAR_NAME(I_ALBW_LW), __FILE__, __LINE__ )
       call VALCHECK( ALBG (:,:,I_SW), 0.0_RP,    2.0_RP, VAR_NAME(I_ALBG_SW), __FILE__, __LINE__ )
       call VALCHECK( ALBG (:,:,I_LW), 0.0_RP,    2.0_RP, VAR_NAME(I_ALBG_LW), __FILE__, __LINE__ )
       call VALCHECK( Z0W  (:,:),      0.0_RP, 1000.0_RP, VAR_NAME(I_Z0W)    , __FILE__, __LINE__ )
       call VALCHECK( SkinT(:,:),      0.0_RP, 1000.0_RP, VAR_NAME(I_SkinT)  , __FILE__, __LINE__ )
       call VALCHECK( SkinW(:,:),      0.0_RP, 1000.0_RP, VAR_NAME(I_SkinW)  , __FILE__, __LINE__ )
       call VALCHECK( SnowQ(:,:),      0.0_RP, 1000.0_RP, VAR_NAME(I_SnowQ)  , __FILE__, __LINE__ )
       call VALCHECK( SnowT(:,:),      0.0_RP, 1000.0_RP, VAR_NAME(I_SnowT)  , __FILE__, __LINE__ )

       call VALCHECK( XMFLX (:,:), -1.0E4_RP, 1.0E4_RP, VAR_NAME(I_XMFLX) , __FILE__, __LINE__ )
       call VALCHECK( YMFLX (:,:), -1.0E4_RP, 1.0E4_RP, VAR_NAME(I_YMFLX) , __FILE__, __LINE__ )
       call VALCHECK( ZMFLX (:,:), -1.0E4_RP, 1.0E4_RP, VAR_NAME(I_ZMFLX) , __FILE__, __LINE__ )
       call VALCHECK( SWUFLX(:,:), -1.0E4_RP, 1.0E4_RP, VAR_NAME(I_SWUFLX), __FILE__, __LINE__ )
       call VALCHECK( LWUFLX(:,:), -1.0E4_RP, 1.0E4_RP, VAR_NAME(I_LWUFLX), __FILE__, __LINE__ )
       call VALCHECK( SHFLX (:,:), -1.0E4_RP, 1.0E4_RP, VAR_NAME(I_SHFLX) , __FILE__, __LINE__ )
       call VALCHECK( LHFLX (:,:), -1.0E4_RP, 1.0E4_RP, VAR_NAME(I_LHFLX) , __FILE__, __LINE__ )
       call VALCHECK( QVFLX (:,:), -1.0E4_RP, 1.0E4_RP, VAR_NAME(I_QVFLX) , __FILE__, __LINE__ )

       call VALCHECK( Lnd_GHFLX  (:,:), -1.0E4_RP, 1.0E4_RP, VAR_NAME(I_Lnd_GHFLX)  , __FILE__, __LINE__ )
       call VALCHECK( Lnd_PRECFLX(:,:), -1.0E4_RP, 1.0E4_RP, VAR_NAME(I_Lnd_PRECFLX), __FILE__, __LINE__ )
       call VALCHECK( Lnd_QVFLX  (:,:), -1.0E4_RP, 1.0E4_RP, VAR_NAME(I_Lnd_QVFLX)  , __FILE__, __LINE__ )

       call VALCHECK( Ocn_WHFLX  (:,:), -1.0E4_RP, 1.0E4_RP, VAR_NAME(I_Ocn_WHFLX)  , __FILE__, __LINE__ )
       call VALCHECK( Ocn_PRECFLX(:,:), -1.0E4_RP, 1.0E4_RP, VAR_NAME(I_Ocn_PRECFLX), __FILE__, __LINE__ )
       call VALCHECK( Ocn_QVFLX  (:,:), -1.0E4_RP, 1.0E4_RP, VAR_NAME(I_Ocn_QVFLX)  , __FILE__, __LINE__ )
    endif

    call HIST_in( LST  (:,:),      'LST',      VAR_DESC(I_LST),      VAR_UNIT(I_LST),      TIME_DTSEC_CPL )
    call HIST_in( SST  (:,:),      'SST',      VAR_DESC(I_SST),      VAR_UNIT(I_SST),      TIME_DTSEC_CPL )
    call HIST_in( ALBW (:,:,I_SW), 'ALBW_SW',  VAR_DESC(I_ALBW_SW),  VAR_UNIT(I_ALBW_SW),  TIME_DTSEC_CPL )
    call HIST_in( ALBW (:,:,I_LW), 'ALBW_LW',  VAR_DESC(I_ALBW_LW),  VAR_UNIT(I_ALBW_LW),  TIME_DTSEC_CPL )
    call HIST_in( ALBG (:,:,I_SW), 'ALBG_SW',  VAR_DESC(I_ALBG_SW),  VAR_UNIT(I_ALBG_SW),  TIME_DTSEC_CPL )
    call HIST_in( ALBG (:,:,I_LW), 'ALBG_LW',  VAR_DESC(I_ALBG_LW),  VAR_UNIT(I_ALBG_LW),  TIME_DTSEC_CPL )
    call HIST_in( Z0W  (:,:),      'Z0W',      VAR_DESC(I_Z0W),      VAR_UNIT(I_Z0W),      TIME_DTSEC_CPL )
    call HIST_in( SkinT(:,:),      'SkinT',    VAR_DESC(I_SkinT),    VAR_UNIT(I_SkinT),    TIME_DTSEC_CPL )
    call HIST_in( SkinW(:,:),      'SkinW',    VAR_DESC(I_SkinW),    VAR_UNIT(I_SkinW),    TIME_DTSEC_CPL )
    call HIST_in( SnowQ(:,:),      'SnowQ',    VAR_DESC(I_SnowQ),    VAR_UNIT(I_SnowQ),    TIME_DTSEC_CPL )
    call HIST_in( SnowT(:,:),      'SnowT',    VAR_DESC(I_SnowT),    VAR_UNIT(I_SnowT),    TIME_DTSEC_CPL )

    call HIST_in( XMFLX (:,:), 'XMFLX',  VAR_DESC(I_XMFLX),  VAR_UNIT(I_XMFLX),  TIME_DTSEC_CPL )
    call HIST_in( YMFLX (:,:), 'YMFLX',  VAR_DESC(I_YMFLX),  VAR_UNIT(I_YMFLX),  TIME_DTSEC_CPL )
    call HIST_in( ZMFLX (:,:), 'ZMFLX',  VAR_DESC(I_ZMFLX),  VAR_UNIT(I_ZMFLX),  TIME_DTSEC_CPL )
    call HIST_in( SWUFLX(:,:), 'SWUFLX', VAR_DESC(I_SWUFLX), VAR_UNIT(I_SWUFLX), TIME_DTSEC_CPL )
    call HIST_in( LWUFLX(:,:), 'LWUFLX', VAR_DESC(I_LWUFLX), VAR_UNIT(I_LWUFLX), TIME_DTSEC_CPL )
!    call HIST_in( SHFLX (:,:), 'SHFLX',  VAR_DESC(I_SHFLX),  VAR_UNIT(I_SHFLX),  TIME_DTSEC_CPL )
!    call HIST_in( LHFLX (:,:), 'LHFLX',  VAR_DESC(I_LHFLX),  VAR_UNIT(I_LHFLX),  TIME_DTSEC_CPL )
    call HIST_in( QVFLX (:,:), 'QVFLX',  VAR_DESC(I_QVFLX),  VAR_UNIT(I_QVFLX),  TIME_DTSEC_CPL )

    call HIST_in( Lnd_GHFLX  (:,:), 'Lnd_GHFLX',   VAR_DESC(I_Lnd_GHFLX),   VAR_UNIT(I_Lnd_GHFLX),   TIME_DTSEC_CPL )
    call HIST_in( Lnd_PRECFLX(:,:), 'Lnd_PRECFLX', VAR_DESC(I_Lnd_PRECFLX), VAR_UNIT(I_Lnd_PRECFLX), TIME_DTSEC_CPL )
    call HIST_in( Lnd_QVFLX  (:,:), 'Lnd_QVFLX',   VAR_DESC(I_Lnd_QVFLX),   VAR_UNIT(I_Lnd_QVFLX),   TIME_DTSEC_CPL )

    call HIST_in( Ocn_WHFLX  (:,:), 'Ocn_WHFLX',   VAR_DESC(I_Ocn_WHFLX),   VAR_UNIT(I_Ocn_WHFLX),   TIME_DTSEC_CPL )
    call HIST_in( Ocn_PRECFLX(:,:), 'Ocn_PRECFLX', VAR_DESC(I_Ocn_PRECFLX), VAR_UNIT(I_Ocn_PRECFLX), TIME_DTSEC_CPL )
    call HIST_in( Ocn_QVFLX  (:,:), 'Ocn_QVFLX',   VAR_DESC(I_Ocn_QVFLX),   VAR_UNIT(I_Ocn_QVFLX),   TIME_DTSEC_CPL )

    return
  end subroutine CPL_vars_history

  !-----------------------------------------------------------------------------
  !> Budget monitor for coupler
  subroutine CPL_vars_total
    use scale_stats, only: &
       STAT_checktotal, &
       STAT_total
    use scale_const, only: &
       I_SW => CONST_I_SW, &
       I_LW => CONST_I_LW
    implicit none

    real(RP) :: total
    !---------------------------------------------------------------------------

    if ( STAT_checktotal ) then

!       call STAT_total( total, LST(:,:),        VAR_NAME(I_LST)     )
!       call STAT_total( total, SST(:,:),        VAR_NAME(I_SST)     )
!       call STAT_total( total, ALBW(:,:,I_SW),  VAR_NAME(I_ALBW_SW) )
!       call STAT_total( total, ALBW(:,:,I_LW),  VAR_NAME(I_ALBW_LW) )
!       call STAT_total( total, ALBG(:,:,I_SW),  VAR_NAME(I_ALBG_SW) )
!       call STAT_total( total, ALBG(:,:,I_LW),  VAR_NAME(I_ALBG_LW) )
!       call STAT_total( total, Z0W(:,:),        VAR_NAME(I_Z0W)     )
!       call STAT_total( total, SkinT(:,:),      VAR_NAME(I_SkinT)   )
!       call STAT_total( total, SkinW(:,:),      VAR_NAME(I_SkinW)   )
!       call STAT_total( total, SnowQ(:,:),      VAR_NAME(I_SnowQ)   )
!       call STAT_total( total, SnowT(:,:),      VAR_NAME(I_SnowT)   )

    endif

    return
  end subroutine CPL_vars_total

  subroutine CPL_vars_merge
    use scale_landuse, only: &
      frac_land  => LANDUSE_frac_land,  &
      frac_lake  => LANDUSE_frac_lake,  &
      frac_urban => LANDUSE_frac_urban, &
      frac_PFT   => LANDUSE_frac_PFT
    implicit none
    !---------------------------------------------------------------------------

    SkinT (:,:) = ( 1.0_RP-frac_land(:,:) ) * SST          (:,:) &
                + (        frac_land(:,:) ) * LST          (:,:)

    ZMFLX (:,:) = ( 1.0_RP-frac_land(:,:) ) * AtmOcn_ZMFLX (:,:) &
                + (        frac_land(:,:) ) * AtmLnd_ZMFLX (:,:)

    XMFLX (:,:) = ( 1.0_RP-frac_land(:,:) ) * AtmOcn_XMFLX (:,:) &
                + (        frac_land(:,:) ) * AtmLnd_XMFLX (:,:)

    YMFLX (:,:) = ( 1.0_RP-frac_land(:,:) ) * AtmOcn_YMFLX (:,:) &
                + (        frac_land(:,:) ) * AtmLnd_YMFLX (:,:)

    SHFLX (:,:) = ( 1.0_RP-frac_land(:,:) ) * AtmOcn_SHFLX (:,:) &
                + (        frac_land(:,:) ) * AtmLnd_SHFLX (:,:)

    LHFLX (:,:) = ( 1.0_RP-frac_land(:,:) ) * AtmOcn_LHFLX (:,:) &
                + (        frac_land(:,:) ) * AtmLnd_LHFLX (:,:)

    QVFLX (:,:) = ( 1.0_RP-frac_land(:,:) ) * AtmOcn_QVFLX (:,:) &
                + (        frac_land(:,:) ) * AtmLnd_QVFLX (:,:)

    LWUFLX(:,:) = ( 1.0_RP-frac_land(:,:) ) * AtmOcn_LWUFLX(:,:) &
                + (        frac_land(:,:) ) * AtmLnd_LWUFLX(:,:)

    SWUFLX(:,:) = ( 1.0_RP-frac_land(:,:) ) * AtmOcn_SWUFLX(:,:) &
                + (        frac_land(:,:) ) * AtmLnd_SWUFLX(:,:)

    return
  end subroutine CPL_vars_merge

  subroutine CPL_putAtm( &
      pDENS, & ! (in)
      pMOMX, & ! (in)
      pMOMY, & ! (in)
      pMOMZ, & ! (in)
      pRHOS, & ! (in)
      pPRES, & ! (in)
      pTMPS, & ! (in)
      pTMPA, & ! (in)
      pQV,   & ! (in)
      pPREC, & ! (in)
      pSWD,  & ! (in)
      pLWD   ) ! (in)
    implicit none

    real(RP), intent(in) :: pDENS(IA,JA)
    real(RP), intent(in) :: pMOMX(IA,JA)
    real(RP), intent(in) :: pMOMY(IA,JA)
    real(RP), intent(in) :: pMOMZ(IA,JA)
    real(RP), intent(in) :: pRHOS(IA,JA)
    real(RP), intent(in) :: pPRES(IA,JA)
    real(RP), intent(in) :: pTMPS(IA,JA)
    real(RP), intent(in) :: pTMPA(IA,JA)
    real(RP), intent(in) :: pQV  (IA,JA)
    real(RP), intent(in) :: pPREC(IA,JA)
    real(RP), intent(in) :: pSWD (IA,JA)
    real(RP), intent(in) :: pLWD (IA,JA)
    !---------------------------------------------------------------------------

    CPL_DENS(:,:) = pDENS(:,:)
    CPL_MOMX(:,:) = pMOMX(:,:)
    CPL_MOMY(:,:) = pMOMY(:,:)
    CPL_MOMZ(:,:) = pMOMZ(:,:)
    CPL_RHOS(:,:) = pRHOS(:,:)
    CPL_PRES(:,:) = pPRES(:,:)
    CPL_TMPS(:,:) = pTMPS(:,:)
    CPL_TMPA(:,:) = pTMPA(:,:)
    CPL_QV  (:,:) = pQV  (:,:)
    CPL_PREC(:,:) = pPREC(:,:)
    CPL_SWD (:,:) = pSWD (:,:)
    CPL_LWD (:,:) = pLWD (:,:)

    return
  end subroutine CPL_putAtm

  subroutine CPL_putLnd( &
      pTG,   & ! (in)
      pQVEF, & ! (in)
      pTCS,  & ! (in)
      pDZG,  & ! (in)
      pZ0M,  & ! (in)
      pZ0H,  & ! (in)
      pZ0E   ) ! (in)
    implicit none

    real(RP), intent(in) :: pTG  (IA,JA)
    real(RP), intent(in) :: pQVEF(IA,JA)
    real(RP), intent(in) :: pTCS (IA,JA)
    real(RP), intent(in) :: pDZG (IA,JA)
    real(RP), intent(in) :: pZ0M (IA,JA)
    real(RP), intent(in) :: pZ0H (IA,JA)
    real(RP), intent(in) :: pZ0E (IA,JA)
    !---------------------------------------------------------------------------

    CPL_TG  (:,:) = pTG  (:,:)
    CPL_QVEF(:,:) = pQVEF(:,:)
    CPL_TCS (:,:) = pTCS (:,:)
    CPL_DZG (:,:) = pDZG (:,:)
    CPL_Z0M (:,:) = pZ0M (:,:)
    CPL_Z0H (:,:) = pZ0H (:,:)
    CPL_Z0E (:,:) = pZ0E (:,:)

    return
  end subroutine CPL_putLnd

  ! tentative
  subroutine CPL_putUrb( &
      pSWUFLX_URB, & ! (in)
      pLWUFLX_URB, & ! (in)
      pSHFLX_URB,  & ! (in)
      pLHFLX_URB,  & ! (in)
      pGHFLX_URB,  & ! (in)
      pTS_URB      ) ! (in)
    implicit none

    real(RP), intent(in) :: pSWUFLX_URB(IA,JA)
    real(RP), intent(in) :: pLWUFLX_URB(IA,JA)
    real(RP), intent(in) :: pSHFLX_URB (IA,JA)
    real(RP), intent(in) :: pLHFLX_URB (IA,JA)
    real(RP), intent(in) :: pGHFLX_URB (IA,JA)
    real(RP), intent(in) :: pTS_URB    (IA,JA)
    !---------------------------------------------------------------------------

    return
  end subroutine CPL_putUrb

  subroutine CPL_putOcn( &
      pTW ) ! (in)
    implicit none

    real(RP), intent(in) :: pTW  (IA,JA)
    !---------------------------------------------------------------------------

    CPL_TW  (:,:) = pTW  (:,:)

    return
  end subroutine CPL_putOcn

  subroutine CPL_getCPL2Atm( &
      pXMFLX,  & ! (out)
      pYMFLX,  & ! (out)
      pZMFLX,  & ! (out)
      pSWUFLX, & ! (out)
      pLWUFLX, & ! (out)
      pSHFLX,  & ! (out)
      pLHFLX,  & ! (out)
      pQVFLX   ) ! (out)
    implicit none

    real(RP), intent(out) :: pXMFLX (IA,JA)
    real(RP), intent(out) :: pYMFLX (IA,JA)
    real(RP), intent(out) :: pZMFLX (IA,JA)
    real(RP), intent(out) :: pSWUFLX(IA,JA)
    real(RP), intent(out) :: pLWUFLX(IA,JA)
    real(RP), intent(out) :: pSHFLX (IA,JA)
    real(RP), intent(out) :: pLHFLX (IA,JA)
    real(RP), intent(out) :: pQVFLX (IA,JA)
    !---------------------------------------------------------------------------

    pXMFLX (:,:) = XMFLX (:,:)
    pYMFLX (:,:) = YMFLX (:,:)
    pZMFLX (:,:) = ZMFLX (:,:)
    pSWUFLX(:,:) = SWUFLX(:,:)
    pLWUFLX(:,:) = LWUFLX(:,:)
    pSHFLX (:,:) = SHFLX (:,:)
    pLHFLX (:,:) = LHFLX (:,:)
    pQVFLX (:,:) = QVFLX (:,:)

    CNT_Atm_Lnd = 0.0_RP
    CNT_Atm_Ocn = 0.0_RP

    return
  end subroutine CPL_getCPL2Atm

  subroutine CPL_getCPL2Lnd( &
      pLnd_GHFLX,   & ! (out)
      pLnd_PRECFLX, & ! (out)
      pLnd_QVFLX    ) ! (out)
    implicit none

    real(RP), intent(out) :: pLnd_GHFLX  (IA,JA)
    real(RP), intent(out) :: pLnd_PRECFLX(IA,JA)
    real(RP), intent(out) :: pLnd_QVFLX  (IA,JA)

    pLnd_GHFLX  (:,:) = Lnd_GHFLX  (:,:)
    pLnd_PRECFLX(:,:) = Lnd_PRECFLX(:,:)
    pLnd_QVFLX  (:,:) = Lnd_QVFLX  (:,:)

    CNT_Lnd = 0.0_RP

    return
  end subroutine CPL_getCPL2Lnd

  ! tentative
  subroutine CPL_getCPL2Urb( &
      pDZ,   & ! (out)
      pDENS, & ! (out)
      pMOMX, & ! (out)
      pMOMY, & ! (out)
      pMOMZ, & ! (out)
      pTMPA, & ! (out)
      pQV,   & ! (out)
      pSWD,  & ! (out)
      pLWD,  & ! (out)
      pPREC  ) ! (out)
    use scale_grid_real, only: &
       CZ => REAL_CZ, &
       FZ => REAL_FZ
    implicit none

    real(RP), intent(out) :: pDZ  (IA,JA)
    real(RP), intent(out) :: pDENS(IA,JA)
    real(RP), intent(out) :: pMOMX(IA,JA)
    real(RP), intent(out) :: pMOMY(IA,JA)
    real(RP), intent(out) :: pMOMZ(IA,JA)
    real(RP), intent(out) :: pTMPA(IA,JA)
    real(RP), intent(out) :: pQV  (IA,JA)
    real(RP), intent(out) :: pSWD (IA,JA)
    real(RP), intent(out) :: pLWD (IA,JA)
    real(RP), intent(out) :: pPREC(IA,JA)

    pDZ  (:,:) = CZ(KS,:,:) - FZ(KS-1,:,:)
    pDENS(:,:) = CPL_DENS(:,:)
    pMOMX(:,:) = CPL_MOMX(:,:)
    pMOMY(:,:) = CPL_MOMY(:,:)
    pMOMZ(:,:) = CPL_MOMZ(:,:)
    pTMPA(:,:) = CPL_TMPA(:,:)
    pQV  (:,:) = CPL_QV  (:,:)
    pSWD (:,:) = CPL_SWD (:,:)
    pLWD (:,:) = CPL_LWD (:,:)
    pPREC(:,:) = CPL_PREC(:,:)

    return
  end subroutine CPL_getCPL2Urb

  subroutine CPL_getCPL2Ocn( &
      pOcn_WHFLX,   & ! (out)
      pOcn_PRECFLX, & ! (out)
      pOcn_QVFLX    ) ! (out)
    implicit none

    real(RP), intent(out) :: pOcn_WHFLX  (IA,JA)
    real(RP), intent(out) :: pOcn_PRECFLX(IA,JA)
    real(RP), intent(out) :: pOcn_QVFLX  (IA,JA)

    pOcn_WHFLX  (:,:) = Ocn_WHFLX  (:,:)
    pOcn_PRECFLX(:,:) = Ocn_PRECFLX(:,:)
    pOcn_QVFLX  (:,:) = Ocn_QVFLX  (:,:)

    CNT_Ocn = 0.0_RP

    return
  end subroutine CPL_getCPL2Ocn

end module mod_CPL_vars
