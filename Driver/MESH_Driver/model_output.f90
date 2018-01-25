module model_output

    use sa_mesh_shared_variables
    use model_dates
    use model_files_variables

    implicit none

    real, allocatable :: TBAR_dly(:, :, :), ALD_dly(:, :), TMAX_ann(:, :, :), TMIN_ann(:, :, :), ALD_ann(:, :), ZOD_ann(:, :, :)
    real, allocatable :: ZOD_TTOL(:)

    !> Description:
    !>  Data type for output file information for a specific format.
    !>
    !> Variables:
    !*  active: .true. if the file is active (default: .false.).
    !*  iun: Unit of the file (must be unique; default: -1).
    !*  path: Path or file name (default: none).
    type output_file_format
        logical :: active = .false.
        integer :: iun = -1
        character(len = 1000) :: path = ''
    end type

    !> Description:
    !>  Data type for output file format information.
    !>
    !> Variables:
    !*  active: .true. if output is active (default: .false.).
    !*  delim: Field delimiter in supported formats (default: space-delimited).
    !*  print_date: Option to print the leading date stamp in supported formats (default: .false.).
    !*  order: Print order of elements in the field in supported formats (default: 'gridorder').
    !*  grids, tiles, grus: Indices of the specific grids/tiles/GRUs for output in supported formats (text format).
    !*  dat: Output data (1: Tile or grid index; 2: Index in series).
    !*  seq, r2c, txt, csv: File information for outputs in various formats.
    type output_file
        logical :: active = .false.
        character(len = 20) :: delim = '', order = 'unknown'
        logical :: print_date = .false.
        integer, dimension(:), allocatable :: grids, tiles, grus
        real, dimension(:, :), allocatable :: dat
        type(output_file_format) seq, r2c, txt, csv
    end type

    !> Description:
    !>  Data type for storing series of output.
    !>
    !> Variables:
    !*  apply_frac: .true. to multiply grid values by fractional area of cell (default: .false.).
    !*  y, m, s, d, h, ts: Output files of the variable at various time intervals.
    type output_series
        logical :: apply_frac = .false.
        type(output_file) y, m, s, d, h, ts
    end type

    !> Description:
    !>  Data type for storing series of dates.
    !>
    !> Variables:
    !*  y, m, s, d, h, ts: Arrays of dates at various time intervals.
    type output_dates
        integer, dimension(:, :), allocatable :: y, m, s, d, h
        integer, dimension(:), allocatable :: ts
    end type

    !> Description:
    !>  Data type for storing series for output.
    !>
    !> Variables:
    !*  dates: Array to store frame count and date (1: Frame count and date; 2: Index in series).
    !*  iun: Base file unit (increments as fields are activated for output).
    !*  in_mem: .true. to store in memory; .false. to write output continuously during the run (default: .false.).
    type output_series_container
        type(output_dates) dates
        integer :: iun = 882100
        logical :: in_mem = .false.
        type(output_series) &
            pre, fsin, fsvh, fsih, fsdr, fsdf, flin, ta, qa, pres, uu, vv, uv, wdir, &
            prec, gro, evap, pevp, evpb, arrd, rof, rofo, rofs, rofb, &
            rcan, sncan, sno, fsno, wsno, zpnd, pndw, lzs, dzs, stgw, &
            cmas, tcan, tsno, tpnd, &
            alvs, alir, albt, fsout, flout, gte, qh, qe, gzero, stge, &
            ald, zod, &
            rff, rchg, qi, stgch, qo, zlvl
        type(output_series), dimension(:), allocatable :: &
            thlq, lqws, thic, fzws, alws, &
            gflx, tbar, tmax, tmin
    end type

    !*  flds: Instance of series for output.
    type(output_series_container), save :: flds

    contains

!>>>>temporarily_here
    !> Description:
    !>  Open an existing text or CSV format file for input (the routine
    !>  implements the 'read' action). Stop the program if the routine
    !>  fails.
    subroutine open_txt_input(iun, fname, verbose, ierr)

        !> Input variables.
        !*  iun: Unit of the file (stream persists).
        !*  fname: Name of the file.
        !*  verbose: .true. to print messages to the screen.
        integer, intent(in) :: iun
        character(len = *), intent(in) :: fname
        logical, intent(in) :: verbose

        !> Output variables.
        !*  ierr: Returns '0' if the routine is successful; program stops otherwise.
        integer, intent(out) :: ierr

        !> Open the file.
        !> Print status to the screen if verbose.
        if (verbose) print 1000, trim(fname)
        open(iun, file = adjustl(fname), status = 'old', action = 'read', iostat = ierr)
        if (ierr /= 0) goto 999

        !> Return if the file successfully opened.
        return

        !> Stop if the routine failed.
999     if (verbose) print 1110, trim(fname)
        stop

1000    format(1x, 'READING: ', (a))
1110    format(/1x, 'ERROR: Error opening ', (a), &
               /3x, 'Check that the file exists or use an alternate format of file.'/)

    end subroutine

    !> Description:
    !>  Return the first line of data from a text or CSV format file.
    !>  The routine skips lines that lead with '#' or '!', and clip the
    !>  line to the first instance of '#' or '!' if one exists. The
    !>  returned line is de-tabbed and compacted of excess whitespace.
    subroutine read_txt_line(iun, line, ierr)

        !> Required for the 'compact' function.
        use strings

        !> Input variables.
        !*  iun: Unit of the file (of persistent stream).
        integer, intent(in) :: iun

        !> Output variables.
        !*  line: First data line read from file.
        !*  ierr: Returns '0' if the routine is successful.
        character(len = *), intent(out) :: line
        integer, intent(out) :: ierr

        !> Loop until the first line of data is read.
        !> Skip blank lines and lines that lead with '#' or '!'.
        !> Clip the line to the first instance of '#' or '!' if one exists.
        line = ''
        do while (ierr == 0)
            read(iun, '(a)', iostat = ierr) line
            if (ierr /= 0) exit
            if (len_trim(line) == 0) cycle
            if (line(1:1) == '#' .or. line(1:1) == '!') cycle
            if (index(line, '#') > 2) line = line(1:index(line, '#') - 1)
            if (index(line, '!') > 2) line = line(1:index(line, '!') - 1)
            call compact(line)
            if (len_trim(line) > 0) exit
        end do

        !> Return when a line that satisfies the constraints is read.
        return

    end subroutine
!<<<<<temporarily_here

    subroutine output_file_parse_indices(shd, file, args, nargs, indices, startindex, ierr)

        !> Required for 'is_letter' and 'value' functions.
        use strings

        !> Input/output variables.
        type(ShedGridParams), intent(in) :: shd
        type(output_file) file

        !> Input variables.
        character(len = *), dimension(:), intent(in) :: args
        integer, intent(in) :: nargs, startindex

        !> Output variables.
        integer, dimension(:), allocatable, intent(out) :: indices
        integer, intent(out) :: ierr

        !> Local variables.
        integer n, j

        !> Count the number of indices.
        n = 0
        do j = startindex + 1, nargs
            if (is_letter(args(j))) exit
            n = n + 1
        end do

        !> Allocate the vector and store the indices.
        ierr = 0
        if (n > 0) then
            allocate(indices(n))
            do j = 1, n
                call value(args(startindex + j), indices(j), ierr)
            end do
        end if

    end subroutine

    subroutine output_file_parse_options(shd, file, t, args, nargs)

        !> Required for 'is_letter', 'lowercase', and 'value' functions.
        use strings

        !> Input/output variables.
        type(ShedGridParams), intent(in) :: shd
        type(output_file) file

        !> Input variables.
        integer, intent(in) :: t, nargs
        character(len = *), dimension(:), intent(in) :: args

        !> Local variables.
        integer n, j, i, ierr
        character(len = len(args)) opts

        !> Mark the field as active.
        file%active = .true.

        !> Condition output based on 'args' flags.
        do i = 2, nargs
            if (is_letter(args(i))) then
                opts = lowercase(args(i))
                select case (opts)

                    !> Already read; skip to avoid 'REMARK' below.
                    case ('y', 'm', 's', 'd', 'h', 'ts')
                        cycle

                    !> Generic output formats.
                    case ('r2c')
                        file%r2c%active = .true.
                        flds%iun = flds%iun + 1
                        file%r2c%iun = flds%iun
                    case ('seq', 'binseq')
                        file%seq%active = .true.
                        flds%iun = flds%iun + 1
                        file%seq%iun = flds%iun
                    case ('txt')
                        file%txt%active = .true.
                        file%delim = ''
                    case ('csv')
                        file%txt%active = .true.
                        file%delim = ','

                    !> Order of the selection being saved.
                    case ('gridorder', 'shedorder')
                        file%order = opts

                    !> Print leading date-stamp.
                    case ('printdate')
                        file%print_date = .true.

                    !> Specialized output (grid, tile, and GRU point output).
                    case('tsi')
                        file%txt%active = .true.
                        file%order = opts
                        call output_file_parse_indices(shd, file, args, nargs, file%grids, i, ierr)
                    case('tsk')
                        file%txt%active = .true.
                        file%order = opts
                        call output_file_parse_indices(shd, file, args, nargs, file%tiles, i, ierr)
                    case('gru')
                        file%txt%active = .true.
                        file%order = opts
                        call output_file_parse_indices(shd, file, args, nargs, file%grus, i, ierr)

                    !> Function.
                    case ('cum', 'acc', 'avg', 'max', 'min')
                        cycle

                    !> TTOL for ZOD.
                    case ('ttol')
                        n = 0
                        do j = i + 1, nargs
                            if (is_letter(args(j))) exit
                            n = n + 1
                        end do
                        if (n > 0) then
                            if (allocated(ZOD_TTOL)) deallocate(ZOD_TTOL)
                            allocate(ZOD_TTOL(n))
                            do j = 1, n
                                call value(args(i + j), ZOD_TTOL(j), ierr)
                            end do
                        end if

                    case default
                        if (ro%DIAGNOSEMODE > 0) print 1010, trim(args(i)), trim(args(1))
                end select
            end if
        end do

        !> Update options for output in 'txt' format.
        if (file%txt%active) then
            flds%iun = flds%iun + 1
            file%txt%iun = flds%iun
        end if

        !> Allocate output variable.
        if (.not. allocated(file%dat)) then
            if (flds%in_mem) then
                allocate(file%dat(shd%NA, t))
            else
                allocate(file%dat(shd%NA, 1))
            end if
            file%dat = 0.0
        end if

