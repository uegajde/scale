!-------------------------------------------------------------------------------
!> Module forcing driver
!!
!! @par Description
!!          This module is for the artificial forcing
!!
!! @author NICAM developers, Team SCALE
!<
!-------------------------------------------------------------------------------
module mod_forcing_driver
  !-----------------------------------------------------------------------------
  !
  !++ Used modules
  !
  use scale_precision
  use scale_io
  use scale_prof
  use scale_atmos_grid_icoA_index
  use scale_tracer

  !-----------------------------------------------------------------------------
  implicit none
  private
  !-----------------------------------------------------------------------------
  !
  !++ Public procedure
  !
  public :: forcing_setup
  public :: forcing_step
  public :: forcing_update

  !-----------------------------------------------------------------------------
  !
  !++ Public parameters & variables
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private procedures
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private parameters & variables
  !
  integer, private, parameter :: nmax_TEND     = 7
  integer, private, parameter :: nmax_PROG     = 6
  integer, private, parameter :: nmax_v_mean_c = 5

  integer, private, parameter :: I_RHOG     = 1 ! Density x G^1/2 x gamma^2
  integer, private, parameter :: I_RHOGVX   = 2 ! Density x G^1/2 x gamma^2 x Horizontal velocity (X-direction)
  integer, private, parameter :: I_RHOGVY   = 3 ! Density x G^1/2 x gamma^2 x Horizontal velocity (Y-direction)
  integer, private, parameter :: I_RHOGVZ   = 4 ! Density x G^1/2 x gamma^2 x Horizontal velocity (Z-direction)
  integer, private, parameter :: I_RHOGW    = 5 ! Density x G^1/2 x gamma^2 x Vertical   velocity
  integer, private, parameter :: I_RHOGE    = 6 ! Density x G^1/2 x gamma^2 x Internal Energy
  integer, private, parameter :: I_RHOGETOT = 7 ! Density x G^1/2 x gamma^2 x Total Energy

  logical, private            :: NEGATIVE_FIXER  = .false.
  logical, private            :: UPDATE_TOT_DENS = .true.

  !-----------------------------------------------------------------------------
