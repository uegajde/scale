!-------------------------------------------------------------------------------
!> module ATMOSPHERE / Physics Aerosol Microphysics
!!
!! @par Description
!!          Aerosol Microphysics driver
!!
!! @author Team SCALE
!!
!! @par History
!! @li      2013-12-06 (S.Nishizawa)  [new]
!<
!-------------------------------------------------------------------------------
#include "inc_openmp.h"
module mod_atmos_phy_ae_driver
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
  public :: ATMOS_PHY_AE_driver_setup
  public :: ATMOS_PHY_AE_driver

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
  subroutine ATMOS_PHY_AE_driver_setup( AE_TYPE )
    use scale_atmos_phy_ae, only: &
       ATMOS_PHY_AE_setup
    implicit none

    character(len=H_SHORT), intent(in) :: AE_TYPE
    !---------------------------------------------------------------------------

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '+++ Module[Physics-AE]/Categ[ATMOS]'

    call ATMOS_PHY_AE_setup( AE_TYPE )

    call ATMOS_PHY_AE_driver( .true., .false. )

    return
  end subroutine ATMOS_PHY_AE_driver_setup

  !-----------------------------------------------------------------------------
  !> Driver
  subroutine ATMOS_PHY_AE_driver( update_flag, history_flag )
    use scale_time, only: &
       dt_AE => TIME_DTSEC_ATMOS_PHY_AE
    use scale_history, only: &
       HIST_in
    use scale_atmos_phy_ae, only: &
       ATMOS_PHY_AE
    use mod_atmos_vars, only: &
       DENS,              &
       MOMZ,              &
       MOMX,              &
       MOMY,              &
       RHOT,              &
       QTRC,              &
       QTRC_t => QTRC_tp
    use mod_atmos_phy_ae_vars, only: &
       QTRC_t_AE => ATMOS_PHY_AE_QTRC_t, &
       CCN       => ATMOS_PHY_AE_CCN
    implicit none

    logical, intent(in) :: update_flag
    logical, intent(in) :: history_flag

    real(RP) :: QTRC0(KA,IA,JA,QA)

    integer :: k, i, j, iq
    !---------------------------------------------------------------------------

    if ( update_flag ) then

       do iq = 1, QA
       do j  = JS, JE
       do i  = IS, IE
       do k  = KS, KE
          QTRC0(k,i,j,iq) = QTRC(k,i,j,iq) ! save
       enddo
       enddo
       enddo
       enddo

       call ATMOS_PHY_AE( DENS, & ! [IN]
                          MOMZ, & ! [IN]
                          MOMX, & ! [IN]
                          MOMY, & ! [IN]
                          RHOT, & ! [IN]
                          QTRC0 ) ! [INOUT]

       do iq = 1, QA
       do j  = JS, JE
       do i  = IS, IE
       do k  = KS, KE
          QTRC_t_AE(k,i,j,iq) = QTRC0(k,i,j,iq) - QTRC(k,i,j,iq)
       enddo
       enddo
       enddo
       enddo

       CCN(:,:,:) = 0.0_RP ! tentative

       if ( history_flag ) then
          call HIST_in( CCN(:,:,:), 'CCN', 'cloud condensation nucrei', '', dt_AE )
       endif

    endif

    !$omp parallel do private(i,j,k) OMP_SCHEDULE_ collapse(3)
    do iq = 1, QA
    do j  = JS, JE
    do i  = IS, IE
    do k  = KS, KE
       QTRC_t(k,i,j,iq) = QTRC_t(k,i,j,iq) + QTRC_t_AE(k,i,j,iq)
    enddo
    enddo
    enddo
    enddo

    return
  end subroutine ATMOS_PHY_AE_driver

end module mod_atmos_phy_ae_driver
