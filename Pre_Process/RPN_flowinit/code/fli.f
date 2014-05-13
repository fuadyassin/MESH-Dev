C    This file is part of FLOWINIT.
C
C    FLOWINIT is free software: you can redistribute it and/or modify
C    it under the terms of the GNU Lesser General Public License as published by
C    the Free Software Foundation, either version 3 of the License, or
C    (at your option) any later version.
C
C    FLOWINIT is distributed in the hope that it will be useful,
C    but WITHOUT ANY WARRANTY; without even the implied warranty of
C    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
C    GNU Lesser General Public License for more details.
C
C    You should have received a copy of the GNU Lesser General Public License
C    along with FLOWINIT.  If not, see <http://www.gnu.org/licenses/>.

        PROGRAM fli   !watflood

!***********************************************************************
!       copyright (c) by Nick Kouwen 1987-2007
!***********************************************************************

c     April 2010: Daniel Deacu
c     - modified the call to GETARG; this intrinsic function takes only
c       two arguments;
c

        Use area_watflood
	USE EF_Module

      implicit none

c      use DFLIB     ! for sound - take out for unix


!     SAVES THE LOCAL VARIABLES FROM ONE RUN TO NEXT
      SAVE

! TW  MAR. 5/98  - DATA STATEMENT MOVED FROM INPEVT.FOR

!     DATA flgevp2/-1.0/


      CHARACTER(79)   :: comment
      CHARACTER*14    :: date
      CHARACTER(2)    :: aa1
      CHARACTER(1)    :: linetype
!      INTEGER(kind=2) :: result1

      integer*2 result1
      CHARACTER*1028 ApiPacket
      CHARACTER*128   QSTR
      INTEGER*2      status, RESP, len
      integer    ::  io_err,sys_err,stat,unit,cond,nj,iallocate,
     *               ios,nhr,nhf,linecount,ideallocate,iendarg,ix,
     *               file_number
      real*4     ::  conv,scale,smc5(16),cintv,e1
      character(20) :: junk
      CHARACTER(10) :: time
      CHARACTER(8)  :: cday
c      INTEGER(2) status1
      CHARACTER(1) buf,stopflg,ensimopenflg
      logical       :: exists

!     this part from options.for
c      CHARACTER(128):: qstr
c      CHARACTER(72) :: junk
!      CHARACTER(14) :: date
      CHARACTER(1)  :: smok 
      INTEGER    :: iallcnt,icnt(5),ndir(5),nchr,
     *     igrdshft,iyshiftmin,iyshiftmax,
     *     jxshiftmin,jxshiftmax,ishift,jshift,inum,jnum,
     *     l,iw1,iw2,iv,iflg,i,j,iallcnt2
      REAL(4)    :: errold(5),err(5),chng(5),best(5)
      REAL(4)    :: optlow,ddtemp,cc1,cc2,crit,best1
      real(4)    :: optlast
      integer*2  :: ntest

!      DATA ntest/-1358/qstr/'options'/nchr/7/
      DATA ntest/43814/qstr/'optionsss'/nchr/9/
      DATA iallcnt/0/


      print*,'*********************************************************'
      print*,'*                                                       *'
      print*,'* FFFFFFF LL                     IIII                   *'
      print*,'* FFFFFFF LL                      II                    *'
      print*,'* FF      LL                      II                    *'
      print*,'* FF      LL      ooo ww ww    ww II   N   N  II  TTTTT *'
      print*,'* FFFFF   LL     oo oo ww ww  ww  II   NN  N  II    T   *'
      print*,'* FFFFF   LL     oo oo  ww wwww   II   N N N  II    T   *'
      print*,'* FF      LLLLLL oo oo   ww ww    II   N  NN  II    T   *'
      print*,'* FF      LLLLLL  ooo     www    IIII  N   N  II    T   *'
      print*,'*                                                       *'
      print*,'*                  WATFLOOD (TM)                        *'
      print*,'*           Version 9.3    Apr  17, 2007                *'
      print*,'*           (c) N. Kouwen, 1972-2007                    *'
      print*,'*                                                       *'
      print*,'*********************************************************'
      print*



c      CALL GETARG(1, buf, status1)
c      if(status1.ne.1)buf=' '
      CALL GETARG(1, buf)       ! ddeacu
      if(buf.eq.'0')then
         iopt=0
      elseif(buf.eq.'1')then
         iopt=1
         stopflg='y'
      elseif(buf.eq.'2')then
         iopt=2
      elseif(buf.eq.'3')then
         iopt=2
      elseif(buf.eq.'4')then
         iopt=2
      elseif(buf.eq.'9')then
