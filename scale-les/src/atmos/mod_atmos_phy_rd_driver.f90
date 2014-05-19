!-------------------------------------------------------------------------------
!> module ATMOSPHERE / Physics Radiation
!!
!! @par Description
!!          Atmospheric radiation transfer process driver
!!
!! @author Team SCALE
!!
!! @par History
!! @li      2013-12-06 (S.Nishizawa)  [new]
!<
!-------------------------------------------------------------------------------
#include "inc_openmp.h"
module mod_atmos_phy_rd_driver
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
  public :: ATMOS_PHY_RD_driver_setup
  public :: ATMOS_PHY_RD_driver

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
  !> Setup
  subroutine ATMOS_PHY_RD_driver_setup( RD_TYPE )
    use scale_atmos_phy_rd, only: &
       ATMOS_PHY_RD_setup
    implicit none

    character(len=H_SHORT), intent(in) :: RD_TYPE
    !---------------------------------------------------------------------------

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '+++ Module[Physics-RD]/Categ[ATMOS]'

    call ATMOS_PHY_RD_setup( RD_TYPE )

    call ATMOS_PHY_RD_driver( .true., .false. )

    return
  end subroutine ATMOS_PHY_RD_driver_setup

  !-----------------------------------------------------------------------------
  !> Driver
  subroutine ATMOS_PHY_RD_driver( update_flag, history_flag )
    use scale_grid_real, only: &
       REAL_CZ,  &
       REAL_FZ,  &
       REAL_LON, &
       REAL_LAT
    use scale_landuse, only: &
       LANDUSE_frac_land
    use scale_time, only: &
       dt_RD => TIME_DTSEC_ATMOS_PHY_RD, &
       TIME_NOWDATE
    use scale_history, only: &
       HIST_in
    use scale_atmos_solarins, only: &
       SOLARINS_insolation => ATMOS_SOLARINS_insolation
    use scale_atmos_phy_rd, only: &
       ATMOS_PHY_RD
    use scale_atmos_phy_rd_common, only: &
       RD_heating => ATMOS_PHY_RD_heating, &
       I_SW, &
       I_LW, &
       I_dn, &
       I_up
    use mod_atmos_vars, only: &
       DENS,              &
       RHOT,              &
       QTRC,              &
       RHOT_t => RHOT_tp
    use mod_cpl_vars, only: &
       CPL_sw_AtmLnd, &
       CPL_sw_AtmOcn, &
       SkinT,         &
       ALBW,          &
       ALBG
    use mod_atmos_phy_sf_vars, only: &
       SWD  => ATMOS_PHY_SF_SWD, &
       LWD  => ATMOS_PHY_SF_LWD
    use mod_atmos_phy_rd_vars, only: &
       RHOT_t_RD  => ATMOS_PHY_RD_RHOT_t,     &
       SFLX_LW_dn => ATMOS_PHY_RD_SFLX_LW_dn, &
       SFLX_SW_dn => ATMOS_PHY_RD_SFLX_SW_dn
    implicit none

    logical, intent(in) :: update_flag
    logical, intent(in) :: history_flag

    real(RP) :: TEMP_t(KA,IA,JA,3)

    real(RP) :: flux_rad(KA,IA,JA,2,2)
    real(RP) :: flux_net(KA,IA,JA,2)
    real(RP) :: flux_up (KA,IA,JA,2)
    real(RP) :: flux_dn (KA,IA,JA,2)

    real(RP) :: flux_rad_top(IA,JA,2)
    real(RP) :: flux_rad_sfc(IA,JA,2)

    real(RP) :: solins  (IA,JA)
    real(RP) :: cosSZA  (IA,JA)
    real(RP) :: temp_sfc(IA,JA)
    real(RP) :: albedo_land(IA,JA,2)

    integer :: k, i, j
    !---------------------------------------------------------------------------

    if ( update_flag ) then

       if ( CPL_sw_AtmLnd .or. CPL_sw_AtmOcn ) then ! tentative
          temp_sfc(:,:) = SkinT(:,:)
       else
          call THERMODYN_temp_pres( TEMP(:,:,:),  & ! [OUT]
                                    PRES(:,:,:),  & ! [OUT]
                                    DENS(:,:,:),  & ! [IN]
                                    RHOT(:,:,:),  & ! [IN]
                                    QTRC(:,:,:,:) ) ! [IN]

          temp_sfc(:,:) = TEMP(KS,:,:)
       endif

       if ( CPL_sw_AtmLnd ) then ! tentative
          albedo_land(:,:,I_SW) = ALBG(:,:,1)
          albedo_land(:,:,I_LW) = ALBG(:,:,2)
       elseif ( CPL_sw_AtmOcn ) then ! tentative
          albedo_land(:,:,I_SW) = ALBW(:,:,1)
          albedo_land(:,:,I_LW) = ALBW(:,:,2)
       else
          albedo_land(:,:,:) = 0.5_RP
       endif

       ! calc solar insolation
       call SOLARINS_insolation( solins  (:,:),  & ! [OUT]
                                 cosSZA  (:,:),  & ! [OUT]
                                 REAL_LON(:,:),  & ! [IN]
                                 REAL_LAT(:,:),  & ! [IN]
                                 TIME_NOWDATE(:) ) ! [IN]

       call ATMOS_PHY_RD( DENS, RHOT, QTRC,      & ! [IN]
                          REAL_CZ, REAL_FZ,      & ! [IN]
                          LANDUSE_frac_land,     & ! [IN]
                          temp_sfc, albedo_land, & ! [IN]
                          solins, cosSZA,        & ! [IN]
                          flux_rad,              & ! [OUT]
                          flux_rad_top           ) ! [OUT]

       ! apply radiative flux convergence -> heating rate
       call RD_heating( flux_rad (:,:,:,:,:), & ! [IN]
                        RHOT     (:,:,:),     & ! [IN]
                        QTRC     (:,:,:),     & ! [IN]
                        REAL_FZ  (:,:,:),     & ! [IN]
                        dt_RD,                & ! [IN]
                        TEMP_t   (:,:,:,:),   & ! [OUT]
                        RHOT_t_RD(:,:,:)      ) ! [OUT]

       do j = JS, JE
       do i = IS, IE
          SFLX_LW_dn(i,j) = flux_rad(KS-1,i,j,I_LW,I_dn)
          SFLX_SW_dn(i,j) = flux_rad(KS-1,i,j,I_SW,I_dn)
       enddo
       enddo

       if ( history_flag ) then

          call HIST_in( solins(:,:), 'SOLINS', 'solar insolation',        'W/m2', dt_RD )
          call HIST_in( cosSZA(:,:), 'COSZ',   'cos(solar zenith angle)', '0-1',  dt_RD )

          do j = JS, JE
          do i = IS, IE
          do k = KS, KE
             flux_net(k,i,j,I_LW) = 0.5_RP * ( ( flux_rad(k-1,i,j,I_LW,I_up) - flux_rad(k-1,i,j,I_LW,I_dn) ) &
                                             + ( flux_rad(k  ,i,j,I_LW,I_up) - flux_rad(k  ,i,j,I_LW,I_dn) ) )
             flux_net(k,i,j,I_SW) = 0.5_RP * ( ( flux_rad(k-1,i,j,I_SW,I_up) - flux_rad(k-1,i,j,I_SW,I_dn) ) &
                                             + ( flux_rad(k  ,i,j,I_SW,I_up) - flux_rad(k  ,i,j,I_SW,I_dn) ) )

             flux_up (k,i,j,I_LW) = 0.5_RP * ( flux_rad(k-1,i,j,I_LW,I_up) + flux_rad(k,i,j,I_LW,I_up) )
             flux_up (k,i,j,I_SW) = 0.5_RP * ( flux_rad(k-1,i,j,I_SW,I_up) + flux_rad(k,i,j,I_SW,I_up) )
             flux_dn (k,i,j,I_LW) = 0.5_RP * ( flux_rad(k-1,i,j,I_LW,I_dn) + flux_rad(k,i,j,I_LW,I_dn) )
             flux_dn (k,i,j,I_SW) = 0.5_RP * ( flux_rad(k-1,i,j,I_SW,I_dn) + flux_rad(k,i,j,I_SW,I_dn) )
          enddo
          enddo
          enddo
          call HIST_in( flux_net(:,:,:,I_LW), 'RADFLUX_LW',  'net radiation flux(LW)', 'W/m2', dt_RD )
          call HIST_in( flux_net(:,:,:,I_SW), 'RADFLUX_SW',  'net radiation flux(SW)', 'W/m2', dt_RD )
          call HIST_in( flux_up (:,:,:,I_LW), 'RADFLUX_LWUP', 'up radiation flux(LW)', 'W/m2', dt_RD )
          call HIST_in( flux_up (:,:,:,I_SW), 'RADFLUX_SWUP', 'up radiation flux(SW)', 'W/m2', dt_RD )
          call HIST_in( flux_dn (:,:,:,I_LW), 'RADFLUX_LWDN', 'dn radiation flux(LW)', 'W/m2', dt_RD )
          call HIST_in( flux_dn (:,:,:,I_SW), 'RADFLUX_SWDN', 'dn radiation flux(SW)', 'W/m2', dt_RD )

          call HIST_in( flux_rad_top(:,:,I_LW), 'OLR', 'TOA     longwave  radiation', 'W/m2', dt_RD )
          call HIST_in( flux_rad_top(:,:,I_SW), 'OSR', 'TOA     shortwave radiation', 'W/m2', dt_RD )
          do j = JS, JE
          do i = IS, IE
             flux_rad_sfc(i,j,I_LW) = flux_rad(KS-1,i,j,I_LW,I_up)-flux_rad(KS-1,i,j,I_LW,I_dn)
             flux_rad_sfc(i,j,I_SW) = flux_rad(KS-1,i,j,I_SW,I_up)-flux_rad(KS-1,i,j,I_SW,I_dn)
          enddo
          enddo
          call HIST_in( flux_rad_sfc(:,:,I_LW), 'SLR', 'Surface longwave  radiation', 'W/m2', dt_RD )
          call HIST_in( flux_rad_sfc(:,:,I_SW), 'SSR', 'Surface shortwave radiation', 'W/m2', dt_RD )

          call HIST_in( TEMP_t, 'TEMP_t_rd_LW', 'tendency of temp in rd(LW)', 'K/day', dt_RD )
          call HIST_in( TEMP_t, 'TEMP_t_rd_SW', 'tendency of temp in rd(SW)', 'K/day', dt_RD )
          call HIST_in( TEMP_t, 'TEMP_t_rd',    'tendency of temp in rd',     'K/day', dt_RD )
       endif
    endif

    do j = JS, JE
    do i = IS, IE
    do k = KS, KE
       RHOT_t(k,i,j) = RHOT_t(k,i,j) + RHOT_t_RD(k,i,j)
    enddo
    enddo
    enddo

    return
  end subroutine ATMOS_PHY_RD_driver

end module mod_atmos_phy_rd_driver
