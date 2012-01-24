!-------------------------------------------------------------------------------
!> module Atmosphere
!!
!! @par Description
!!          Atmosphere module
!!
!! @author H.Tomita and SCALE developpers
!!
!! @par History
!! @li      2011-11-11 (H.Yashiro) [new]
!! @li      2011-12-11 (H.Yashiro) [add] Boundary, Surface and Turbulence module
!!
!<
!-------------------------------------------------------------------------------
module mod_atmos
  !-----------------------------------------------------------------------------
  !
  !++ used modules
  !
  !-----------------------------------------------------------------------------
  implicit none
  private
  !-----------------------------------------------------------------------------
  !
  !++ Public procedure
  !
  public :: ATMOS_setup
  public :: ATMOS_step
  !-----------------------------------------------------------------------------
  !
  !++ Public parameters & variables
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private procedure
  !
  !-----------------------------------------------------------------------------
  !
  !++ Private parameters & variables
  !
  !-----------------------------------------------------------------------------
contains

  !-----------------------------------------------------------------------------
  !> Setup atmosphere
  !-----------------------------------------------------------------------------
  subroutine ATMOS_setup
    use mod_stdio, only: &
       IO_FID_LOG,  &
       IO_L
    use mod_atmos_vars, only: &
       ATMOS_vars_setup,  &
       ATMOS_vars_restart_read
    use mod_atmos_refstate, only: &
       ATMOS_REFSTATE_setup
    use mod_atmos_boundary, only: &
       ATMOS_BOUNDARY_setup
    use mod_atmos_dyn, only: &
       ATMOS_DYN_setup
!    use mod_atmos_phy_mp, only: &
!       ATMOS_PHY_MP_setup
    implicit none
    !---------------------------------------------------------------------------

    call ATMOS_vars_setup

    call ATMOS_vars_restart_read

    call ATMOS_REFSTATE_setup

    call ATMOS_BOUNDARY_setup

    call ATMOS_DYN_setup

!    call ATMOS_PHY_MP_setup

    return
  end subroutine ATMOS_setup

  !-----------------------------------------------------------------------------
  !> advance atmospheric state
  !-----------------------------------------------------------------------------
  subroutine ATMOS_step
    use mod_stdio, only: &
       IO_FID_LOG,  &
       IO_L
    use mod_time, only: &
       TIME_DTSEC,                       &
       TIME_DTSEC_ATMOS_DYN,             &
       TIME_DTSEC_ATMOS_PHY_TB,          &
       TIME_DTSEC_ATMOS_PHY_MP,          &
       do_dyn    => TIME_DOATMOS_DYN,    &
       do_phy_tb => TIME_DOATMOS_PHY_TB, &
       do_phy_mp => TIME_DOATMOS_PHY_MP, &
       do_phy_rd => TIME_DOATMOS_PHY_RD, &
       TIME_rapstart,                    &
       TIME_rapend
    use mod_grid, only: &
       KA   => GRID_KA,   &
       IA   => GRID_IA,   &
       JA   => GRID_JA,   &
       KS   => GRID_KS,   &
       KE   => GRID_KE,   &
       WS   => GRID_WS,   &
       WE   => GRID_WE,   &
       IS   => GRID_IS,   &
       IE   => GRID_IE,   &
       JS   => GRID_JS,   &
       JE   => GRID_JE,   &
       CDZ  => GRID_CDZ,  &
       CDX  => GRID_CDX,  &
       CDY  => GRID_CDY,  &
       RCDZ => GRID_RCDZ, &
       RCDX => GRID_RCDX, &
       RCDY => GRID_RCDY, &
       RFDX => GRID_RFDX, &
       RFDY => GRID_RFDY, &
       RFDZ => GRID_RFDZ
    use mod_atmos_vars, only: &
       var => atmos_var, &
       VA        => A_VA,            &
       QA        => A_QA,            &
       sw_dyn    => ATMOS_sw_dyn,    &
       sw_phy_tb => ATMOS_sw_phy_tb, &
       sw_phy_mp => ATMOS_sw_phy_mp, &
       sw_phy_rd => ATMOS_sw_phy_rd, &
       ATMOS_vars_get,               &
       ATMOS_vars_getdiag,           &
       ATMOS_vars_put
    use mod_atmos_refstate, only: &
       REF_dens => ATMOS_REFSTATE_dens, &
       REF_pott => ATMOS_REFSTATE_pott
    use mod_atmos_boundary, only: &
       DAMP_var   => ATMOS_BOUNDARY_var,  &
       DAMP_alpha => ATMOS_BOUNDARY_alpha
    use mod_atmos_dyn, only: &
       ATMOS_DYN
    use mod_atmos_phy_sf, only: &
       ATMOS_PHY_SF
    use mod_atmos_phy_tb, only: &
       ATMOS_PHY_TB
    use mod_history, only: &
       HIST_in