!       rev. 9.1.63  Sep.  29/04  - NK: Added iopt_start as an arg for quick filecheck
         iopt_start=99
      endif

c	translateflg='n'  ! used on translate.for if 'y'
c      ittoflg=0
c      ssmc_firstpass='y'
c      flgevp2=-1.0
c      ensimopenflg='n'

c!     TS - ALLOCATION FOR AREA12A ARRAYS
c      allocate(fln(601),filename(200),outfln(100),stat=iAllocate)
      allocate(fln(100),filename(100),outfln(100),infln(100),
     *         stat=iAllocate)
      if (iAllocate.ne.0) STOP 
     *     'Warning: error with allocation of area12a arrays In fli9' 

! SET DEFALUT FILENAMES FOR OUTPUT FILES:
!     these names may be replaced with the outfiles.txt file in the working
!     directory to send the files to a designated place for output.
!     A default outfiles.new file is created in the working directory each 
!     time this program is run.

      do i=51,100
      filename(i)='..'
      end do

      filename(51)='fli.txt' !program information
c     filename(52)='rte.r2c'      !output
!      filename(52)='fli.r2c'    !output  assigned in fli
      filename(52)='res_fli.txt' !reservoir data
      filename(53)='route_fli.txt' !routing data
      filename(54)='spl_fli.csv' !paired observed/computed
      filename(57)='resin_fli.txt' !lake inflow obs/computed
!dgp  units 60,61 because they're not used in rte
      filename(60)='flow_init.r2c'
      filename(61)='lzs_init.r2c'
      filename(98)='fli_info.txt'
      filename(99)='scratch5'   ! reserved as scratch file
      filename(100)='scratch6'  ! not used


      iendarg=0

!     id is used as a flag. when id=0 openfiles:
      id=1                      ! used in rdevt
c      ni=1         !not used like this now  nk Apr. 8/03


      ioflg=0
! ioflg IS THE NUMBER OF OUTPUT FILES LISTED IN OUTFILES.TXT
! so it's value will be changed then


!     open fli_info.txt     
      open(unit=98,file=filename(98),status='unknown',iostat=ios)
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      if(ios.ne.0)call io_warning(98,filename(98),ios)
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      call date_and_time(cday,time)
      write(98,6016)time(1:2),time(3:4),time(5:6)
      write(98,6017)cday(1:4),cday(5:6),cday(7:8)
      write(98,5005)


      i=51
      if(ioflg.gt.1)then
         filename(i)=outfln(i)
      endif
      open(unit=i,file=filename(i),access='sequential',
     *     recl=2096,status='unknown',iostat=ios)
!       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      if(ios.ne.0)call io_warning(i,filename(i),ios)
!       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      call date_and_time(cday,time)
      write(51,6016)time(1:2),time(3:4),time(5:6)
      write(51,6017)cday(1:4),cday(5:6),cday(7:8)
      write(51,*)
      write(51,5003)i,filename(i)

!dgp  from rte.f
! THE OUTFILES.TXT FILE READS THE NAMES OF ALL THE OUTPUT FILES
      ioflg=0 ! # of output files listed in outfiles_fli.txt
      INQUIRE(FILE='outfiles_fli.txt',EXIST=exists)
      if(exists)then
!         AN OUTFILES.TXT FILE EXISTS AND WE'LL READ IT:
        open(unit=99,file='outfiles_fli.txt',
     *               status='old',iostat=ios)
        if(ios.eq.0)then
          print*,'reading outfile names from outfiles_fli.txt'
          do i=51,100
            read(99,5001,iostat=ios)outfln(i)
            write(51,'(a)') trim(outfln(i))
            if(ios.ne.0)then
              print*,'Problems on unit 99'
              print*,'Warning: error reading file name outfiles_fli.txt'
              print*,'possible cause: existing file is read-only'
              print*,'or end of file is reached - need 50 lines'
              print*,'iostat code =',ios
              print*,'Got as far as line ',i-50
              STOP 'program aborted in spl.for @ 345'
            endif
            ioflg=i
          end do
          close(unit=99)
        else
          print*,'Error opening outfiles_fli.txt'
          print*,'Continuing using default output files'
        endif
      else
        print*,'outfiles_fli.txt file not found, defaults used'
        print*
      endif

!dgp  from rte.f
! ORIGINAL FILEIO.FI SECTION - STARTS HERE:

!   LEAVE FILEIO HERE BECAUSE rdevtA READS FILE NAMES THAT HAVE TO BE OPENED

!   Rev. 7.78 modified for error checking - Sept.29/96  AC flight
!   Rev  7.9  modified to open files for evaporation output
!   Rev. 8.3  - May.  22/97 -     added the simout/outfiles capability

