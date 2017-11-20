!-------------------------------------------------------------------------------
!> module ATMOSPHERE / Physics Chemistry
!!
!! @par Description
!!          Atmospheric chemistry driver
!!
!! @author Team SCALE
!!
!! @par History
!! @li      2014-05-04 (H.Yashiro)    [new]
!<
!-------------------------------------------------------------------------------
#include "inc_openmp.h"
module mod_atmos_phy_ch_driver
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
  public :: ATMOS_PHY_CH_driver_config
  public :: ATMOS_PHY_CH_driver_setup
  public :: ATMOS_PHY_CH_driver_resume
  public :: ATMOS_PHY_CH_driver

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
  !> Config
  subroutine ATMOS_PHY_CH_driver_config
    use scale_atmos_phy_ch, only: &
       ATMOS_PHY_CH_config
    use mod_atmos_admin, only: &
       ATMOS_PHY_CH_TYPE, &
       ATMOS_sw_phy_ch
    implicit none
    !---------------------------------------------------------------------------

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '++++++ Module[CONFIG] / Categ[ATMOS PHY_CH] / Origin[SCALE-RM]'

    if ( ATMOS_sw_phy_ch ) then
       call ATMOS_PHY_CH_config( ATMOS_PHY_CH_TYPE )
    else
       if( IO_L ) write(IO_FID_LOG,*) '*** this component is never called.'
    endif

    return
  end subroutine ATMOS_PHY_CH_driver_config

  !-----------------------------------------------------------------------------
  !> Setup
  subroutine ATMOS_PHY_CH_driver_setup
    use scale_atmos_phy_ch, only: &
       ATMOS_PHY_CH_setup
    use mod_atmos_admin, only: &
       ATMOS_PHY_CH_TYPE, &
       ATMOS_sw_phy_ch
    implicit none
    !---------------------------------------------------------------------------

    if( IO_L ) write(IO_FID_LOG,*)
    if( IO_L ) write(IO_FID_LOG,*) '++++++ Module[DRIVER] / Categ[ATMOS PHY_CH] / Origin[SCALE-RM]'

    if ( ATMOS_sw_phy_ch ) then

       ! setup library component
       call ATMOS_PHY_CH_setup

    else
       if( IO_L ) write(IO_FID_LOG,*) '*** this component is never called.'
    endif

    return
  end subroutine ATMOS_PHY_CH_driver_setup

  !-----------------------------------------------------------------------------
  !> Resume
  subroutine ATMOS_PHY_CH_driver_resume
    use mod_atmos_admin, only: &
       ATMOS_sw_phy_ch
    implicit none

    if ( ATMOS_sw_phy_ch ) then

       ! run once (only for the diagnostic value)
       call PROF_rapstart('ATM_Chemistry', 1)
       call ATMOS_PHY_CH_driver( update_flag = .true. )
       call PROF_rapend  ('ATM_Chemistry', 1)

    end if

    return
  end subroutine ATMOS_PHY_CH_driver_resume

  !-----------------------------------------------------------------------------
  !> Driver
  subroutine ATMOS_PHY_CH_driver( update_flag )
    use scale_time, only: &
       dt_CH => TIME_DTSEC_ATMOS_PHY_CH
    use scale_rm_statistics, only: &
       STATISTICS_checktotal, &
       STAT_total
    use scale_history, only: &
       HIST_in
    use scale_atmos_phy_ch, only: &
       ATMOS_PHY_CH, &
       QA_CH,        &
       QS_CH,        &
       QE_CH
    use mod_atmos_vars, only: &
       DENS   => DENS_av, &
       QTRC   => QTRC_av, &
       RHOQ_t => RHOQ_tp
    use mod_atmos_phy_ch_vars, only: &
       RHOQ_t_CH => ATMOS_PHY_CH_RHOQ_t
!       O3        => ATMOS_PHY_CH_O3
    implicit none

    logical, intent(in) :: update_flag

    real(RP) :: total ! dummy

    integer  :: k, i, j, iq
    !---------------------------------------------------------------------------

    if ( update_flag ) then

!OCL XFILL
       RHOQ_t_CH(:,:,:,:) = 0.0_RP

       call ATMOS_PHY_CH( QA_CH,              & ! [IN]
                          DENS     (:,:,:),   & ! [IN]
                          QTRC     (:,:,:,:), & ! [IN]
                          RHOQ_t_CH(:,:,:,:)  ) ! [INOUT]


       do iq = QS_CH, QE_CH
          call HIST_in( RHOQ_t_CH(:,:,:,iq), trim(TRACER_NAME(iq))//'_t_CH', &
                        'tendency rho*'//trim(TRACER_NAME(iq))//' in CH', 'kg/m3/s', nohalo=.true. )
       enddo
    endif

    do iq = QS_CH, QE_CH
       !$omp parallel do private(i,j,k) OMP_SCHEDULE_
       do j  = JS, JE
       do i  = IS, IE
       do k  = KS, KE
          RHOQ_t(k,i,j,iq) = RHOQ_t(k,i,j,iq) + RHOQ_t_CH(k,i,j,iq)
       enddo
       enddo
       enddo
    enddo

    if ( STATISTICS_checktotal ) then
       do iq = QS_CH, QE_CH
          call STAT_total( total, RHOQ_t_CH(:,:,:,iq), trim(TRACER_NAME(iq))//'_t_CH' )
       enddo
    endif

    return
  end subroutine ATMOS_PHY_CH_driver

end module mod_atmos_phy_ch_driver