1010    format(3x, 'REMARK: ', (a), ' (Variable ', (a), ') is an unrecognized argument for output.')

    end subroutine

    subroutine output_file_parse_freq(shd, ts, field, args, nargs)

        !> Required for 'is_letter' and 'lowercase' functions.
        use strings

        !> Input/output variables.
        type(ShedGridParams), intent(in) :: shd
        type(output_series) field
        type(dates_model), intent(in) :: ts

        !> Input variables.
        integer, intent(in) :: nargs
        character(len = *), intent(in) :: args(:)

        !> Local variables.
        integer i

        !> Activate output based on 'args' flags.
        do i = 2, nargs
            if (is_letter(args(i)))then
                select case (lowercase(args(i)))

                    !> Yearly.
                    case ('y')
                        call output_file_parse_options(shd, field%y, ts%nyears, args, nargs)

                    !> Monthly.
                    case ('m')
                        call output_file_parse_options(shd, field%m, ts%nmonths, args, nargs)

                    !> Seasonal (monthly average).
                    case ('s')
                        call output_file_parse_options(shd, field%s, 12, args, nargs)

                    !> Daily.
                    case ('d')
                        call output_file_parse_options(shd, field%d, ts%nr_days, args, nargs)

                    !> Hourly.
                    case ('h')
                        call output_file_parse_options(shd, field%h, ts%nr_days*24, args, nargs)

                    !> Per time-step.
                    case ('ts')
                        call output_file_parse_options(shd, field%ts, ts%nr_days*24*(3600/ic%dts), args, nargs)

                    !> Weight by fractional area.
                    case ('frac', 'apply_frac')
                        field%apply_frac = .true.
                end select
            end if
        end do

    end subroutine

    subroutine init_out(fls, shd, ts)

        !> 'control_variables' required for 'ro' options.
        !> 'strings' required for 'is_letter' function.
        use control_variables
        use strings

        !> Input/output variables.
        type(fl_ids), intent(in) :: fls
        type(ShedGridParams), intent(in) :: shd
        type(dates_model), intent(in) :: ts

        !> Local variables.
        integer iun, n, j, nargs, ierr
        character(len = 20) args(50)
        character(len = 1000) line

        !> Allocate output variable for time-stamps based on switch to store variables in-memory.
        if (flds%in_mem) then
            allocate(flds%dates%y(6, ts%nyears))
            allocate(flds%dates%m(6, ts%nmonths))
            allocate(flds%dates%s(6, 12))
            allocate(flds%dates%d(6, ts%nr_days))
            allocate(flds%dates%h(6, ts%nr_days*24))
        else
            allocate(flds%dates%y(6, 1))
            allocate(flds%dates%m(6, 1))
            allocate(flds%dates%s(6, 1))
            allocate(flds%dates%d(6, 1))
            allocate(flds%dates%h(6, 1))
        end if
        allocate(flds%dates%ts(6))

        !> Open output fields configuration file.
        iun = 100
        call open_txt_input(iun, 'outputs_balance.txt', .true., ierr)

        !> Allocate and initialize output fields.
        n = 0
        do while (ierr == 0)

            !> Read the line.
            call read_txt_line(iun, line, ierr)

            !> Check for output field signature: character string followed by at least one space.
            if (len_trim(line) == 0 .or. scan(line, ' ') == 0) cycle
            if (.not. is_letter(line(1:index(line, ' ') - 1))) cycle

            !> Split the line.
            call parse(line, ' ', args, nargs)

            !> Output field.
            if (ro%DIAGNOSEMODE > 0) print 1000, trim(args(1))
            select case (args(1))

                !> Meteorological forcing.
                case ('FSDOWN', 'FSIN')
                    call output_file_parse_freq(shd, ts, flds%fsin, args, nargs)
                    if (flds%fsin%y%active) call output_variables_allocate(out%grid%fsin%y, shd%NA)
                    if (flds%fsin%m%active) call output_variables_allocate(out%grid%fsin%m, shd%NA)
                    if (flds%fsin%d%active) call output_variables_allocate(out%grid%fsin%d, shd%NA)
                    if (flds%fsin%h%active) call output_variables_allocate(out%grid%fsin%h, shd%NA)
                case ('FSVH')
                    call output_file_parse_freq(shd, ts, flds%fsvh, args, nargs)
                    if (flds%fsvh%y%active) call output_variables_allocate(out%grid%fsin%y, shd%NA)
                    if (flds%fsvh%m%active) call output_variables_allocate(out%grid%fsin%m, shd%NA)
                    if (flds%fsvh%d%active) call output_variables_allocate(out%grid%fsin%d, shd%NA)
                    if (flds%fsvh%h%active) call output_variables_allocate(out%grid%fsin%h, shd%NA)
                case ('FSIH')
                    call output_file_parse_freq(shd, ts, flds%fsih, args, nargs)
                    if (flds%fsih%y%active) call output_variables_allocate(out%grid%fsin%y, shd%NA)
                    if (flds%fsih%m%active) call output_variables_allocate(out%grid%fsin%m, shd%NA)
                    if (flds%fsih%d%active) call output_variables_allocate(out%grid%fsin%d, shd%NA)
                    if (flds%fsih%h%active) call output_variables_allocate(out%grid%fsin%h, shd%NA)
                case ('FDL', 'FLIN')
                    call output_file_parse_freq(shd, ts, flds%flin, args, nargs)
                    if (flds%flin%y%active) call output_variables_allocate(out%grid%flin%y, shd%NA)
                    if (flds%flin%m%active) call output_variables_allocate(out%grid%flin%m, shd%NA)
                    if (flds%flin%d%active) call output_variables_allocate(out%grid%flin%d, shd%NA)
                    if (flds%flin%h%active) call output_variables_allocate(out%grid%flin%h, shd%NA)
                case ('UL', 'UV')
                    call output_file_parse_freq(shd, ts, flds%uv, args, nargs)
                    if (flds%uv%y%active) call output_variables_allocate(out%grid%uv%y, shd%NA)
                    if (flds%uv%m%active) call output_variables_allocate(out%grid%uv%m, shd%NA)
                    if (flds%uv%d%active) call output_variables_allocate(out%grid%uv%d, shd%NA)
                    if (flds%uv%h%active) call output_variables_allocate(out%grid%uv%h, shd%NA)
                case ('TA')
                    call output_file_parse_freq(shd, ts, flds%ta, args, nargs)
                    if (flds%ta%y%active) call output_variables_allocate(out%grid%ta%y, shd%NA)
                    if (flds%ta%m%active) call output_variables_allocate(out%grid%ta%m, shd%NA)
                    if (flds%ta%d%active) call output_variables_allocate(out%grid%ta%d, shd%NA)
                    if (flds%ta%h%active) call output_variables_allocate(out%grid%ta%h, shd%NA)
                case ('QA', 'HU')
                    call output_file_parse_freq(shd, ts, flds%qa, args, nargs)
                    if (flds%qa%y%active) call output_variables_allocate(out%grid%qa%y, shd%NA)
                    if (flds%qa%m%active) call output_variables_allocate(out%grid%qa%m, shd%NA)
                    if (flds%qa%d%active) call output_variables_allocate(out%grid%qa%d, shd%NA)
                    if (flds%qa%h%active) call output_variables_allocate(out%grid%qa%h, shd%NA)
                case ('PRES')
                    call output_file_parse_freq(shd, ts, flds%pres, args, nargs)
                    if (flds%pres%y%active) call output_variables_allocate(out%grid%pres%y, shd%NA)
                    if (flds%pres%m%active) call output_variables_allocate(out%grid%pres%m, shd%NA)
                    if (flds%pres%d%active) call output_variables_allocate(out%grid%pres%d, shd%NA)
                    if (flds%pres%h%active) call output_variables_allocate(out%grid%pres%h, shd%NA)
                case ('PRE')
                    call output_file_parse_freq(shd, ts, flds%pre, args, nargs)
                    if (flds%pre%y%active) call output_variables_allocate(out%grid%pre%y, shd%NA)
                    if (flds%pre%m%active) call output_variables_allocate(out%grid%pre%m, shd%NA)
                    if (flds%pre%d%active) call output_variables_allocate(out%grid%pre%d, shd%NA)
                    if (flds%pre%h%active) call output_variables_allocate(out%grid%pre%h, shd%NA)

                !> Water balance.
                case ('PREC', 'Rainfall', 'Rain', 'Precipitation')
                    call output_file_parse_freq(shd, ts, flds%prec, args, nargs)
                    if (flds%prec%y%active) call output_variables_allocate(out%grid%pre%y, shd%NA)
                    if (flds%prec%m%active) call output_variables_allocate(out%grid%pre%m, shd%NA)
                    if (flds%prec%d%active) call output_variables_allocate(out%grid%pre%d, shd%NA)
                    if (flds%prec%h%active) call output_variables_allocate(out%grid%pre%h, shd%NA)
                case ('EVAP', 'Evapotranspiration')
                    call output_file_parse_freq(shd, ts, flds%evap, args, nargs)
                    if (flds%evap%y%active) call output_variables_allocate(out%grid%evap%y, shd%NA)
                    if (flds%evap%m%active) call output_variables_allocate(out%grid%evap%m, shd%NA)
                    if (flds%evap%d%active) call output_variables_allocate(out%grid%evap%d, shd%NA)
                    if (flds%evap%h%active) call output_variables_allocate(out%grid%evap%h, shd%NA)
                case ('Runoff', 'ROF')
                    call output_file_parse_freq(shd, ts, flds%rof, args, nargs)
                    if (flds%rof%y%active) call output_variables_allocate(out%grid%rof%y, shd%NA)
                    if (flds%rof%m%active) call output_variables_allocate(out%grid%rof%m, shd%NA)
                    if (flds%rof%d%active) call output_variables_allocate(out%grid%rof%d, shd%NA)
                    if (flds%rof%h%active) call output_variables_allocate(out%grid%rof%h, shd%NA)
                case ('RCAN')
                    call output_file_parse_freq(shd, ts, flds%rcan, args, nargs)
                    if (flds%rcan%y%active) call output_variables_allocate(out%grid%rcan%y, shd%NA)
                    if (flds%rcan%m%active) call output_variables_allocate(out%grid%rcan%m, shd%NA)
                    if (flds%rcan%d%active) call output_variables_allocate(out%grid%rcan%d, shd%NA)
                    if (flds%rcan%h%active) call output_variables_allocate(out%grid%rcan%h, shd%NA)
                case ('SCAN', 'SNCAN')
                    call output_file_parse_freq(shd, ts, flds%sncan, args, nargs)
                    if (flds%sncan%y%active) call output_variables_allocate(out%grid%sncan%y, shd%NA)
                    if (flds%sncan%m%active) call output_variables_allocate(out%grid%sncan%m, shd%NA)
                    if (flds%sncan%d%active) call output_variables_allocate(out%grid%sncan%d, shd%NA)
                    if (flds%sncan%h%active) call output_variables_allocate(out%grid%sncan%h, shd%NA)
                case ('PNDW')
                    call output_file_parse_freq(shd, ts, flds%pndw, args, nargs)
                    if (flds%pndw%y%active) call output_variables_allocate(out%grid%pndw%y, shd%NA)
                    if (flds%pndw%m%active) call output_variables_allocate(out%grid%pndw%m, shd%NA)
                    if (flds%pndw%d%active) call output_variables_allocate(out%grid%pndw%d, shd%NA)
                    if (flds%pndw%h%active) call output_variables_allocate(out%grid%pndw%h, shd%NA)
                case ('SNO')
                    call output_file_parse_freq(shd, ts, flds%sno, args, nargs)
                    if (flds%sno%y%active) call output_variables_allocate(out%grid%sno%y, shd%NA)
                    if (flds%sno%m%active) call output_variables_allocate(out%grid%sno%m, shd%NA)
                    if (flds%sno%d%active) call output_variables_allocate(out%grid%sno%d, shd%NA)
                    if (flds%sno%h%active) call output_variables_allocate(out%grid%sno%h, shd%NA)
                case ('WSNO')
                    call output_file_parse_freq(shd, ts, flds%wsno, args, nargs)
                    if (flds%wsno%y%active) call output_variables_allocate(out%grid%wsno%y, shd%NA)
                    if (flds%wsno%m%active) call output_variables_allocate(out%grid%wsno%m, shd%NA)
                    if (flds%wsno%d%active) call output_variables_allocate(out%grid%wsno%d, shd%NA)
                    if (flds%wsno%h%active) call output_variables_allocate(out%grid%wsno%h, shd%NA)
                case ('STG', 'DSTG', 'STGW')
                    call output_file_parse_freq(shd, ts, flds%stgw, args, nargs)
                    if (flds%stgw%y%active) call output_variables_allocate(out%grid%stgw%y, shd%NA)
                    if (flds%stgw%m%active) call output_variables_allocate(out%grid%stgw%m, shd%NA)
                    if (flds%stgw%d%active) call output_variables_allocate(out%grid%stgw%d, shd%NA)
                    if (flds%stgw%h%active) call output_variables_allocate(out%grid%stgw%h, shd%NA)
                case ('THLQ')
                    if (.not. allocated(flds%thlq)) allocate(flds%thlq(shd%lc%IGND))
                    do j = 1, shd%lc%IGND
                        call output_file_parse_freq(shd, ts, flds%thlq(j), args, nargs)
                        if (flds%thlq(j)%y%active) call output_variables_allocate(out%grid%thlq(j)%y, shd%NA)
                        if (flds%thlq(j)%m%active) call output_variables_allocate(out%grid%thlq(j)%m, shd%NA)
                        if (flds%thlq(j)%d%active) call output_variables_allocate(out%grid%thlq(j)%d, shd%NA)
                        if (flds%thlq(j)%h%active) call output_variables_allocate(out%grid%thlq(j)%h, shd%NA)
                    end do
                case ('LQWS')
                    if (.not. allocated(flds%lqws)) allocate(flds%lqws(shd%lc%IGND))
                    do j = 1, shd%lc%IGND
                        call output_file_parse_freq(shd, ts, flds%lqws(j), args, nargs)
                        if (flds%lqws(j)%y%active) call output_variables_allocate(out%grid%lqws(j)%y, shd%NA)
                        if (flds%lqws(j)%m%active) call output_variables_allocate(out%grid%lqws(j)%m, shd%NA)
                        if (flds%lqws(j)%d%active) call output_variables_allocate(out%grid%lqws(j)%d, shd%NA)
                        if (flds%lqws(j)%h%active) call output_variables_allocate(out%grid%lqws(j)%h, shd%NA)
                    end do
                case ('THIC')
                    if (.not. allocated(flds%thic)) allocate(flds%thic(shd%lc%IGND))
                    do j = 1, shd%lc%IGND
                        call output_file_parse_freq(shd, ts, flds%thic(j), args, nargs)
                        if (flds%thic(j)%y%active) call output_variables_allocate(out%grid%thic(j)%y, shd%NA)
                        if (flds%thic(j)%m%active) call output_variables_allocate(out%grid%thic(j)%m, shd%NA)
                        if (flds%thic(j)%d%active) call output_variables_allocate(out%grid%thic(j)%d, shd%NA)
                        if (flds%thic(j)%h%active) call output_variables_allocate(out%grid%thic(j)%h, shd%NA)
                    end do
                case ('FRWS', 'FZWS')
                    if (.not. allocated(flds%fzws)) allocate(flds%fzws(shd%lc%IGND))
                    do j = 1, shd%lc%IGND
                        call output_file_parse_freq(shd, ts, flds%fzws(j), args, nargs)
                        if (flds%fzws(j)%y%active) call output_variables_allocate(out%grid%fzws(j)%y, shd%NA)
                        if (flds%fzws(j)%m%active) call output_variables_allocate(out%grid%fzws(j)%m, shd%NA)
                        if (flds%fzws(j)%d%active) call output_variables_allocate(out%grid%fzws(j)%d, shd%NA)
                        if (flds%fzws(j)%h%active) call output_variables_allocate(out%grid%fzws(j)%h, shd%NA)
                    end do

                !> Energy balance.
                case ('HFS', 'SensibleHeat', 'QH')
                    call output_file_parse_freq(shd, ts, flds%qh, args, nargs)
                    if (flds%qh%y%active) call output_variables_allocate(out%grid%qh%y, shd%NA)
                    if (flds%qh%m%active) call output_variables_allocate(out%grid%qh%m, shd%NA)
                    if (flds%qh%d%active) call output_variables_allocate(out%grid%qh%d, shd%NA)
                    if (flds%qh%h%active) call output_variables_allocate(out%grid%qh%h, shd%NA)
                case ('QEVP', 'LatentHeat', 'QE')
                    call output_file_parse_freq(shd, ts, flds%qe, args, nargs)
                    if (flds%qe%y%active) call output_variables_allocate(out%grid%qe%y, shd%NA)
                    if (flds%qe%m%active) call output_variables_allocate(out%grid%qe%m, shd%NA)
                    if (flds%qe%d%active) call output_variables_allocate(out%grid%qe%d, shd%NA)
                    if (flds%qe%h%active) call output_variables_allocate(out%grid%qe%h, shd%NA)
                case ('GFLX', 'HeatConduction')
                    if (.not. allocated(flds%gflx)) allocate(flds%gflx(shd%lc%IGND))
                    do j = 1, shd%lc%IGND
                        call output_file_parse_freq(shd, ts, flds%gflx(j), args, nargs)
                        if (flds%gflx(j)%y%active) call output_variables_allocate(out%grid%gflx(j)%y, shd%NA)
                        if (flds%gflx(j)%m%active) call output_variables_allocate(out%grid%gflx(j)%m, shd%NA)
                        if (flds%gflx(j)%d%active) call output_variables_allocate(out%grid%gflx(j)%d, shd%NA)
                        if (flds%gflx(j)%h%active) call output_variables_allocate(out%grid%gflx(j)%h, shd%NA)
                    end do
                case ('TempSoil', 'Temperature_soil_layers', 'TBAR')
                    if (.not. allocated(flds%tbar)) allocate(flds%tbar(shd%lc%IGND))
                    do j = 1, shd%lc%IGND
                        call output_file_parse_freq(shd, ts, flds%tbar(j), args, nargs)
                        if (flds%tbar(j)%y%active) call output_variables_allocate(out%grid%tbar(j)%y, shd%NA)
                        if (flds%tbar(j)%m%active) call output_variables_allocate(out%grid%tbar(j)%m, shd%NA)
                        if (flds%tbar(j)%d%active) call output_variables_allocate(out%grid%tbar(j)%d, shd%NA)
                        if (flds%tbar(j)%h%active) call output_variables_allocate(out%grid%tbar(j)%h, shd%NA)
                    end do

                case ('ZOD', 'TMAX', 'TMIN', 'ALD')
