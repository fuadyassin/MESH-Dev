!>
!> Module for storing control variable types.
!>
module control_variables

    !> *****************************************************************
    !> Description: Variable type to store generic run options. These
    !> run options are not tied to any one part, module, or process
    !> module within the code.
    !> *****************************************************************
    type run_options

        !* VERBOSEMODE: Flag to suppress certain model output from the console.
        !*   VERBOSEMODE = 0: Disable most console output.
        !*   VERBOSEMODE = 1: Enable regular output to the console (default).
        integer :: VERBOSEMODE = 1

        !* DIAGNOSEMODE: Flag to write additional diagnostic output to the console.
        !*   DIAGNOSEMODE = 0: Disable diagnostic output (default).
        !*   DIAGNOSEMODE = 1: Write additional diagnostic output to the console.
        integer :: DIAGNOSEMODE = 0

        !> RUNFLAGS: Flags to enable or disable processes (default all: .true.).
        !*  RUNCLIM: Read meteorological forcing input.
        !*  RUNCHNL: Run channel flow balance and output.
        !*  RUNBALWB: Run water balance and output.
        !*  RUNBALEB: Run energy balance and output.
        !*  RUNTILE: Run tile processes (e.g., LSS).
        !*  RUNGRID: Run grid processes (e.g., multi-point run).
        logical :: RUNCLIM = .true.
        logical :: RUNCHNL = .true.
        logical :: RUNBALWB = .true.
        logical :: RUNBALEB = .true.
        logical :: RUNTILE = .true.
        logical :: RUNGRID = .true.

    end type !run_options

    !> *****************************************************************
    !> Description: Variable type to store control options. These
    !> options control the structure of the model.
    !> *****************************************************************
    type control_options

        !* PROCESS_ACTIVE: Active processes in the model (not case sensitive), comma-separated.
        !*   CLASS: CLASS 3.6 (default).
        !*   WF_WATROUTE: Original routing routine (default).
        !*   SA_RTE: Offline routing module.
        character(500) :: PROCESS_ACTIVE = 'CLASS,WF_WATROUTE'

    end type

end module
