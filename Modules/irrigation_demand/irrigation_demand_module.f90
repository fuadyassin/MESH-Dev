module irrigation_module

    implicit none

    !*  irflg: 1 for irrigated GRU; 0 otherwise (default: 0).
    !*  thlmin: Fraction of field capacity used to determine irrigation demand (default: 0.5). [--].
    !*  t1: Start hour in day for irrigation (default: 0 -- from beginning of day). [h].
    !*  t2: Stop hour in day for irrigation (default: 24 -- to end of day). [h].
    type irrigation_parameters
        integer, dimension(:), allocatable :: irflg, t1, t2
        real, dimension(:), allocatable :: thlmin
    end type

    !*  dmnd: Calculated irrigation demand. [kg m-2 s-1].
    !*  avail: Water available for irrigation. [kg m-2 s-1].
    !*  oldpre: Diagnostic variable of precipitation before adding water for irrigation. [kg m-2 s-1].
    !*  newpre: Diagnostic variable of precipitation after adding water for irrigation. [kg m-2 s-1].
    type irrigation_variables
        real, dimension(:), allocatable :: dmnd, avail
    end type

    type irrigation_container
        type(irrigation_parameters) pm, pm_gru, pm_grid
        type(irrigation_variables) va
        logical :: PROCESS_ACTIVE = .false.
    end type

    real, dimension(:), allocatable, save :: IRDMND

    type(irrigation_container), save :: irrm

    contains

    subroutine irrigation_parameters_allocate(pm, n, ierr)

        type(irrigation_parameters) pm
        integer n, ierr

        allocate(pm%irflg(n), pm%t1(n), pm%t2(n), pm%thlmin(n), stat = ierr)
        pm%irflg = 0; pm%t1 = 0; pm%t2 = 0; pm%thlmin = 0.0

    end subroutine

    subroutine irrigation_parameters_deallocate(pm, ierr)

        type(irrigation_parameters) pm
        integer ierr

        deallocate(pm%irflg, pm%t1, pm%t2, pm%thlmin, stat = ierr)

    end subroutine

    subroutine irrigation_init(fls, shd, cm)

        use model_files_variabletypes
        use sa_mesh_shared_variables
        use climate_forcing

        type(fl_ids) :: fls
        type(ShedGridParams) :: shd
        type(clim_info) :: cm

        integer ierr

        !> Return if the irrigation module is not active.
        if (.not. irrm%PROCESS_ACTIVE) then

            !> Deallocate NNML-based parameters allocated in other parts of the code.
            call irrigation_parameters_deallocate(irrm%pm, ierr)
            return
        end if

        !> Allocate and initialize variables.
        allocate(irrm%va%dmnd(shd%lc%NML), irrm%va%avail(shd%lc%NML))
        irrm%va%dmnd = 0.0; irrm%va%avail = 0.0
        allocate(IRDMND(shd%lc%NML))

        !> Deallocate non-NML based parameters allocated in other parts of the code.
        call irrigation_parameters_deallocate(irrm%pm_grid, ierr)
        call irrigation_parameters_deallocate(irrm%pm_gru, ierr)

        !> Assign default parameterization in the case of no parameterization.
        if (all(irrm%pm%thlmin == 0.0)) irrm%pm%thlmin = 0.5
        if (all(irrm%pm%t1 == 0)) irrm%pm%t1 = 0
        if (all(irrm%pm%t2 == 0)) irrm%pm%t2 = 24

    end subroutine

    subroutine irrigation_within_tile(fls, shd, cm)

        use mpi_module
        use model_files_variabletypes
        use sa_mesh_shared_variables
        use climate_forcing

        type(fl_ids) :: fls
        type(ShedGridParams) :: shd
        type(clim_info) :: cm

        integer n, k, j
        real smin, fsmin, ir, lqsum, check
        logical iractive

        !*  MINSTG: Minimum storage to leave in the channel, not accessible for irrigation. [m3].
        !*  MINFSTG: Fraction of storage to leave in the channel, not accessible for irrigation. [--].
        real :: MINSTG = 0.0
        real :: MINFSTG = 0.05

        !> Return if the irrigation module is not active.
        if (.not. irrm%PROCESS_ACTIVE .or. ipid /= 0) return