!    use mod_atmos_phy_mp, only: &
!       ATMOS_PHY_MP
!    use mod_atmos_phy_rd, only: &
!       ATMOS_PHY_RD
    implicit none

    ! prognostics
    real(8) :: dens(KA,IA,JA)      ! density     [kg/m3]
    real(8) :: momx(KA,IA,JA)      ! momentum(x) [kg/m3 * m/s]
    real(8) :: momy(KA,IA,JA)      ! momentum(y) [kg/m3 * m/s]
    real(8) :: momz(KA,IA,JA)      ! momentum(z) [kg/m3 * m/s]
    real(8) :: rhot(KA,IA,JA)      ! rho * theta [kg/m3 * K]
    real(8) :: qtrc(KA,IA,JA,QA)   ! tracer mixing ratio [kg/kg],[1/m3]

    ! diagnostics
    real(8) :: pres(KA,IA,JA)      ! pressure    [Pa]
    real(8) :: velx(KA,IA,JA)      ! velocity(x) [m/s]
    real(8) :: vely(KA,IA,JA)      ! velocity(y) [m/s]
    real(8) :: velz(KA,IA,JA)      ! velocity(z) [m/s]
    real(8) :: temp(KA,IA,JA)      ! temperature [K]
    real(8) :: pott(KA,IA,JA)      ! potential temperature [K]

    ! surface flux
    real(8) :: FLXij_sfc(IA,JA,3)  ! => FLXij(WS,1:IA,1:JA,1:3,3)
    real(8) :: FLXt_sfc (IA,JA)    ! => FLXt (WS,1:IA,1:JA)
    real(8) :: FLXqv_sfc(IA,JA)    ! => FLXq (WS,1:IA,1:JA,I_QV)

    ! tendency
    real(8) :: dens_t(KA,IA,JA)    ! density     [kg/m3]
    real(8) :: momx_t(KA,IA,JA)    ! momentum(x) [kg/m3 * m/s]
    real(8) :: momy_t(KA,IA,JA)    ! momentum(y) [kg/m3 * m/s]
    real(8) :: momz_t(KA,IA,JA)    ! momentum(z) [kg/m3 * m/s]
    real(8) :: rhot_t(KA,IA,JA)    ! rho * theta [kg/m3 * K]
    real(8) :: qtrc_t(KA,IA,JA,QA) ! tracer mixing ratio [kg/kg],[1/m3]

    ! working for atmos_dyn
    real(8) :: var_s    (KA,IA,JA,VA)  ! prognostic variables (previous step)
    real(8) :: diagvar  (KA,IA,JA,5)   ! diagnostic variables (work)
    real(8) :: dens_diff(KA,IA,JA)     ! anomary of density
    real(8) :: pott_diff(KA,IA,JA)     ! anomary of rho * pott
    real(8) :: ray_damp (KA,IA,JA,5)
    real(8) :: num_diff (KA,IA,JA,5,3)
    real(8) :: mflx_hi  (KA,IA,JA,3)   ! rho * vel(x,y,z) @ (u,v,w)-face high order
    real(8) :: mflx_lo  (KA,IA,JA,3)   ! rho * vel(x,y,z) @ (u,v,w)-face high order
    real(8) :: qflx_hi  (KA,IA,JA,3)   ! rho * vel(x,y,z) * phi @ (u,v,w)-face high order
    real(8) :: qflx_lo  (KA,IA,JA,3)   ! rho * vel(x,y,z) * phi @ (u,v,w)-face low  order
    real(8) :: qflx_anti(KA,IA,JA,3)   ! rho * vel(x,y,z) * phi @ (u,v,w)-face antidiffusive
    real(8) :: ddiv     (KA,IA,JA)     ! density divergence
    real(8) :: rjpls    (KA,IA,JA,3)   ! plus  in (x,y,z)-direction
    real(8) :: rjmns    (KA,IA,JA,3)   ! minus in (x,y,z)-direction
    !---------------------------------------------------------------------------

    !########## Dynamics ##########
    call TIME_rapstart('Dynamics')
    if ( sw_dyn .AND. do_dyn ) then
       call ATMOS_DYN( &
               var, var_s, diagvar, &
               CDZ, CDX, CDY, RCDZ, RCDX, RCDY, RFDZ, RFDX, RFDY, &
               ray_damp, DAMP_var, DAMP_alpha, &
               num_diff, dens_diff, pott_diff, REF_dens, REF_pott, &
               mflx_hi, mflx_lo, qflx_hi, qflx_lo, qflx_anti, ddiv, rjpls, rjmns, &
               KA, IA, JA, VA, QA, &
               KS, KE, WS, WE, IS, IE, JS, JE )
    endif
    call TIME_rapend  ('Dynamics')

    call TIME_rapstart('VARset')
    call ATMOS_vars_get( dens, momx, momy, momz, rhot, qtrc )
    call ATMOS_vars_getdiag( pres, velx, vely, velz, temp )
    call TIME_rapend  ('VARset')

    !########## Turbulence ##########

!    call TIME_rapstart('Turbulence')
!    if ( sw_phy_tb .AND. do_phy_tb ) then
!       momx_t(:,:,:)   = 0.D0
!       momy_t(:,:,:)   = 0.D0
!       momz_t(:,:,:)   = 0.D0
!       rhot_t(:,:,:)   = 0.D0
!       qtrc_t(:,:,:,:) = 0.D0