!                    call output_file_parse_freq(shd, ts, flds%ald, args, nargs)
!                    flds%ald%m%active = .false.
!                    flds%ald%s%active = .false.
!                    flds%ald%d%active = .false.
!                    flds%ald%h%active = .false.
!                    flds%ald%ts%active = .false.
!                    call output_field_allocate(shd, ts, flds%ald)
!                    if (flds%ald%y%active) then
!                        call output_variables_allocate(out%grid%tbar, shd%NA)
!                        if (.not. allocated(TBAR_dly)) allocate(TBAR_dly(nts_d, shd%NA, shd%lc%IGND))
!                        if (.not. allocated(ALD_dly)) allocate(ALD_dly(nts_d, shd%NA))
!                        if (.not. allocated(TMAX_ann)) allocate(TMAX_ann(nts_y, shd%NA, shd%lc%IGND))
!                        if (.not. allocated(TMIN_ann)) allocate(TMIN_ann(nts_y, shd%NA, shd%lc%IGND))
!                        if (.not. allocated(ALD_ann)) allocate(ALD_ann(nts_y, shd%NA))
!                        if (.not. allocated(ZOD_TTOL)) then
!                            allocate(ZOD_TTOL(1)); ZOD_TTOL = 0.0
!                        end if
!                        if (.not. allocated(ZOD_ann)) allocate(ZOD_ann(nts_y, shd%NA, size(ZOD_TTOL)))
!                        TBAR_dly = 0.0; ALD_dly = -1.0; TMAX_ann = 0.0; TMIN_ann = 1000.0; ALD_ann = -1.0; ZOD_ann = -1.0
!                    end if

                !> Channels and routing.
                case ('WR_RUNOFF', 'RFF')
                    call output_file_parse_freq(shd, ts, flds%rff, args, nargs)
                    if (flds%rff%y%active) call output_variables_allocate(out%grid%rff%y, shd%NA)
                    if (flds%rff%m%active) call output_variables_allocate(out%grid%rff%m, shd%NA)
                    if (flds%rff%d%active) call output_variables_allocate(out%grid%rff%d, shd%NA)
                    if (flds%rff%h%active) call output_variables_allocate(out%grid%rff%h, shd%NA)
                case ('WR_RECHARGE', 'RCHG')
                    call output_file_parse_freq(shd, ts, flds%rchg, args, nargs)
                    if (flds%rchg%y%active) call output_variables_allocate(out%grid%rchg%y, shd%NA)
                    if (flds%rchg%m%active) call output_variables_allocate(out%grid%rchg%m, shd%NA)
                    if (flds%rchg%d%active) call output_variables_allocate(out%grid%rchg%d, shd%NA)
                    if (flds%rchg%h%active) call output_variables_allocate(out%grid%rchg%h, shd%NA)

                case default
                    n = n - 1
                    print 1010, trim(args(1))
            end select
            n = n + 1
        end do
        close(iun)
        print 1110, n