!   THIS IS TO OPEN AND READ THE OPTIONAL OUTFILES.TXT FILE THAT SETS
!   THE LOCATIONS OF THE OUTPUT FILES.  IF FILE DOES NOT EXIST, DEFAULT
!   NAMES WILL BE USED.

      write(51,5002)
      do i=52,100
        if(ioflg.gt.1 .and. len_trim(outfln(i)).gt.2)then
          filename(i)=outfln(i)
        endif
      end do

      if(iopt.eq.2)print*, ' In spl -1001'

      write(51,5002)
      write(51,1030)(i,i,filename(i),i=51,100)

      INQUIRE(FILE='infiles_fli.txt',EXIST=exists)
      if(exists)then
        open(unit=99,file='infiles_fli.txt',
     *               status='old',iostat=ios)
        if(ios.eq.0)then
!         AN INFILES.TXT FILE EXISTS AND WE'LL READ IT:
          print*,'reading infile names from infiles_fli.txt'
          do i=1,50
            read(99,5001,iostat=ios)infln(i)
            if(ios.ne.0)then
              print*,'Problems on unit 99'
              print*,'Warning: error reading file name infiles_fli.txt'
              print*,'possible cause: end of file is reached'
              print*,' - need 50 lines'
              print*,'iostat code =',ios
              print*,'Got as far as line ',i-100
              STOP 'program aborted in spl.for @ 345b'
            endif
            ioflg=i
          end do
          close(unit=99)
        else
          print*,'Error opening infiles_fli.txt'
          print*,'Continuing using default input files'
        endif
      else
        print*,'infiles_fli.txt file not found, defaults used'
        print*
      end if

!dgp  from rte.f
!      fln(99)='event/event.evt'
      if (len_trim(infln(1)) .gt. 2) then
        fln(99)=infln(1)
      else
        fln(99)='event/event.evt'
      end if

      if(iopt.eq.2)print*, 'In fli: 1 - before rdevt call'

!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      call rdevt(date,conv,scale,smc5,nhr,nhf)
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      i=52
c        if(ioflg.gt.1)then
c          filename(i)=outfln(i)
c        endif
      open(unit=i,file=filename(i),access='sequential',
     *     status='unknown',iostat=ios)
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      if(ios.ne.0)call io_warning(i,filename(i),ios)
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      write(51,5003)i,filename(i)


      i=53
c        if(ioflg.gt.1)then
c          filename(i)=outfln(i)
c        endif
      open(unit=i,file=filename(i),access='sequential',
     *     status='unknown',iostat=ios)
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      if(ios.ne.0)call io_warning(i,filename(i),ios)
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      write(51,5003)i,filename(i)

      i=57
      if(ioflg.gt.1)then
         filename(i)=outfln(i)
      endif
      open(unit=i,file=filename(i),access='sequential',
     *     status='unknown',iostat=ios)
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      if(ios.ne.0)call io_warning(i,filename(i),ios)
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      write(51,5003)i,filename(i)

      if(iopt.eq.2)print*, ' In fli -1001'

      write(51,6015)
     *     time(1:2),time(3:4),time(5:6),cday(1:4),cday(5:6),cday(7:8)

!      write(51,6015) hrs,mins,secs,day,month,year

99905 write(51,1000)fln(10),fln(1)
      write(52,1000)fln(10),fln(1)

      if(iopt.eq.2)print*, ' In fli - 1183'


      if(iopt.eq.2)print*, ' In fli - 1190'



!     SHED READS IN ALL THE WATERSHED DATA, FROM SEPERATE PROGRAM:

      if(IsFileTypeR2C(fln(1))) then
         if(iopt.eq.2)print*, ' In fli - before call shed'
!     read the shed file: bsnm_shd.r2c
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         call read_shed_ef(31,1)	
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!     read the parameter file:  bsnm_ch_par.r2c
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         call read_shed_ef(271,41)	
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      else
         print*,'Old format shd files not accepted'
         print*,'Please create EF ????_shd.r2c files & rerun'
         stop 'Program aborted in fli @ 406'
      endif

      if(iopt.eq.2)print*, ' In fli - before allocate'


      allocate(qrgrid(ycount+10,xcount+10),stat=iAllocate)
      if(iAllocate.ne.0) STOP
     *     'Error with allocation of area16a arrays In fli9'