!       call ATMOS_PHY_SF( dens,   rhot,   qtrc,          & ! [IN]
!                          pres,   velx,   vely,   velz,  & ! [IN]
!                          FLXij_sfc, FLXt_sfc, FLXqv_sfc ) ! [OUT]

!       call ATMOS_PHY_TB( dens,   rhot,   qtrc,                  & ! [IN]
!                          velx,   vely,   velz,                  & ! [IN]
!                          FLXij_sfc, FLXt_sfc, FLXqv_sfc,        & ! [IN]
!                          momx_t, momy_t, momz_t, rhot_t, qtrc_t ) ! [OUT]

!       momx(:,:,:)   = momx(:,:,:)   + TIME_DTSEC_ATMOS_PHY_TB * momx_t(:,:,:)
!       momy(:,:,:)   = momy(:,:,:)   + TIME_DTSEC_ATMOS_PHY_TB * momy_t(:,:,:)
!       momz(:,:,:)   = momz(:,:,:)   + TIME_DTSEC_ATMOS_PHY_TB * momz_t(:,:,:)
!       rhot(:,:,:)   = rhot(:,:,:)   + TIME_DTSEC_ATMOS_PHY_TB * rhot_t(:,:,:)
!       qtrc(:,:,:,:) = qtrc(:,:,:,:) + TIME_DTSEC_ATMOS_PHY_TB * qtrc_t(:,:,:,:)

!    endif
!    call TIME_rapend  ('Turbulence')

    !########## Microphysics ##########
!    call TIME_rapstart('Microphysics')
!    if ( sw_phy_mp .AND. do_phy_mp ) then

!       call ATMOS_PHY_MP( dens,   momx,   momy,   momz,   rhot,   qtrc,  & ! [IN]
!                          dens_t, momx_t, momy_t, momz_t, rhot_t, qtrc_t ) ! [OUT]

!       dens(:,:,:)   = dens(:,:,:)   + TIME_DTSEC_ATMOS_PHY_MP * dens_t(:,:,:)
!       momx(:,:,:)   = momx(:,:,:)   + TIME_DTSEC_ATMOS_PHY_MP * momx_t(:,:,:)
!       momy(:,:,:)   = momy(:,:,:)   + TIME_DTSEC_ATMOS_PHY_MP * momy_t(:,:,:)
!       momz(:,:,:)   = momz(:,:,:)   + TIME_DTSEC_ATMOS_PHY_MP * momz_t(:,:,:)
!       rhot(:,:,:)   = rhot(:,:,:)   + TIME_DTSEC_ATMOS_PHY_MP * rhot_t(:,:,:)
!       qtrc(:,:,:,:) = qtrc(:,:,:,:) + TIME_DTSEC_ATMOS_PHY_MP * qtrc_t(:,:,:,:)

!    endif
!    call TIME_rapend  ('Microphysics')


    !########## Radiation ##########
!    call TIME_rapstart('Radiation')
!    if ( sw_phy_rd .AND. do_phy_rd ) then
!       call ATMOS_PHY_RD( dens,   momx,   momy,   momz,   rhot,   qtrc,  &
!                          rhot_t                                         )
!    endif
!    call TIME_rapend  ('Radiation')


!    call TIME_rapstart('VARset')
!    call ATMOS_vars_put   ( dens, momx, momy, momz, rhot, qtrc  ) ! [IN]
!    call TIME_rapend  ('VARset')

    call TIME_rapstart('History')
    call HIST_in( dens(:,:,:), 'DENS', 'density',     'kg/m3',   '3D', TIME_DTSEC )
    call HIST_in( momz(:,:,:), 'MOMZ', 'momentum z',  'kg/m2/s', '3D', TIME_DTSEC )
    call HIST_in( momx(:,:,:), 'MOMX', 'momentum x',  'kg/m2/s', '3D', TIME_DTSEC )
    call HIST_in( momy(:,:,:), 'MOMY', 'momentum y',  'kg/m2/s', '3D', TIME_DTSEC )
    call HIST_in( rhot(:,:,:), 'RHOT', 'rho * theta', 'kg/m3*K', '3D', TIME_DTSEC )

    pott(:,:,:) = rhot(:,:,:) / dens(:,:,:)
    call HIST_in( pott(:,:,:), 'PT',   'potential temp.', 'K', '3D', TIME_DTSEC )

    call HIST_in( pres(:,:,:), 'PRES', 'pressure',    'Pa',  '3D', TIME_DTSEC )
    call HIST_in( velz(:,:,:), 'W',    'velocity w',  'm/s', '3D', TIME_DTSEC )
    call HIST_in( velx(:,:,:), 'U',    'velocity u',  'm/s', '3D', TIME_DTSEC )
    call HIST_in( vely(:,:,:), 'V',    'velocity v',  'm/s', '3D', TIME_DTSEC )
    call HIST_in( temp(:,:,:), 'T',    'temperature', 'K',   '3D', TIME_DTSEC )
    call TIME_rapend  ('History')

    return
  end subroutine ATMOS_step

end module mod_atmos