1000    format(3x, 'Reading output variable: ', (a))
1010    format(3x, 'REMARK: Variable ', (a), ' is not recognized for output.')
1110    format(3x, 'Output variables: ', i3)

    end subroutine

    subroutine UpdateFIELDSOUT(fls, shd)

        use permafrost_active_layer

        type(fl_ids) fls
        type(ShedGridParams) shd

        call update_output_variables(fls, shd)

!        if (flds%ald%y%active .and. ic%now%day /= ic%next%day) then
!            TBAR_dly(ic%iter%day, : , :) = out%grid%tbar
!            call active_layer_depth( &
!                TBAR_dly(ic%iter%day, :, :), shd%lc%sl%ZBOT, &
!                ALD_dly(ic%iter%day, :), &
!                shd%lc%IGND, shd%NA, 1, shd%NA)
!            ALD_ann(ic%iter%year, :) = max(ALD_ann(ic%iter%year, :), ALD_dly(id, :))
!            TMAX_ann(ic%iter%year, :, :) = max(TMAX_ann(ic%iter%year, :, :), TBAR_dly(ic%iter%day, :, :))
!            TMIN_ann(ic%iter%year, :, :) = min(TMIN_ann(ic%iter%year, :, :), TBAR_dly(ic%iter%day, :, :))
!        end if

    end subroutine

    subroutine Write_Outputs(fls, shd)

        use permafrost_active_layer

        type(fl_ids) fls
        type(ShedGridParams) shd

        integer k, j

        if (flds%ald%y%active .and. ic%now%year /= ic%next%year) then

            !> ALD.
!            call WriteFields_i(vr, ts, ifo, i, 'Y', shd, ts%nyears, fls)

            !> ZOD.
!            do j = 1, size(ZOD_TTOL)
!                do k = 1, ts%nyears
!                    call zero_oscillation_depth( &
!                        TMAX_ann(k, :, :), TMIN_ann(k, :, :), shd%lc%sl%ZBOT, ZOD_TTOL(j), &
!                        ZOD_ann(k, :, j), &
!                        shd%lc%IGND, shd%NA, 1, shd%NA)
!                end do
!                call WriteFields_i(vr, ts, ifo, i, 'Y', shd, ts%nyears, fls, j)
!            end do

            !> TMAX.
!            do j = 1, shd%lc%IGND
!                call WriteFields_i(vr, ts, ifo, i, 'Y', shd, ts%nyears, fls, j)
!            end do

            !> TMIN.