!        if (ipid /= 0 .or. izero == 0) then
            irrm%va%avail(il1:il2) = 0.0
            do k = il1, il2 !GRU -> loop for timestep
                IRDMND(k) = 0.0   !initialization for each time step
                if (irrm%pm%irflg(k) == 1 .and. sum(stas%sl%thic(k, :)) == 0.0) then
                    iractive = (ic%now%hour >= irrm%pm%t1(k) .and. ic%now%hour < irrm%pm%t2(k))
                    if (.not. iractive) cycle
                    if (irrm%pm%t1(k) == 0 .or. (ic%now%hour == irrm%pm%t1(k) .and. ic%ts_hourly == 1)) then ! calculate at beginning of irrigation period
!                        do j = 1, shd%lc%IGND ! loop for each Soil layers
                        do j = 1, 3 ! loop for each Soil layers
                            check = irrm%pm%thlmin(k)*pm%slp%thfc(k, j) ! calculate 50% of field capacity
                            lqsum =  stas%sl%thlq(k, j)
                            if (lqsum < check)then ! check if sum of soil moisture is less than 50% of FC
                                ir = (pm%slp%thfc(k, j) - lqsum)*stas%sl%delzw(k, j) ! calculate irrigation water to field capacity for each permeable soil depth
                            else
                                ir = 0.0
                            end if
                            IRDMND(k) = IRDMND(k) + ir ! sum of complete soil depth
                        end do !soil layer
                        IRDMND(k) = IRDMND(k)*(1000.0/ic%dts) ! convert into mm/sec
                        irrm%va%dmnd(k) = IRDMND(k)
                    end if
                    irrm%va%avail(k) = max(irrm%va%dmnd(k) - cm%dat(ck%RT)%GAT(k), 0.0) ! subtract current precipitation to calculate actual requirement if there is rain
                    if (ro%RUNGRID) then
                        if (pm%tp%iabsp(k) > 0 .and. pm%tp%iabsp(k) <= fms%absp%n) then
                            n = fms%absp%meta%rnk(pm%tp%iabsp(k)) !RANK of channel to pull abstraction
                            fsmin = fms%absp%fsmin(pm%tp%iabsp(k)) ! if read from tb0 file
                            smin = fms%absp%smin(pm%tp%iabsp(k)) ! if read from tb0 file
                        else
                            n = shd%lc%ILMOS(k) ! pull from own cell if no abstraction point defined
                            fsmin = MINFSTG
                            smin = MINSTG
                        end if
                        irrm%va%avail(k) = min(max(stas_grid%chnl%s(n) - smin, 0.0)*(1.0 - fsmin)/shd%AREA(n)*1000.0/ic%dts, &
                            irrm%va%avail(k)) ! adjust to the maximum water available from channel storage (m3 to mm)
                        stas_grid%chnl%s(n) = stas_grid%chnl%s(n) - &
                            (irrm%va%avail(k)*ic%dts/1000.0)*shd%lc%ACLASS(shd%lc%ILMOS(k), shd%lc%JLMOS(k))*shd%AREA(n)
                    end if
                    cm%dat(ck%RT)%GAT(k) = cm%dat(ck%RT)%GAT(k) + irrm%va%avail(k) ! add irrigation water into precipitation
                    irrm%va%dmnd(k) = irrm%va%dmnd(k) - irrm%va%avail(k)
                end if
            end do
