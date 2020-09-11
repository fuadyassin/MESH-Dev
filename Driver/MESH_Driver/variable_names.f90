module variable_names

    implicit none

    !> Meteorology/climatology variables.
    character(len = 10), parameter :: VN_FSIN = 'FSIN'
    character(len = 10), parameter :: VN_FSVH = 'FSVH'
    character(len = 10), parameter :: VN_FSIH = 'FSIH'
    character(len = 10), parameter :: VN_FSDIR = 'FSDIR'
    character(len = 10), parameter :: VN_FSDFF = 'FSDFF'
    character(len = 10), parameter :: VN_FSOUT = 'FSOUT'
    character(len = 10), parameter :: VN_FLIN = 'FLIN'
    character(len = 10), parameter :: VN_FLOUT = 'FLOUT'
    character(len = 10), parameter :: VN_TA = 'TA'
    character(len = 10), parameter :: VN_QA = 'QA'
    character(len = 10), parameter :: VN_PRES = 'PRES'
    character(len = 10), parameter :: VN_UV = 'UV'
    character(len = 10), parameter :: VN_WDIR = 'WDIR'
    character(len = 10), parameter :: VN_UU = 'UU'
    character(len = 10), parameter :: VN_VV = 'VV'
    character(len = 10), parameter :: VN_PRE = 'PRE'
    character(len = 10), parameter :: VN_PRERN = 'PRERN'
    character(len = 10), parameter :: VN_PRESNO = 'PRESNO'
    character(len = 10), parameter :: VN_PREC = 'PREC'
    character(len = 10), parameter :: VN_PRECRN = 'PRECRN'
    character(len = 10), parameter :: VN_PRECSNO = 'PRECSNO'

    !> Canopy variables.
    character(len = 10), parameter :: VN_LQWSCAN = 'LQWSCAN'
    character(len = 10), parameter :: VN_FZWSCAN = 'FZWSCAN'
    character(len = 10), parameter :: VN_CMAS = 'CMAS'
    character(len = 10), parameter :: VN_TCAN = 'TCAN'
    character(len = 10), parameter :: VN_GRO = 'GRO'

    !> Snow variables.
    character(len = 10), parameter :: VN_SNO = 'SNO'
    character(len = 10), parameter :: VN_RHOSNO = 'RHOSNO'
    character(len = 10), parameter :: VN_ZSNO = 'ZSNO'
    character(len = 10), parameter :: VN_FSNO = 'FSNO'
    character(len = 10), parameter :: VN_LQWSSNO = 'LQWSSNO'
    character(len = 10), parameter :: VN_TSNO = 'TSNO'
    character(len = 10), parameter :: VN_DRAINSNO = 'DRAINSNO'

    !> Surface variables.
    character(len = 10), parameter :: VN_ALBT = 'ALBT'
    character(len = 10), parameter :: VN_ALVS = 'ALVS'
    character(len = 10), parameter :: VN_ALIR = 'ALIR'
    character(len = 10), parameter :: VN_GTE = 'GTE'
    character(len = 10), parameter :: VN_ZPND = 'ZPND'
    character(len = 10), parameter :: VN_LQWSPND = 'LQWSPND'
    character(len = 10), parameter :: VN_TPND = 'TPND'
    character(len = 10), parameter :: VN_POTEVP = 'POTEVP'
    character(len = 10), parameter :: VN_ET = 'ET'
    character(len = 10), parameter :: VN_EVPB = 'EVPB'
    character(len = 10), parameter :: VN_ARRD = 'ARRD'
    character(len = 10), parameter :: VN_OVRFLW = 'OVRFLW'
    character(len = 10), parameter :: VN_QEVP = 'QEVP'
    character(len = 10), parameter :: VN_QSENS = 'QSENS'
    character(len = 10), parameter :: VN_GZERO = 'GZERO'

    !> Subsurface/soil variables.
    character(len = 10), parameter :: VN_THLQSOL = 'THLQSOL'
    character(len = 10), parameter :: VN_THICSOL = 'THICSOL'
    character(len = 10), parameter :: VN_LQWSSOL = 'LQWSSOL'
    character(len = 10), parameter :: VN_FZWSSOL = 'FZWSSOL'
    character(len = 10), parameter :: VN_ALWSSOL = 'ALWSSOL'
    character(len = 10), parameter :: VN_TSOL = 'TSOL'
    character(len = 10), parameter :: VN_GFLX = 'GFLX'
    character(len = 10), parameter :: VN_LATFLW = 'LATFLW'
    character(len = 10), parameter :: VN_DRAINSOL = 'DRAINSOL'

    !> Groundwater/lower zone storage variables.
    character(len = 10), parameter :: VN_RCHG = 'RCHG'
    character(len = 10), parameter :: VN_STGGW = 'STGGW'
    character(len = 10), parameter :: VN_DZS = 'DZS'

    !> Diagnostic variables.
    character(len = 10), parameter :: VN_STGE = 'STGE'
    character(len = 10), parameter :: VN_DSTGE = 'DSTGE'
    character(len = 10), parameter :: VN_STGW = 'STGW'
    character(len = 10), parameter :: VN_DSTGW = 'DSTGW'

    !> Routing variables.
    character(len = 10), parameter :: VN_RFF = 'RFF'
    character(len = 10), parameter :: VN_ROF = 'ROF'
    character(len = 10), parameter :: VN_QI = 'QI'
    character(len = 10), parameter :: VN_QO = 'QO'
    character(len = 10), parameter :: VN_STGCH = 'STGCH'
    character(len = 10), parameter :: VN_ZLVL = 'ZLVL'

end module