!            do j = 1, shd%lc%IGND
!                call WriteFields_i(vr, ts, ifo, i, 'Y', shd, ts%nyears, fls, j)
!            end do
        end if

    end subroutine

    subroutine flush_output(fls, shd, file, field_name, freq, dates, igndx)

        !> Input variables.
        type(fl_ids), intent(in) :: fls
        type(ShedGridParams), intent(in) :: shd
        type(output_file), intent(in) :: file
        character(len = *), intent(in) :: field_name, freq
        integer, intent(in) :: dates(:, :)

        !> Input variables (optional).
        integer, intent(in), optional :: igndx

        !> Local variables.
        character(len = 25) str

        !> Append 'igndx' if provided.
        if (present(igndx)) then
            write(str, '(i10)') igndx
            str = trim(adjustl(field_name)) // '_' // trim(adjustl(freq)) // '_' // trim(adjustl(str))
        else
            str = trim(adjustl(field_name)) // '_' // trim(adjustl(freq))
        end if

        !> Write output.
        if (file%seq%active) call write_seq(fls, shd, file, str, dates, file%seq)
        if (file%r2c%active) call write_r2c(fls, shd, file, str, dates, file%r2c)
        if (file%txt%active) call write_txt(fls, shd, file, str, dates, file%txt)

    end subroutine

    !> Description:
    !>  Update the output series using the 'out_var' variable.
    subroutine update_output_variable(file, out_var, t)

        !> Input variables.
        real, dimension(:), intent(in) :: out_var
        integer, intent(in) :: t

        !> Input/output variables.
        type(output_file) file

        !> Transfer variable.
        file%dat(:, t) = out_var

    end subroutine

    !> Description:
    !>  Update the 'dates' variable from the 'ic' counter.
    subroutine update_output_dates(dates, iter, t)

        !> Input variables.
        integer, intent(in) :: iter, t

        !> Input/output variables.
        integer dates(:, :)

        !> Save the time-step using 'next' date.
        dates(1, t) = iter
        dates(2, t) = ic%next%year
        dates(3, t) = ic%next%month
        dates(4, t) = ic%next%day
        dates(5, t) = ic%next%hour
        dates(6, t) = ic%next%mins

        !> Check 'hour' for the 24th hour.
        !> Output is written 01-24h while the model runs 00-23h.
        if (dates(5, t) == 0) dates(5, t) = 24

    end subroutine

    subroutine update_output_variables(fls, shd)

        !> Input variables.
        type(fl_ids), intent(in) :: fls
        type(ShedGridParams), intent(in) :: shd

        !> Local variables.
        integer t_y, t_m, t_d, t_h, j
        logical out_y, out_m, out_s, out_d, out_h, out_ts
        real frac(shd%NA)

        !> Set local variables.
        out_y = (ic%now%year /= ic%next%year)
        out_m = (ic%now%month /= ic%next%month)
        out_s = .false.
        out_d = (ic%now%day /= ic%next%day)
        out_h = (ic%now%hour /= ic%next%hour)
        out_ts = .true.

        !> Update time-steps.
        if (out_y) then
            if (flds%in_mem) then
                t_y = ic%iter%year
            else
                t_y = 1
            end if
            call update_output_dates(flds%dates%y, ic%iter%year, t_y)
        end if
        if (out_m) then
            if (flds%in_mem) then
                t_m = ic%iter%month
            else
                t_m = 1
            end if
            call update_output_dates(flds%dates%m, ic%iter%month, t_m)
        end if
        if (out_d) then
            if (flds%in_mem) then
                t_d = ic%iter%day
            else
                t_d = 1
            end if
            call update_output_dates(flds%dates%d, ic%iter%day, t_d)
        end if
        if (out_h) then
            if (flds%in_mem) then
                t_h = ic%iter%hour
            else
                t_h = 1
            end if
            call update_output_dates(flds%dates%h, ic%iter%hour, t_h)
        end if

        !> FSIN.
        if (flds%fsin%y%active .and. out_y) then
            call update_output_variable(flds%fsin%y, out%grid%fsin%y, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%fsin%y, 'FSDOWN', 'Y', flds%dates%y)
        end if
        if (flds%fsin%m%active .and. out_m) then
            call update_output_variable(flds%fsin%m, out%grid%fsin%m, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%fsin%m, 'FSDOWN', 'M', flds%dates%m)
        end if
        if (flds%fsin%d%active .and. out_d) then
            call update_output_variable(flds%fsin%d, out%grid%fsin%d, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%fsin%d, 'FSDOWN', 'D', flds%dates%d)
        end if
        if (flds%fsin%h%active .and. out_h) then
            call update_output_variable(flds%fsin%h, out%grid%fsin%h, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%fsin%h, 'FSDOWN', 'H', flds%dates%h)
        end if

        !> FSVH.
        if (flds%fsvh%y%active .and. out_y) then
            call update_output_variable(flds%fsvh%y, out%grid%fsin%y/2.0, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%fsvh%y, 'FSVH', 'Y', flds%dates%y)
        end if
        if (flds%fsvh%m%active .and. out_m) then
            call update_output_variable(flds%fsvh%m, out%grid%fsin%m/2.0, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%fsvh%m, 'FSVH', 'M', flds%dates%m)
        end if
        if (flds%fsvh%d%active .and. out_d) then
            call update_output_variable(flds%fsvh%d, out%grid%fsin%d/2.0, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%fsvh%d, 'FSVH', 'D', flds%dates%d)
        end if
        if (flds%fsvh%h%active .and. out_h) then
            call update_output_variable(flds%fsvh%h, out%grid%fsin%h/2.0, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%fsvh%h, 'FSVH', 'H', flds%dates%h)
        end if

        !> FSIH.
        if (flds%fsih%y%active .and. out_y) then
            call update_output_variable(flds%fsih%y, out%grid%fsin%y/2.0, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%fsih%y, 'FSIH', 'Y', flds%dates%y)
        end if
        if (flds%fsih%m%active .and. out_m) then
            call update_output_variable(flds%fsih%m, out%grid%fsin%m/2.0, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%fsih%m, 'FSIH', 'M', flds%dates%m)
        end if
        if (flds%fsih%d%active .and. out_d) then
            call update_output_variable(flds%fsih%d, out%grid%fsin%d/2.0, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%fsih%d, 'FSIH', 'D', flds%dates%d)
        end if
        if (flds%fsih%h%active .and. out_h) then
            call update_output_variable(flds%fsih%h, out%grid%fsin%h/2.0, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%fsih%h, 'FSIH', 'H', flds%dates%h)
        end if

        !> FLIN.
        if (flds%flin%y%active .and. out_y) then
            call update_output_variable(flds%flin%y, out%grid%flin%y, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%flin%y, 'FDL', 'Y', flds%dates%y)
        end if
        if (flds%flin%m%active .and. out_m) then
            call update_output_variable(flds%flin%m, out%grid%flin%m, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%flin%m, 'FDL', 'M', flds%dates%m)
        end if
        if (flds%flin%d%active .and. out_d) then
            call update_output_variable(flds%flin%d, out%grid%flin%d, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%flin%d, 'FDL', 'D', flds%dates%d)
        end if
        if (flds%flin%h%active .and. out_h) then
            call update_output_variable(flds%flin%h, out%grid%flin%h, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%flin%h, 'FDL', 'H', flds%dates%h)
        end if

        !> UV.
        if (flds%uv%y%active .and. out_y) then
            call update_output_variable(flds%uv%y, out%grid%uv%y, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%uv%y, 'UL', 'Y', flds%dates%y)
        end if
        if (flds%uv%m%active .and. out_m) then
            call update_output_variable(flds%uv%m, out%grid%uv%m, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%uv%m, 'UL', 'M', flds%dates%m)
        end if
        if (flds%uv%d%active .and. out_d) then
            call update_output_variable(flds%uv%d, out%grid%uv%d, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%uv%d, 'UL', 'D', flds%dates%d)
        end if
        if (flds%uv%h%active .and. out_h) then
            call update_output_variable(flds%uv%h, out%grid%uv%h, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%uv%h, 'UL', 'H', flds%dates%h)
        end if

        !> TA.
        if (flds%ta%y%active .and. out_y) then
            call update_output_variable(flds%ta%y, out%grid%ta%y, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%ta%y, 'TA', 'Y', flds%dates%y)
        end if
        if (flds%ta%m%active .and. out_m) then
            call update_output_variable(flds%ta%m, out%grid%ta%m, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%ta%m, 'TA', 'M', flds%dates%m)
        end if
        if (flds%ta%d%active .and. out_d) then
            call update_output_variable(flds%ta%d, out%grid%ta%d, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%ta%d, 'TA', 'D', flds%dates%d)
        end if
        if (flds%ta%h%active .and. out_h) then
            call update_output_variable(flds%ta%h, out%grid%ta%h, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%ta%h, 'TA', 'H', flds%dates%h)
        end if

        !> QA.
        if (flds%qa%y%active .and. out_y) then
            call update_output_variable(flds%qa%y, out%grid%qa%y, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%qa%y, 'QA', 'Y', flds%dates%y)
        end if
        if (flds%qa%m%active .and. out_m) then
            call update_output_variable(flds%qa%m, out%grid%qa%m, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%qa%m, 'QA', 'M', flds%dates%m)
        end if
        if (flds%qa%d%active .and. out_d) then
            call update_output_variable(flds%qa%d, out%grid%qa%d, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%qa%d, 'QA', 'D', flds%dates%d)
        end if
        if (flds%qa%h%active .and. out_h) then
            call update_output_variable(flds%qa%h, out%grid%qa%h, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%qa%h, 'QA', 'H', flds%dates%h)
        end if

        !> PRES.
        if (flds%pres%y%active .and. out_y) then
            call update_output_variable(flds%pres%y, out%grid%pres%y, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%pres%y, 'PRES', 'Y', flds%dates%y)
        end if
        if (flds%pres%m%active .and. out_m) then
            call update_output_variable(flds%pres%m, out%grid%pres%m, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%pres%m, 'PRES', 'M', flds%dates%m)
        end if
        if (flds%pres%d%active .and. out_d) then
            call update_output_variable(flds%pres%d, out%grid%pres%d, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%pres%d, 'PRES', 'D', flds%dates%d)
        end if
        if (flds%pres%h%active .and. out_h) then
            call update_output_variable(flds%pres%h, out%grid%pres%h, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%pres%h, 'PRES', 'H', flds%dates%h)
        end if

        !> PRE.
        if (flds%pre%y%active .and. out_y) then
            call update_output_variable(flds%pre%y, out%grid%pre%y, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%pre%y, 'PRE', 'Y', flds%dates%y)
        end if
        if (flds%pre%m%active .and. out_m) then
            call update_output_variable(flds%pre%m, out%grid%pre%m, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%pre%m, 'PRE', 'M', flds%dates%m)
        end if
        if (flds%pre%d%active .and. out_d) then
            call update_output_variable(flds%pre%d, out%grid%pre%d, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%pre%d, 'PRE', 'D', flds%dates%d)
        end if
        if (flds%pre%h%active .and. out_h) then
            call update_output_variable(flds%pre%h, out%grid%pre%h, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%pre%h, 'PRE', 'H', flds%dates%h)
        end if

        !> PREC.
        if (flds%prec%apply_frac) then
            frac = shd%FRAC
        else
            frac = 1.0
        end if
        if (flds%prec%y%active .and. out_y) then
            call update_output_variable(flds%prec%y, out%grid%pre%y*ic%dts*frac, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%prec%y, 'PREC', 'Y', flds%dates%y)
        end if
        if (flds%prec%m%active .and. out_m) then
            call update_output_variable(flds%prec%m, out%grid%pre%m*ic%dts*frac, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%prec%m, 'PREC', 'M', flds%dates%m)
        end if
        if (flds%prec%d%active .and. out_d) then
            call update_output_variable(flds%prec%d, out%grid%pre%d*ic%dts*frac, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%prec%d, 'PREC', 'D', flds%dates%d)
        end if
        if (flds%prec%h%active .and. out_h) then
            call update_output_variable(flds%prec%h, out%grid%pre%h*ic%dts*frac, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%prec%h, 'PREC', 'H', flds%dates%h)
        end if

        !> EVAP.
        if (flds%evap%apply_frac) then
            frac = frac
        else
            frac = 1.0
        end if
        if (flds%evap%y%active .and. out_y) then
            call update_output_variable(flds%evap%y, out%grid%evap%y*ic%dts*frac, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%evap%y, 'EVAP', 'Y', flds%dates%y)
        end if
        if (flds%evap%m%active .and. out_m) then
            call update_output_variable(flds%evap%m, out%grid%evap%m*ic%dts*frac, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%evap%m, 'EVAP', 'M', flds%dates%m)
        end if
        if (flds%evap%d%active .and. out_d) then
            call update_output_variable(flds%evap%d, out%grid%evap%d*ic%dts*frac, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%evap%d, 'EVAP', 'D', flds%dates%d)
        end if
        if (flds%evap%h%active .and. out_h) then
            call update_output_variable(flds%evap%h, out%grid%evap%h*ic%dts*frac, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%evap%h, 'EVAP', 'H', flds%dates%h)
        end if

        !> ROF.
        if (flds%rof%apply_frac) then
            frac = shd%FRAC
        else
            frac = 1.0
        end if
        if (flds%rof%y%active .and. out_y) then
            call update_output_variable(flds%rof%y, out%grid%rof%y*ic%dts*frac, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rof%y, 'ROF', 'Y', flds%dates%y)
        end if
        if (flds%rof%m%active .and. out_m) then
            call update_output_variable(flds%rof%m, out%grid%rof%m*ic%dts*frac, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rof%m, 'ROF', 'M', flds%dates%m)
        end if
        if (flds%rof%d%active .and. out_d) then
            call update_output_variable(flds%rof%d, out%grid%rof%d*ic%dts*frac, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rof%d, 'ROF', 'D', flds%dates%d)
        end if
        if (flds%rof%h%active .and. out_h) then
            call update_output_variable(flds%rof%h, out%grid%rof%h*ic%dts*frac, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rof%h, 'ROF', 'H', flds%dates%h)
        end if

        !> RCAN.
        if (flds%rcan%apply_frac) then
            frac = shd%FRAC
        else
            frac = 1.0
        end if
        if (flds%rcan%y%active .and. out_y) then
            call update_output_variable(flds%rcan%y, out%grid%rcan%y*frac, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rcan%y, 'RCAN', 'Y', flds%dates%y)
        end if
        if (flds%rcan%m%active .and. out_m) then
            call update_output_variable(flds%rcan%m, out%grid%rcan%m*frac, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rcan%m, 'RCAN', 'M', flds%dates%m)
        end if
        if (flds%rcan%d%active .and. out_d) then
            call update_output_variable(flds%rcan%d, out%grid%rcan%d*frac, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rcan%d, 'RCAN', 'D', flds%dates%d)
        end if
        if (flds%rcan%h%active .and. out_h) then
            call update_output_variable(flds%rcan%h, out%grid%rcan%h*frac, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rcan%h, 'RCAN', 'H', flds%dates%h)
        end if

        !> SNCAN.
        if (flds%sncan%apply_frac) then
            frac = shd%FRAC
        else
            frac = 1.0
        end if
        if (flds%sncan%y%active .and. out_y) then
            call update_output_variable(flds%sncan%y, out%grid%sncan%y*frac, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%sncan%y, 'SNCAN', 'Y', flds%dates%y)
        end if
        if (flds%sncan%m%active .and. out_m) then
            call update_output_variable(flds%sncan%m, out%grid%sncan%m*frac, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%sncan%m, 'SNCAN', 'M', flds%dates%m)
        end if
        if (flds%sncan%d%active .and. out_d) then
            call update_output_variable(flds%sncan%d, out%grid%sncan%d*frac, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%sncan%d, 'SNCAN', 'D', flds%dates%d)
        end if
        if (flds%sncan%h%active .and. out_h) then
            call update_output_variable(flds%sncan%h, out%grid%sncan%h*frac, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%sncan%h, 'SNCAN', 'H', flds%dates%h)
        end if

        !> PNDW.
        if (flds%pndw%apply_frac) then
            frac = shd%FRAC
        else
            frac = 1.0
        end if
        if (flds%pndw%y%active .and. out_y) then
            call update_output_variable(flds%pndw%y, out%grid%pndw%y*frac, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%pndw%y, 'PNDW', 'Y', flds%dates%y)
        end if
        if (flds%pndw%m%active .and. out_m) then
            call update_output_variable(flds%pndw%m, out%grid%pndw%m*frac, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%pndw%m, 'PNDW', 'M', flds%dates%m)
        end if
        if (flds%pndw%d%active .and. out_d) then
            call update_output_variable(flds%pndw%d, out%grid%pndw%d*frac, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%pndw%d, 'PNDW', 'D', flds%dates%d)
        end if
        if (flds%pndw%h%active .and. out_h) then
            call update_output_variable(flds%pndw%h, out%grid%pndw%h*frac, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%pndw%h, 'PNDW', 'H', flds%dates%h)
        end if

        !> SNO.
        if (flds%sno%apply_frac) then
            frac = shd%FRAC
        else
            frac = 1.0
        end if
        if (flds%sno%y%active .and. out_y) then
            call update_output_variable(flds%sno%y, out%grid%sno%y*frac, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%sno%y, 'SNO', 'Y', flds%dates%y)
        end if
        if (flds%sno%m%active .and. out_m) then
            call update_output_variable(flds%sno%m, out%grid%sno%m*frac, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%sno%m, 'SNO', 'M', flds%dates%m)
        end if
        if (flds%sno%d%active .and. out_d) then
            call update_output_variable(flds%sno%d, out%grid%sno%d*frac, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%sno%d, 'SNO', 'D', flds%dates%d)
        end if
        if (flds%sno%h%active .and. out_h) then
            call update_output_variable(flds%sno%h, out%grid%sno%h*frac, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%sno%h, 'SNO', 'H', flds%dates%h)
        end if

        !> WSNO.
        if (flds%wsno%apply_frac) then
            frac = shd%FRAC
        else
            frac = 1.0
        end if
        if (flds%wsno%y%active .and. out_y) then
            call update_output_variable(flds%wsno%y, out%grid%wsno%y*frac, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%wsno%y, 'WSNO', 'Y', flds%dates%y)
        end if
        if (flds%wsno%m%active .and. out_m) then
            call update_output_variable(flds%wsno%m, out%grid%wsno%m*frac, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%wsno%m, 'WSNO', 'M', flds%dates%m)
        end if
        if (flds%wsno%d%active .and. out_d) then
            call update_output_variable(flds%wsno%d, out%grid%wsno%d*frac, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%wsno%d, 'WSNO', 'D', flds%dates%d)
        end if
        if (flds%wsno%h%active .and. out_h) then
            call update_output_variable(flds%wsno%h, out%grid%wsno%h*frac, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%wsno%h, 'WSNO', 'H', flds%dates%h)
        end if

        !> STGW.
        if (flds%stgw%apply_frac) then
            frac = shd%FRAC
        else
            frac = 1.0
        end if
        if (flds%stgw%y%active .and. out_y) then
            call update_output_variable(flds%stgw%y, out%grid%stgw%y*frac, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%stgw%y, 'STG', 'Y', flds%dates%y)
        end if
        if (flds%stgw%m%active .and. out_m) then
            call update_output_variable(flds%stgw%m, out%grid%stgw%m*frac, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%stgw%m, 'STG', 'M', flds%dates%m)
        end if
        if (flds%stgw%d%active .and. out_d) then
            call update_output_variable(flds%stgw%d, out%grid%stgw%d*frac, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%stgw%d, 'STG', 'D', flds%dates%d)
        end if
        if (flds%stgw%h%active .and. out_h) then
            call update_output_variable(flds%stgw%h, out%grid%stgw%h*frac, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%stgw%h, 'STG', 'H', flds%dates%h)
        end if

        !> QH.
        if (flds%qh%apply_frac) then
            frac = shd%FRAC
        else
            frac = 1.0
        end if
        if (flds%qh%y%active .and. out_y) then
            call update_output_variable(flds%qh%y, out%grid%qh%y*frac, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%qh%y, 'HFS', 'Y', flds%dates%y)
        end if
        if (flds%qh%m%active .and. out_m) then
            call update_output_variable(flds%qh%m, out%grid%qh%m*frac, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%qh%m, 'HFS', 'M', flds%dates%m)
        end if
        if (flds%qh%d%active .and. out_d) then
            call update_output_variable(flds%qh%d, out%grid%qh%d*frac, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%qh%d, 'HFS', 'D', flds%dates%d)
        end if
        if (flds%qh%h%active .and. out_h) then
            call update_output_variable(flds%qh%h, out%grid%qh%h*frac, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%qh%h, 'HFS', 'H', flds%dates%h)
        end if

        !> QE.
        if (flds%qe%apply_frac) then
            frac = shd%FRAC
        else
            frac = 1.0
        end if
        if (flds%qe%y%active .and. out_y) then
            call update_output_variable(flds%qe%y, out%grid%qe%y*frac, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%qe%y, 'QEVP', 'Y', flds%dates%y)
        end if
        if (flds%qe%m%active .and. out_m) then
            call update_output_variable(flds%qe%m, out%grid%qe%m*frac, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%qe%m, 'QEVP', 'M', flds%dates%m)
        end if
        if (flds%qe%d%active .and. out_d) then
            call update_output_variable(flds%qe%d, out%grid%qe%d*frac, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%qe%d, 'QEVP', 'D', flds%dates%d)
        end if
        if (flds%qe%h%active .and. out_h) then
            call update_output_variable(flds%qe%h, out%grid%qe%h*frac, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%qe%h, 'QEVP', 'H', flds%dates%h)
        end if

        !> Variables with multiple layers.
        do j = 1, shd%lc%IGND

            !> THLQ.
            if (allocated(flds%thlq)) then
                if (flds%thlq(j)%apply_frac) then
                    frac = shd%FRAC
                else
                    frac = 1.0
                end if
                if (flds%thlq(j)%y%active .and. out_y) then
                    call update_output_variable(flds%thlq(j)%y, out%grid%thlq(j)%y*frac, t_y)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%thlq(j)%y, 'THLQ', 'Y', flds%dates%y, j)
                end if
                if (flds%thlq(j)%m%active .and. out_m) then
                    call update_output_variable(flds%thlq(j)%m, out%grid%thlq(j)%m*frac, t_m)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%thlq(j)%m, 'THLQ', 'M', flds%dates%m, j)
                end if
                if (flds%thlq(j)%d%active .and. out_d) then
                    call update_output_variable(flds%thlq(j)%d, out%grid%thlq(j)%d*frac, t_d)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%thlq(j)%d, 'THLQ', 'D', flds%dates%d, j)
                end if
                if (flds%thlq(j)%h%active .and. out_h) then
                    call update_output_variable(flds%thlq(j)%h, out%grid%thlq(j)%h*frac, t_h)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%thlq(j)%h, 'THLQ', 'H', flds%dates%h, j)
                end if
            end if

            !> LQWS.
            if (allocated(flds%lqws)) then
                if (flds%lqws(j)%apply_frac) then
                    frac = shd%FRAC
                else
                    frac = 1.0
                end if
                if (flds%lqws(j)%y%active .and. out_y) then
                    call update_output_variable(flds%lqws(j)%y, out%grid%lqws(j)%y*frac, t_y)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%lqws(j)%y, 'LQWS', 'Y', flds%dates%y, j)
                end if
                if (flds%lqws(j)%m%active .and. out_m) then
                    call update_output_variable(flds%lqws(j)%m, out%grid%lqws(j)%m*frac, t_m)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%lqws(j)%m, 'LQWS', 'M', flds%dates%m, j)
                end if
                if (flds%lqws(j)%d%active .and. out_d) then
                    call update_output_variable(flds%lqws(j)%d, out%grid%lqws(j)%d*frac, t_d)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%lqws(j)%d, 'LQWS', 'D', flds%dates%d, j)
                end if
                if (flds%lqws(j)%h%active .and. out_h) then
                    call update_output_variable(flds%lqws(j)%h, out%grid%lqws(j)%h*frac, t_h)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%lqws(j)%h, 'LQWS', 'H', flds%dates%h, j)
                end if
            end if

            !> THIC.
            if (allocated(flds%thic)) then
                if (flds%thic(j)%apply_frac) then
                    frac = shd%FRAC
                else
                    frac = 1.0
                end if
                if (flds%thic(j)%y%active .and. out_y) then
                    call update_output_variable(flds%thic(j)%y, out%grid%thic(j)%y*frac, t_y)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%thic(j)%y, 'THIC', 'Y', flds%dates%y, j)
                end if
                if (flds%thic(j)%m%active .and. out_m) then
                    call update_output_variable(flds%thic(j)%m, out%grid%thic(j)%m*frac, t_m)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%thic(j)%m, 'THIC', 'M', flds%dates%m, j)
                end if
                if (flds%thic(j)%d%active .and. out_d) then
                    call update_output_variable(flds%thic(j)%d, out%grid%thic(j)%d*frac, t_d)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%thic(j)%d, 'THIC', 'D', flds%dates%d, j)
                end if
                if (flds%thic(j)%h%active .and. out_h) then
                    call update_output_variable(flds%thic(j)%h, out%grid%thic(j)%h*frac, t_h)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%thic(j)%h, 'THIC', 'H', flds%dates%h, j)
                end if
            end if

            !> FZWS.
            if (allocated(flds%fzws)) then
                if (flds%fzws(j)%apply_frac) then
                    frac = shd%FRAC
                else
                    frac = 1.0
                end if
                if (flds%fzws(j)%y%active .and. out_y) then
                    call update_output_variable(flds%fzws(j)%y, out%grid%fzws(j)%y*frac, t_y)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%fzws(j)%y, 'FRWS', 'Y', flds%dates%y, j)
                end if
                if (flds%fzws(j)%m%active .and. out_m) then
                    call update_output_variable(flds%fzws(j)%m, out%grid%fzws(j)%m*frac, t_m)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%fzws(j)%m, 'FRWS', 'M', flds%dates%m, j)
                end if
                if (flds%fzws(j)%d%active .and. out_d) then
                    call update_output_variable(flds%fzws(j)%d, out%grid%fzws(j)%d*frac, t_d)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%fzws(j)%d, 'FRWS', 'D', flds%dates%d, j)
                end if
                if (flds%fzws(j)%h%active .and. out_h) then
                    call update_output_variable(flds%fzws(j)%h, out%grid%fzws(j)%h*frac, t_h)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%fzws(j)%h, 'FRWS', 'H', flds%dates%h, j)
                end if
            end if

            !> GFLX.
            if (allocated(flds%gflx)) then
                if (flds%gflx(j)%apply_frac) then
                    frac = shd%FRAC
                else
                    frac = 1.0
                end if
                if (flds%gflx(j)%y%active .and. out_y) then
                    call update_output_variable(flds%gflx(j)%y, out%grid%gflx(j)%y*frac, t_y)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%gflx(j)%y, 'GFLX', 'Y', flds%dates%y, j)
                end if
                if (flds%gflx(j)%m%active .and. out_m) then
                    call update_output_variable(flds%gflx(j)%m, out%grid%gflx(j)%m*frac, t_m)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%gflx(j)%m, 'GFLX', 'M', flds%dates%m, j)
                end if
                if (flds%gflx(j)%d%active .and. out_d) then
                    call update_output_variable(flds%gflx(j)%d, out%grid%gflx(j)%d*frac, t_d)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%gflx(j)%d, 'GFLX', 'D', flds%dates%d, j)
                end if
                if (flds%gflx(j)%h%active .and. out_h) then
                    call update_output_variable(flds%gflx(j)%h, out%grid%gflx(j)%h*frac, t_h)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%gflx(j)%h, 'GFLX', 'H', flds%dates%h, j)
                end if
            end if

            !> TBAR.
            if (allocated(flds%tbar)) then
                if (flds%tbar(j)%y%active .and. out_y) then
                    call update_output_variable(flds%tbar(j)%y, out%grid%tbar(j)%y, t_y)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%tbar(j)%y, 'TBAR', 'Y', flds%dates%y, j)
                end if
                if (flds%tbar(j)%m%active .and. out_m) then
                    call update_output_variable(flds%tbar(j)%m, out%grid%tbar(j)%m, t_m)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%tbar(j)%m, 'TBAR', 'M', flds%dates%m, j)
                end if
                if (flds%tbar(j)%d%active .and. out_d) then
                    call update_output_variable(flds%tbar(j)%d, out%grid%tbar(j)%d, t_d)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%tbar(j)%d, 'TBAR', 'D', flds%dates%d, j)
                end if
                if (flds%tbar(j)%h%active .and. out_h) then
                    call update_output_variable(flds%tbar(j)%h, out%grid%tbar(j)%h, t_h)
                    if (.not. flds%in_mem) call flush_output(fls, shd, flds%tbar(j)%h, 'TBAR', 'H', flds%dates%h, j)
                end if
            end if
        end do

        !> ZOD, TMAX, TMIN, ALD.

        !> RFF.
        if (flds%rff%y%active .and. out_y) then
            call update_output_variable(flds%rff%y, out%grid%rff%y*ic%dts, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rff%y, 'WR_RUNOFF', 'Y', flds%dates%y)
        end if
        if (flds%rff%m%active .and. out_m) then
            call update_output_variable(flds%rff%m, out%grid%rff%m*ic%dts, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rff%m, 'WR_RUNOFF', 'M', flds%dates%m)
        end if
        if (flds%rff%d%active .and. out_d) then
            call update_output_variable(flds%rff%d, out%grid%rff%d*ic%dts, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rff%d, 'WR_RUNOFF', 'D', flds%dates%d)
        end if
        if (flds%rff%h%active .and. out_h) then
            call update_output_variable(flds%rff%h, out%grid%rff%h*ic%dts, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rff%h, 'WR_RUNOFF', 'H', flds%dates%h)
        end if

        !> RCHG.
        if (flds%rchg%y%active .and. out_y) then
            call update_output_variable(flds%rchg%y, out%grid%rchg%y*ic%dts, t_y)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rchg%y, 'WR_RECHARGE', 'Y', flds%dates%y)
        end if
        if (flds%rchg%m%active .and. out_m) then
            call update_output_variable(flds%rchg%m, out%grid%rchg%m*ic%dts, t_m)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rchg%m, 'WR_RECHARGE', 'M', flds%dates%m)
        end if
        if (flds%rchg%d%active .and. out_d) then
            call update_output_variable(flds%rchg%d, out%grid%rchg%d*ic%dts, t_d)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rchg%d, 'WR_RECHARGE', 'D', flds%dates%d)
        end if
        if (flds%rchg%h%active .and. out_h) then
            call update_output_variable(flds%rchg%h, out%grid%rchg%h*ic%dts, t_h)
            if (.not. flds%in_mem) call flush_output(fls, shd, flds%rchg%h, 'WR_RECHARGE', 'H', flds%dates%h)
        end if

    end subroutine

    subroutine write_seq(fls, shd, file, field_name, dates, file_fmt)

        !> Input variables.
        type(fl_ids), intent(in) :: fls
        type(ShedGridParams), intent(in) :: shd
        type(output_file), intent(in) :: file
        character(len = *), intent(in) :: field_name
        integer, intent(in) :: dates(:, :)
        type(output_file_format), intent(in) :: file_fmt

        !> Local variables.
        integer iun, t, ierr
        logical opened_status

        !> Check if the file is opened.
        iun = file_fmt%iun
        inquire(iun, opened = opened_status)

        !> Open the file (if not opened).
        if (.not. opened_status) then
            open( &
                iun, file = trim(adjustl(fls%GENDIR_OUT)) // '/' // trim(adjustl(field_name)) // '.seq', &
                status = 'replace', form = 'unformatted', action = 'write', access = 'sequential', &
                iostat = ierr)
        end if

        !> Write series.
        do t = 1, size(file%dat, 2)

            !> Write frame number (N) and time-stamp.
            !> Extended format for 'seq': N N yyyy MM dd HH mm ss SSS
            write(iun) dates(1, t), dates(1, t), dates(2, t), dates(3, t), dates(4, t), dates(5, t), dates(6, t)

            !> Write data.
            write(iun) file%dat(:, t)
        end do

    end subroutine

    subroutine write_r2c(fls, shd, file, field_name, dates, file_fmt)

        !> Input variables.
        type(fl_ids), intent(in) :: fls
        type(ShedGridParams), intent(in) :: shd
        type(output_file), intent(in) :: file
        character(len = *), intent(in) :: field_name
        integer, intent(in) :: dates(:, :)
        type(output_file_format), intent(in) :: file_fmt

        !> Local variables.
        integer iun, t, j, i, ierr
        real, dimension(shd%yCount, shd%xCount) :: data_aux
        logical opened_status
        character(len = 10) str10
        character(len = 8) str8

        !> Check if the file is opened.
        iun = file_fmt%iun
        inquire(iun, opened = opened_status)

        !> Open the file (if not opened) and write 'r2c' header.
        if (.not. opened_status) then
            open( &
                iun, file = trim(adjustl(fls%GENDIR_OUT)) // '/' // trim(adjustl(field_name)) // '.r2c', &
                status = 'replace', form = 'formatted', action = 'write', &
                iostat = ierr)
            write(iun, 3005) '########################################'
            write(iun, 3005) ':FileType r2c  ASCII  EnSim 1.0         '
            write(iun, 3005) '#                                       '
            write(iun, 3005) '# DataType               2D Rect Cell   '
            write(iun, 3005) '#                                       '
            write(iun, 3005) ':Application               MeshOutput   '
            write(iun, 3005) ':Version                 1.0.00         '
            write(iun, 3005) ':WrittenBy          MESH_DRIVER         '
            call date_and_time(str8, str10)
            write(iun, 3010) ':CreationDate       ', str8(1:4), str8(5:6), str8(7:8), str10(1:2), str10(3:4)
            write(iun, 3005) '#                                       '
            write(iun, 3005) '#---------------------------------------'
            write(iun, 3005) '#                                       '
            i = len_trim(field_name)
            if (index(field_name, '_') > 1) i = index(field_name, '_') - 1
            write(iun, 3002) ':Name               ', field_name(1:i)
            write(iun, 3005) '#                                       '
            write(iun, 3004) ':Projection         ', shd%CoordSys%Proj
            if (shd%CoordSys%Proj == 'LATLONG   ') &
                write(iun, 3004) ':Ellipsoid          ', shd%CoordSys%Ellips
            if (shd%CoordSys%Proj == 'UTM       ') then
                write(iun, 3004) ':Ellipsoid          ', shd%CoordSys%Ellips
                write(iun, 3004) ':Zone               ', shd%CoordSys%Zone
            end if
            write(iun, 3005) '#                                       '
            write(iun, 3003) ':xOrigin            ', shd%xOrigin
            write(iun, 3003) ':yOrigin            ', shd%yOrigin
            write(iun, 3005) '#                                       '
            write(iun, 3005) ':SourceFile            MESH_DRIVER      '
            write(iun, 3005) '#                                       '
            write(iun, 3002) ':AttributeName      ', field_name(1:i)
            write(iun, 3002) ':AttributeUnits     ', ''
            write(iun, 3005) '#                                       '
            write(iun, 3001) ':xCount             ', shd%xCount
            write(iun, 3001) ':yCount             ', shd%yCount
            write(iun, 3003) ':xDelta             ', shd%xDelta
            write(iun, 3003) ':yDelta             ', shd%yDelta
            write(iun, 3005) '#                                       '
            write(iun, 3005) '#                                       '
            write(iun, 3005) ':endHeader                              '
        end if

        !> Write series.
        do t = 1, size(file%dat, 2)

            !> Transfer data to temporary variable.
            data_aux = 0.0
            do i = 1, shd%NA
                data_aux(shd%yyy(i), shd%xxx(i)) = file%dat(i, t)
            end do

            !> Write frame number and time-stamp.
            !> Standard format for 'r2c': "yyyy/MM/dd HH:mm:ss.SSS"
            write(iun, 9000) dates(1, t), dates(1, t), dates(2, t), dates(3, t), dates(4, t), dates(5, t), dates(6, t)

            !> Write data.
            do j = 1, shd%yCount
                write(iun, 9001) (data_aux(j, i), i = 1, shd%xCount)
            end do

            !> Write end frame.
            write(iun, 9002)
        end do