!        end if

    end subroutine

    subroutine irrigation_open_output(fls, shd, cm)

        use mpi_module
        use model_files_variabletypes
        use sa_mesh_shared_variables
        use climate_forcing

        type(fl_ids) :: fls
        type(ShedGridParams) :: shd
        type(clim_info) :: cm

        character(len = 200) fn
        character(len = 3) ffmti
        integer iun, l

        !> Return if the irrigation module is not active or if not the head node.
        if (.not. irrm%PROCESS_ACTIVE .or. ipid /= 0) return

        open(unit = 1981, file = './' // trim(fls%GENDIR_OUT) // '/irrigation.csv') ! open file for output
        write(1981, 1010) 'YEAR', 'DAY', 'HOUR', 'MINS', 'IRDMND', 'IRAVAI', 'IRTOT', 'OLDPRE', 'NEWPRE'
        if (fms%absp%n > 0) then
            do l = 1, fms%absp%n
                iun = 1981 + l
                write(ffmti, '(i3)') l
                fn = './' // trim(fls%GENDIR_OUT) // '/irrigation_' // trim(adjustl(ffmti)) // '.csv'
                open(unit = iun, file = fn)
                write(iun, 1010) 'YEAR', 'DAY', 'HOUR', 'MINS', 'IRDMND', 'IRAVAI', 'IRTOT', 'OLDPRE', 'NEWPRE'
            end do
        end if

1010    format(9999(g15.7e2, ','))

    end subroutine

    subroutine irrigation_write_output(fls, shd, cm)

        use mpi_module
        use model_files_variabletypes
        use sa_mesh_shared_variables
        use climate_forcing

        type(fl_ids) :: fls
        type(ShedGridParams) :: shd
        type(clim_info) :: cm

        real, dimension(:), allocatable :: SUMIRDMND, SUMIRAVAI, SUMOLDPRE, SUMNEWPRE
        integer iun, l, k

        !> Return if the irrigation module is not active or if not the head node.
        if (.not. irrm%PROCESS_ACTIVE .or. ipid /= 0) return

        !> Aggregate outputs.
        if (.not. allocated(SUMIRDMND)) allocate(SUMIRDMND(0:fms%absp%n))
        if (.not. allocated(SUMIRAVAI)) allocate(SUMIRAVAI(0:fms%absp%n))
        if (.not. allocated(SUMOLDPRE)) allocate(SUMOLDPRE(0:fms%absp%n))
        if (.not. allocated(SUMNEWPRE)) allocate(SUMNEWPRE(0:fms%absp%n))
        SUMIRDMND = 0.0; SUMIRAVAI = 0.0; SUMOLDPRE = 0.0; SUMNEWPRE = 0.0
        do k = 1, shd%lc%NML
            if (irrm%va%avail(k) > 0.0) then
                if (pm%tp%iabsp(k) > 0 .and. pm%tp%iabsp(k) <= fms%absp%n) then
                    SUMIRDMND(pm%tp%iabsp(k)) = SUMIRDMND(pm%tp%iabsp(k)) + (irrm%va%dmnd(k) + irrm%va%avail(k))*ic%dts
                    SUMIRAVAI(pm%tp%iabsp(k)) = SUMIRAVAI(pm%tp%iabsp(k)) + irrm%va%avail(k)*ic%dts
                    SUMOLDPRE(pm%tp%iabsp(k)) = SUMOLDPRE(pm%tp%iabsp(k)) + (cm%dat(ck%RT)%GAT(k) - irrm%va%avail(k))*ic%dts
                    SUMNEWPRE(pm%tp%iabsp(k)) = SUMNEWPRE(pm%tp%iabsp(k)) + cm%dat(ck%RT)%GAT(k)*ic%dts
                end if
                SUMIRDMND(0) = SUMIRDMND(0) + (irrm%va%dmnd(k) + irrm%va%avail(k))*ic%dts
                SUMIRAVAI(0) = SUMIRAVAI(0) + irrm%va%avail(k)*ic%dts
                SUMOLDPRE(0) = SUMOLDPRE(0) + (cm%dat(ck%RT)%GAT(k) - irrm%va%avail(k))*ic%dts
                SUMNEWPRE(0) = SUMNEWPRE(0) + cm%dat(ck%RT)%GAT(k)*ic%dts
            end if
        end do

        !> Write outputs.
        write(1981, 1010) &
            ic%now%year, ic%now%jday, ic%now%hour, ic%now%mins, SUMIRDMND(0), SUMIRAVAI(0), SUMIRAVAI(0), SUMOLDPRE(0), SUMNEWPRE(0)
        do l = 1, fms%absp%n
            iun = 1981 + l
            write(iun, 1010) &
                ic%now%year, ic%now%jday, ic%now%hour, ic%now%mins, &
                SUMIRDMND(l), SUMIRAVAI(l), SUMIRAVAI(l), SUMOLDPRE(l), SUMNEWPRE(l)
        end do

1010    format(9999(g15.7e2, ','))

    end subroutine

end module