!       Initialize these values because many are outside grid
!       and would otherwise be undifined.  nk June 11/03
      do i=1,ycount+10
         do j=1,xcount+10
            qrgrid(i,j)=0.0
         end do
      end do

      allocate(nhyd(ycount,xcount),nbasin(ycount,xcount),
     *     stat=iAllocate)
      if(iAllocate.ne.0) STOP
     *     'Error with allocation of nhyd array in fli'

      allocate(p(ycount,xcount),stat=iAllocate)
      if(iAllocate.ne.0) STOP
     *     'Error with allocation of p() array In fli9'

      mo=mo1
 
!     basin/bsnm.par
!      open(unit=32 ,file=fln(2) ,status='old',iostat=ios) !ch_par is already read above
!      if(ios.ne.0)then
!         print*,'Problems on unit 32'
!         write(*,99172)fln(2)
!         write(51,99172)fln(2)
!99172    format(' Warning: Error opening or reading fln:',a30/
!     *    ' Probable cause: missing basin/bsnm.par input file'/
!     *    ' OR: in config.sys have you set files=100 & buffers=50?'/)
!         print*,'iostat code =',ios
!         STOP 'program aborted In fli.for @ 372'
!      endif

	
!      if(iopt.eq.2)print*, ' In fli - before call rdpar'

!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
C      call rdpar(1,ix,e1)
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


!     WARNING: DON'T COMBINE NEXT SEGMENT WITH PREVIOUS SEGMENT 
!     BECAUSE IGRDSHFT CAN BE SET = 0 IN THE FILE (i.e. NO IOS ERROR)
c      if(igrdshft.le.0)then
      maxn=1

      id=1     !  needed for proper initialization in read_flow_ef

!     read the streamflow file for the initial flows
!     only one line of data needed

     
!      if(IsFileTypeTB0(fln(6))) then
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         call read_flow_ef('0',date) !EnSim compatible tb0 file
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!      else
!         print*,'Old format str files not accepted'
!         print*,'Please create EF yyyymmdd_str.tb0 files & rerun'
!         stop 'Program aborted in fli @ 142'
!      endif

      allocate(outarray(ycount,xcount),stat=iAllocate)
      if(iAllocate.ne.0) STOP
     *     'Error with allocation of ensim arrays in fli'      
      iallcnt2=2
      if(iopt.eq.2)print*,' in fli, passed location  201'

c
      index=1
      month1=mo1

      if(iopt.eq.2)print*,' In fli - gone to read_resv_ef'

!     read the reservoir release file for the initial releases
!     only one line of data needed

!      if(IsFileTypeTB0(fln(7)))then
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
         call read_resv_ef()    !EnSim compatible tb0 file
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!      else
!         print*,'Old format rel files not accepted'
!         print*,'Please create EF yyyymmdd_rel.tb0 files & rerun'
!         stop 'Program aborted in fli @ 142'
!      endif

      if(iopt.eq.2)print*,' In fli - back from read_resv_ef'
      write(51,*)'releases read'

      if(iopt.eq.2)print*,'in fli, gone to flowinit'
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      call flowinit()
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      if(iopt.eq.2)print*,'in fli, back from flowinit'

      author='fli.exe (flowinit)  '

!      fln(99)='flow_init.r2c'
      if (len_trim(outfln(60)) .gt. 2) then
        fln(99)=outfln(60)
      else
        fln(99)=filename(60)
      end if

!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      call write_flowinit()
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

!      fln(99)='lzs_init.r2c'
      if (len_trim(outfln(61)) .gt. 2) then
        fln(99)=outfln(61)
      else
        fln(99)=filename(61)
      end if

!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      call write_lzsinit()
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      stop ' normal ending'


! FORMATS

 1000 format(' ',2(' ',a30))
 1030 format(' ','Unit no. =',i3,' file no',i3,' = ',a30)
 5001 format(a)
 5002 format(/' output files')
 5003 format(' opened unit'i5,' file neame ',a30)
 5005 format(' Files opened:')
 6015 format(' runtime  ',a2,':',a2,':',a2,2x,a4,'-',a2,'-',a2)
 6016 format('  runtime    ',2(a2,':'),a2)
 6017 format('  rundate  ',a4,'-',a2,'-',a2)
     

      END PROGRAM fli     
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      subroutine io_warning(unit_number,file_name,ios)

c      use area12

      use area_watflood

      integer  :: unit_number,ios
      character*30  :: file_name

      print*,'Problems on unit',unit_number
      print*,'Warning:'
      print*,' error in opening file name  ',file_name
      print*,'possible cause: existing file is read-only'
      print*,'or folder does not exist    <<<'
      print*,'or file does not exist      <<<'
      print*,'or DISK does not exist      <<<'
      Print*
      print*,'iostat code =',ios
      print*
      
      STOP 'program aborted in io-warning.for (fli)  @1054'


      end subroutine io_warning