contains
  !-----------------------------------------------------------------------------
  subroutine forcing_setup
    use scale_prc, only: &
       PRC_abort
    use mod_runconf, only: &
       AF_TYPE
    use mod_af_heldsuarez, only: &
       AF_heldsuarez_init
    use mod_af_dcmip, only: &
       AF_dcmip_init
    implicit none

    namelist /FORCING_PARAM/ &
       NEGATIVE_FIXER,       &
       UPDATE_TOT_DENS

    integer :: ierr
    !---------------------------------------------------------------------------

    !--- read parameters
    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '+++ Module[forcing]/Category[nhm]'
    rewind(IO_FID_CONF)
    read(IO_FID_CONF,nml=FORCING_PARAM,iostat=ierr)
    if ( ierr < 0 ) then
       if( IO_L ) write(IO_FID_LOG,*) '*** FORCING_PARAM is not specified. use default.'
    elseif( ierr > 0 ) then
       write(*,*) 'xxx Not appropriate names in namelist FORCING_PARAM. STOP.'
       call PRC_abort
    endif
    if( IO_NML ) write(IO_FID_NML,nml=FORCING_PARAM)

    if( IO_L ) write(IO_FID_LOG,*) '+++ Artificial forcing type: ', trim(AF_TYPE)
    select case(AF_TYPE)
    case('NONE')
       !--- do nothing
    case('HELD-SUAREZ')
       call AF_heldsuarez_init( moist_case = .false. )
    case('DCMIP')
       call AF_dcmip_init
    case default
       write(*,*) 'xxx unsupported forcing type! STOP.'
       call PRC_abort
    end select

    return
  end subroutine forcing_setup

  !-----------------------------------------------------------------------------
  subroutine forcing_step
    use scale_const, only: &
       GRAV => CONST_GRAV
    use mod_grd, only: &
       GRD_LAT,  &
       GRD_LON,  &
       GRD_s,    &
       GRD_zs,   &
       GRD_ZSFC, &
       GRD_vz,   &
       GRD_Z,    &
       GRD_ZH
    use mod_gmtr, only: &
       GMTR_p, &
       GMTR_p_IX,  &
       GMTR_p_IY,  &
       GMTR_p_IZ,  &
       GMTR_p_JX,  &
       GMTR_p_JY,  &
       GMTR_p_JZ
    use mod_vmtr, only: &
       VMTR_getin_GSGAM2,  &
       VMTR_getin_GSGAM2H, &
       VMTR_getin_PHI
    use mod_time, only: &
       TIME_DTL
    use mod_gtl, only: &
       GTL_clip_region, &
       GTL_clip_region_1layer
    use mod_runconf, only: &
       AF_TYPE
    use mod_prgvar, only: &
       prgvar_get_in_withdiag, &
       prgvar_set_in
    use mod_atmos_phy_sf_vars, only: &
       SFC_TEMP   => ATMOS_PHY_SF_SFC_TEMP
    use mod_bndcnd, only: &
       BNDCND_thermo, &
       TEM_sfc
    use mod_history, only: &
       history_in
    use mod_af_heldsuarez, only: &
       AF_heldsuarez
    use mod_af_dcmip, only: &
       AF_dcmip
    use mod_grd_conversion, only: &
       grd_gm2rm
    use mod_runconf, only: &
       ATMOS_PHY_TYPE
    use mod_grd_conversion, only: &
       grd_gm2rm
    implicit none

    real(RP) :: rhog  (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: rhogvx(ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: rhogvy(ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: rhogvz(ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: rhogw (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: rhoge (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: rhogq (ADM_gall_in,ADM_kall,ADM_lall,QA)
    real(RP) :: rho   (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: pre   (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: tem   (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: vx    (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: vy    (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: vz    (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: w     (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: q     (ADM_gall_in,ADM_kall,ADM_lall,QA)
    real(RP) :: ein   (ADM_gall_in,ADM_kall,ADM_lall)

    real(RP) :: pre_srf(ADM_gall_in,ADM_lall)

    ! forcing tendency
    real(RP) :: fvx(ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: fvy(ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: fvz(ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: fw (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: fe (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: fq (ADM_gall_in,ADM_kall,ADM_lall,QA)
    real(RP) :: frho(ADM_gall_in,ADM_kall,ADM_lall)

    real(RP) :: tmp (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: precip(ADM_gall_in,ADM_KNONE,ADM_lall)

    ! geometry, coordinate
    real(RP) :: gsgam2 (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: gsgam2h(ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: phi    (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: z      (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: zh     (ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: z_srf  (ADM_gall_in,ADM_lall)
    real(RP) :: lat    (ADM_gall_in,ADM_lall)
    real(RP) :: lon    (ADM_gall_in,ADM_lall)
    real(RP) :: ix     (ADM_gall_in,ADM_lall)
    real(RP) :: iy     (ADM_gall_in,ADM_lall)
    real(RP) :: iz     (ADM_gall_in,ADM_lall)
    real(RP) :: jx     (ADM_gall_in,ADM_lall)
    real(RP) :: jy     (ADM_gall_in,ADM_lall)
    real(RP) :: jz     (ADM_gall_in,ADM_lall)
    real(RP) :: Tsfc   (ADM_gall_in,ADM_knone,ADM_lall)

    real(RP) :: frhogq(ADM_gall_in,ADM_kall,ADM_lall)
    real(RP) :: z_srf_rmgrid(IA,JA)

    character(len=H_SHORT) :: varname

    integer :: i, j, k, l, nq, k0, ij, ij2
    !---------------------------------------------------------------------------

    call PROF_rapstart('__Forcing',1)

    ! forcing
    if ( AF_TYPE=='HELD-SUAREZ' ) then

       do l = 1, ADM_lall
          call AF_heldsuarez( ADM_gall_in,  & ! [IN]
                              lat(:,l),     & ! [IN]
                              pre(:,:,l),   & ! [IN]
                              tem(:,:,l),   & ! [IN]
                              vx (:,:,l),   & ! [IN]
                              vy (:,:,l),   & ! [IN]
                              vz (:,:,l),   & ! [IN]
                              fvx(:,:,l),   & ! [OUT]
                              fvy(:,:,l),   & ! [OUT]
                              fvz(:,:,l),   & ! [OUT]
                              fe (:,:,l)    ) ! [OUT]

          call history_in( 'ml_af_fvx', fvx(:,:,l) )
          call history_in( 'ml_af_fvy', fvy(:,:,l) )
          call history_in( 'ml_af_fvz', fvz(:,:,l) )
          call history_in( 'ml_af_fe',  fe (:,:,l) )
       enddo
       fw(:,:,:)   = 0.0_RP
       fq(:,:,:,:) = 0.0_RP
       frho(:,:,:) = 0.0_RP
    endif

    select case( ATMOS_PHY_TYPE )
    case( 'SIMPLE' )

       fw (:,:,:)   = 0.0_RP
       frho(:,:,:)  = 0.0_RP

       do l = 1, ADM_lall
          call AF_dcmip( ADM_gall_in,      & ! [IN]
                         lat    (:,l),     & ! [IN]
                         lon    (:,l),     & ! [IN]
                         z      (:,:,l),   & ! [IN]
                         zh     (:,:,l),   & ! [IN]
                         rho    (:,:,l),   & ! [IN]
                         pre    (:,:,l),   & ! [IN]
                         tem    (:,:,l),   & ! [IN]
                         vx     (:,:,l),   & ! [IN]
                         vy     (:,:,l),   & ! [IN]
                         vz     (:,:,l),   & ! [IN]
                         q      (:,:,l,:), & ! [IN]
                         ein    (:,:,l),   & ! [IN]
                         pre_srf(:,l),     & ! [IN]
                         Tsfc   (:,k0,l),  & ! [IN]
                         fvx    (:,:,l),   & ! [OUT]
                         fvy    (:,:,l),   & ! [OUT]
                         fvz    (:,:,l),   & ! [OUT]
                         fe     (:,:,l),   & ! [OUT]
                         fq     (:,:,l,:), & ! [OUT]
                         precip (:,k0,l),  & ! [OUT]
                         ix     (:,l),     & ! [IN]
                         iy     (:,l),     & ! [IN]
                         iz     (:,l),     & ! [IN]
                         jx     (:,l),     & ! [IN]
                         jy     (:,l),     & ! [IN]
                         jz     (:,l),     & ! [IN]
                         TIME_DTL          ) ! [IN]

          call history_in( 'ml_af_fvx', fvx (:,:,l) )
          call history_in( 'ml_af_fvy', fvy (:,:,l) )
          call history_in( 'ml_af_fvz', fvz (:,:,l) )
          call history_in( 'ml_af_fw',  fw  (:,:,l) )
          call history_in( 'ml_af_fe',  fe  (:,:,l) )
          call history_in( 'ml_af_frho',  frho(:,:,l) )

          do nq = 1, QA
             write(varname,'(A,I2.2)') 'ml_af_fq', nq

             call history_in( varname, fq(:,:,l,nq) )
          enddo

          call history_in( 'sl_af_prcp', precip(:,:,l) )
       enddo

    case ('NONE')

       frho(:,:,:)  = 0.0_RP
       fvx(:,:,:)   = 0.0_RP
       fvy(:,:,:)   = 0.0_RP
       fvz(:,:,:)   = 0.0_RP
       fw (:,:,:)   = 0.0_RP
       fe (:,:,:)   = 0.0_RP
       fq (:,:,:,:) = 0.0_RP

    end select

    do l=1, ADM_lall
       call history_in( 'sl_sst', Tsfc(:,:,l) )
    enddo

    call VMTR_getin_GSGAM2 ( gsgam2  )
    call VMTR_getin_GSGAM2H( gsgam2h )

    rhogvx(:,:,:) = rhogvx(:,:,:) + TIME_DTL * fvx(:,:,:) * rho(:,:,:) * GSGAM2 (:,:,:)
    rhogvy(:,:,:) = rhogvy(:,:,:) + TIME_DTL * fvy(:,:,:) * rho(:,:,:) * GSGAM2 (:,:,:)
    rhogvz(:,:,:) = rhogvz(:,:,:) + TIME_DTL * fvz(:,:,:) * rho(:,:,:) * GSGAM2 (:,:,:)
    rhogw (:,:,:) = rhogw (:,:,:) + TIME_DTL * fw (:,:,:) * rho(:,:,:) * GSGAM2H(:,:,:)
    rhoge (:,:,:) = rhoge (:,:,:) + TIME_DTL * fe (:,:,:) * rho(:,:,:) * GSGAM2 (:,:,:)

    if ( UPDATE_TOT_DENS ) rhog (:,:,:) = rhog (:,:,:) + TIME_DTL * frho(:,:,:) * GSGAM2 (:,:,:)

    do nq = 1, QA
       frhogq(:,:,:) = fq(:,:,:,nq) * rho(:,:,:) * GSGAM2(:,:,:) &
            + q(:,:,:,nq) * frho(:,:,:) * GSGAM2(:,:,:)
          
       if ( NEGATIVE_FIXER ) then
          tmp   (:,:,:)    = max( rhogq(:,:,:,nq) + TIME_DTL * frhogq(:,:,:), 0.0_DP )
          frhogq(:,:,:)    = ( tmp(:,:,:) - rhogq(:,:,:,nq) ) / TIME_DTL
          rhogq (:,:,:,nq) = tmp(:,:,:)
       else
          rhogq(:,:,:,nq) = rhogq(:,:,:,nq) + TIME_DTL * frhogq(:,:,:)
       endif

       if ( UPDATE_TOT_DENS ) then
          if ( TRACER_MASS(nq) > 0.0_RP ) then ! update total density
             rhog (:,:,:) = rhog (:,:,:) + TIME_DTL * frhogq(:,:,:)
          endif
       endif
    enddo

    !--- set the prognostic variables
    call prgvar_set_in( rhog,   & ! [IN]
                        rhogvx, & ! [IN]
                        rhogvy, & ! [IN]
                        rhogvz, & ! [IN]
                        rhogw,  & ! [IN]
                        rhoge,  & ! [IN]
                        rhogq   ) ! [IN]

    call PROF_rapend  ('__Forcing',1)

    return
  end subroutine forcing_step
  
  !-----------------------------------------------------------------------------
  ! [add; original by H.Miura] 20130613 R.Yoshida
  subroutine forcing_update( &
       PROG, PROG_pl )
    use mod_adm, only: &
       ADM_have_pl
    use mod_grd, only: &
       GRD_LAT,  &
       GRD_LON,  &
       GRD_s,    &
       GRD_s_pl, &
       GRD_Z,    &
       GRD_ZH,   &
       GRD_vz,   &
       GRD_vz_pl
    use mod_time, only: &
       TIME_DTL
    use mod_af_trcadv, only: & ![add] 20130612 R.Yoshida
       test11_velocity, &
       test12_velocity
    use mod_ideal_init, only: &
       DCTEST_type, &
       DCTEST_case
    implicit none

    real(RP), intent(inout) :: PROG    (ADM_gall   ,ADM_kall,ADM_lall   ,nmax_PROG) ! prognostic variables
    real(RP), intent(inout) :: PROG_pl (ADM_gall_pl,ADM_kall,ADM_lall_pl,nmax_PROG)

    real(RP) :: vx     (ADM_gall   ,ADM_kall,ADM_lall   ) ! horizontal velocity_x
    real(RP) :: vx_pl  (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: vy     (ADM_gall   ,ADM_kall,ADM_lall   ) ! horizontal velocity_y
    real(RP) :: vy_pl  (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: vz     (ADM_gall   ,ADM_kall,ADM_lall   ) ! horizontal velocity_z
    real(RP) :: vz_pl  (ADM_gall_pl,ADM_kall,ADM_lall_pl)
    real(RP) :: w      (ADM_gall   ,ADM_kall,ADM_lall   ) ! vertical velocity
    real(RP) :: w_pl   (ADM_gall_pl,ADM_kall,ADM_lall_pl)

    real(RP), save :: time = 0.0_RP ! for tracer advection test [add; original by H.Miura] 20130612 R.Yoshida

    integer :: n, k ,l, k0
    !---------------------------------------------------------------------------

    call PROF_rapstart('__Forcing',1)

    k0 = ADM_KNONE

    !--- update velocity
    time = time + TIME_DTL

    if ( DCTEST_type == 'Traceradvection' .AND. DCTEST_case == '1-1' ) then

       do l = 1, ADM_lall
       do k = 1, ADM_kall
       do n = 1, ADM_gall
          ! full (1): u,v
          ! half (2): w
          call test11_velocity( time,                   & ! [IN]
                                GRD_s (n,k0,l,GRD_LON), & ! [IN]
                                GRD_s (n,k0,l,GRD_LAT), & ! [IN]
                                GRD_vz(n,k,l,GRD_Z ),   & ! [IN]
                                GRD_vz(n,k,l,GRD_ZH),   & ! [IN]
                                vx    (n,k,l),          & ! [OUT]
                                vy    (n,k,l),          & ! [OUT]
                                vz    (n,k,l),          & ! [OUT]
                                w     (n,k,l)           ) ! [OUT]
       enddo
       enddo
       enddo

       if ( ADM_have_pl ) then
          do l = 1, ADM_lall_pl
          do k = 1, ADM_kall
          do n = 1, ADM_gall_pl
             call test11_velocity( time,                      & ! [IN]
                                   GRD_s_pl (n,k0,l,GRD_LON), & ! [IN]
                                   GRD_s_pl (n,k0,l,GRD_LAT), & ! [IN]
                                   GRD_vz_pl(n,k,l,GRD_Z ),   & ! [IN]
                                   GRD_vz_pl(n,k,l,GRD_ZH),   & ! [IN]
                                   vx_pl    (n,k,l),          & ! [OUT]
                                   vy_pl    (n,k,l),          & ! [OUT]
                                   vz_pl    (n,k,l),          & ! [OUT]
                                   w_pl     (n,k,l)           ) ! [OUT]
          enddo
          enddo
          enddo
       endif

    elseif( DCTEST_type == 'Traceradvection' .AND. DCTEST_case == '1-2' ) then

       do l = 1, ADM_lall
       do k = 1, ADM_kall
       do n = 1, ADM_gall
          ! full (1): u,v
          ! half (2): w
          call test12_velocity( time,                   & ! [IN]
                                GRD_s (n,k0,l,GRD_LON), & ! [IN]
                                GRD_s (n,k0,l,GRD_LAT), & ! [IN]
                                GRD_vz(n,k,l,GRD_Z ),   & ! [IN]
                                GRD_vz(n,k,l,GRD_ZH),   & ! [IN]
                                vx    (n,k,l),          & ! [OUT]
                                vy    (n,k,l),          & ! [OUT]
                                vz    (n,k,l),          & ! [OUT]
                                w     (n,k,l)           ) ! [OUT]
       enddo
       enddo
       enddo

       if ( ADM_have_pl ) then
          do l = 1, ADM_lall_pl
          do k = 1, ADM_kall
          do n = 1, ADM_gall_pl
             call test12_velocity( time,                      & ! [IN]
                                   GRD_s_pl (n,k0,l,GRD_LON), & ! [IN]
                                   GRD_s_pl (n,k0,l,GRD_LAT), & ! [IN]
                                   GRD_vz_pl(n,k,l,GRD_Z ),   & ! [IN]
                                   GRD_vz_pl(n,k,l,GRD_ZH),   & ! [IN]
                                   vx_pl    (n,k,l),          & ! [OUT]
                                   vy_pl    (n,k,l),          & ! [OUT]
                                   vz_pl    (n,k,l),          & ! [OUT]
                                   w_pl     (n,k,l)           ) ! [OUT]
          enddo
          enddo
          enddo
       endif

    endif

    PROG(:,:,:,I_RHOGVX) = vx(:,:,:) * PROG(:,:,:,I_RHOG)
    PROG(:,:,:,I_RHOGVY) = vy(:,:,:) * PROG(:,:,:,I_RHOG)
    PROG(:,:,:,I_RHOGVZ) = vz(:,:,:) * PROG(:,:,:,I_RHOG)
    PROG(:,:,:,I_RHOGW ) = w (:,:,:) * PROG(:,:,:,I_RHOG)

    if ( ADM_have_pl ) then
       PROG_pl(:,:,:,I_RHOGVX) = vx_pl(:,:,:) * PROG_pl(:,:,:,I_RHOG)
       PROG_pl(:,:,:,I_RHOGVY) = vy_pl(:,:,:) * PROG_pl(:,:,:,I_RHOG)
       PROG_pl(:,:,:,I_RHOGVZ) = vz_pl(:,:,:) * PROG_pl(:,:,:,I_RHOG)
       PROG_pl(:,:,:,I_RHOGW ) = w_pl (:,:,:) * PROG_pl(:,:,:,I_RHOG)
    endif

    call PROF_rapend  ('__Forcing',1)

    return
  end subroutine forcing_update

end module mod_forcing_driver