3001    format((a), i8)
3002    format((a), 3x, (a))
3003    format((a), f16.7)
3004    format((a), 1x, (a))
3005    format((a))
3010    format(a20, a4, '-', a2, '-', a2, 2x, a2, ':', a2)
9000    format(':Frame', 2i10, 3x, """", i4, '/', i2.2, '/', i2.2, 1x, i2.2, ':', i2.2, ":00.000""")
9001    format(999(e12.6, ' '))
9002    format(':EndFrame')

    end subroutine

    subroutine write_txt(fls, shd, file, field_name, dates, file_fmt)

        !> Input variables.
        type(fl_ids), intent(in) :: fls
        type(ShedGridParams), intent(in) :: shd
        type(output_file), intent(in) :: file
        character(len = *), intent(in) :: field_name
        integer, intent(in) :: dates(:, :)
        type(output_file_format), intent(in) :: file_fmt

        !> Local variables.
        integer iun, t, j, i, ierr
        real, dimension(shd%yCount, shd%xCount) :: data_aux
        logical opened_status
        character(len = 25) str

        !> Check if the file is opened.
        iun = file_fmt%iun
        inquire(iun, opened = opened_status)

        !> Open the file (if not opened).
        if (.not. opened_status) then
            open( &
                iun, file = trim(adjustl(fls%GENDIR_OUT)) // '/' // trim(adjustl(field_name)) // '.txt', &
                status = 'replace', form = 'formatted', action = 'write', &
                iostat = ierr)
        end if

        !> Assign the delimiter.
        select case (file%delim)
            case (',')
                write(str, '(a)') "(9999(e12.6, ','))"
            case default
                write(str, '(a)') "(9999(e12.6, ' '))"
        end select

        !> Write series.
        do t = 1, size(file%dat, 2)

            !> Lead line with date (optional).
            if (file%print_date) then
                write(iun, 9000, advance = 'no') dates(2, t), dates(3, t), dates(4, t), dates(5, t), dates(6, t)
            end if

            !> Determine order of cells for output.
            select case (file%order)

                !> Write for specific grids.
                case ('tsi')
                    write(iun, str) (file%dat(file%grids(i), t), i = 1, size(file%grids))

                !> Write by order of 'r2c' grid (e.g., by shd%yCount, then by shd%xCount in a single line).
                case ('shedorder')

                    !> Transfer data to temporary array.
                    data_aux = 0.0
                    do i = 1, shd%NA
                        data_aux(shd%yyy(i), shd%xxx(i)) = file%dat(i, t)
                    end do

                    !> Write data (in a single line).
                    do j = 1, shd%yCount
                        write(iun, str, advance = 'no') (data_aux(j, i), i = 1, shd%xCount)
                    end do
                    write(iun, *)

                !> Write by order of RANK (e.g., 1:shd%NA).
                case default
                    write(iun, str) file%dat(:, t)
            end select
        end do

9000    format("""", i4, '/', i2.2, '/', i2.2, 1x, i2.2, ':', i2.2, ":00.000""", 2x)

    end subroutine

end module
