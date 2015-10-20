!---------------------------------------------------------------
!      Output
!---------------------------------------------------------------

subroutine outflac
use arrays
include 'precision.inc'
include 'params.inc'
include 'arrays.inc'

parameter( kindr=4, kindi=4 )

real(kindr), allocatable :: D1d(:),De(:,:),Dn2(:,:,:)
real(kindr) rtime

! define record number and write it to contents
if( lastout .eq. 1 ) then
    nrec = 1
    open (1,file='_contents.0')
else
    open (1,file='_contents.0',status='old',err=5)
    do while (.TRUE.)
        read( 1, *, end=10 ) nrec
    end do
5   continue
    open (1,file='_contents.0',position='append')
    nrec = 0
10  continue
    nrec = nrec + 1
    backspace(1)
endif
write( 1, '(i6,1x,i8,1x,f7.3)' ) nrec, nloop, time/sec_year/1.e6
close(1)

! added (Sept 30, 2015) output of total dissipation
open (1,file='disstime.0',position='append')
write (1,'(2e10.3)') time, disstot
close (1)
! output dispacemnts of surface
open (1,file='dispsurf.0',position='append')
do i =1,nx-1
    write (1,'(3e12.3)') cord(1,i,1), disp(1,i,1), disp(1,i,2)
end do
close (1)
! end of added output (WR Buck - Sept 30, 2015)

! Time
open (1,file='time.0',access='direct',recl=kindr)
rtime = real(time)
write (1,rec=nrec) rtime
close (1) 


! Coordinates in [km]
allocate( Dn2(nz,nx,2) )

nwords = nz*nx*2
Dn2(1:nz,1:nx,1:2) = real(cord(1:nz,1:nx,1:2) / 1000)
open (1,file='mesh.0',access='direct',recl=nwords*kindr) 
write (1,rec=nrec) Dn2
close (1)

! Put displacemnts into the velocity file [m]
if( io_vel.eq.1 ) then
Dn2(1:nz,1:nx,1:2) = real(disp(1:nz,1:nx,1:2))
open (1,file='vel.0',access='direct',recl=nwords*kindr)
write (1,rec=nrec) Dn2
close (1)
endif

! Velocities in [cm/year]
!if( io_vel.eq.1 ) then
!    Dn2(1:nz,1:nx,1:2) = real(vel(1:nz,1:nx,1:2) * sec_year * 100)
!    open (1,file='vel.0',access='direct',recl=nwords*kindr)
!    write (1,rec=nrec) Dn2
!    close (1)
!endif

! Temperature in [Celsius]
if( io_temp.eq.1 ) then
    nwords = nz*nx
    Dn2(1:nz,1:nx,1) = real(temp(1:nz,1:nx))
    open (1,file='temperature.0',access='direct',recl=nwords*kindr)
    write (1,rec=nrec) Dn2(1:nz,1:nx,1)
    close (1)
endif


deallocate( Dn2 )


! 2-D (nx-1)*(nz-1) arrays - elements defined
allocate( De(nz-1,nx-1) )

nwords = (nz-1)*(nx-1)

! Strain rate II
if( io_srII.eq.1 ) then
    do i = 1, nx-1
        do j = 1, nz-1
            if( e2sr(j,i).ne.0. ) then
                De(j,i) = real(dlog10( e2sr(j,i) ))
            else
                De(j,i) = 0
            endif
        enddo
    enddo
    open (1,file='srII.0',access='direct',recl=nwords*kindr) 
    write (1,rec=nrec) De
    close (1)
endif


! Strain
if( io_eII.eq.1 ) then
    do i = 1, nx-1
        do j = 1, nz-1
            De(j,i) = real(strainII(j,i))
        end do
    end do
    open (1,file='eII.0',access='direct',recl=nwords*kindr) 
    write (1,rec=nrec) De
    close (1)
endif

    do i = 1, nx-1
        do j = 1, nz-1
            De(j,i) = real(strainI(j,i))
        end do
    end do
    open (1,file='eI.0',access='direct',recl=nwords*kindr) 
    write (1,rec=nrec) De
    close (1)

! Density 
if( io_mark.eq.1 ) then
   do i = 1, nx-1
   do j = 1, nz-1
          De(j,i) = real(Eff_dens(j,i))
   enddo
   enddo
    open (1,file='density.0',access='direct',recl=nwords*kindr)
    write (1,rec=nrec) De
    close (1)
endif


! APS
if( io_aps.eq.1 ) then
    De(1:nz-1,1:nx-1) = real(aps(1:nz-1,1:nx-1))
    open (1,file='aps.0',access='direct',recl=nwords*kindr) 
    write (1,rec=nrec) De
    close (1)
endif


! Stress II in [kb]
if( io_sII.eq.1 ) then
    do i = 1, nx-1
        do j = 1, nz-1
            De(j,i) = real(stressII(j,i) * 1.e-8)
        end do
    end do
    open (1,file='sII.0',access='direct',recl=nwords*kindr) 
    write (1,rec=nrec) De
    close (1)
endif


! Sxx in [kb]
if( io_sxx.eq.1 ) then
    do i = 1, nx-1
        do j = 1, nz-1
            sxx = 0.25 * (stress0(j,i,1,1)+stress0(j,i,1,2)+stress0(j,i,1,3)+stress0(j,i,1,4) )
            De(j,i) = real(( sxx-stressI(j,i) ) * 1.e-8)
        end do
    end do
    open (1,file='sxx.0',access='direct',recl=nwords*kindr) 
    write (1,rec=nrec) De
    close (1)
endif


! Szz in [kb]
if( io_szz.eq.1 ) then
    do i = 1, nx-1
        do j = 1, nz-1
            szz = 0.25 * (stress0(j,i,2,1)+stress0(j,i,2,2)+stress0(j,i,2,3)+stress0(j,i,2,4) )
            De(j,i) = real(( szz-stressI(j,i) ) * 1.e-8)
        end do
    end do
    open (1,file='szz.0',access='direct',recl=nwords*kindr) 
    write (1,rec=nrec) De
    close (1)
endif


! Sxz in [kb]
if( io_sxz.eq.1 ) then
    do i = 1, nx-1
        do j = 1, nz-1
            sxz = 0.25 * (stress0(j,i,3,1)+stress0(j,i,3,2)+stress0(j,i,3,3)+stress0(j,i,3,4))
            De(j,i) = real(sxz * 1.e-8)
        end do
    end do
    open (1,file='sxz.0',access='direct',recl=nwords*kindr) 
    write (1,rec=nrec) De
    close (1)
endif


! Pressure in [kb]
if( io_pres.eq.1 ) then
    do i = 1, nx-1
        do j = 1, nz-1
            De(j,i) = real(stressI(j,i) * 1.e-8)
        end do
    end do
    open (1,file='pres.0',access='direct',recl=nwords*kindr) 
    write (1,rec=nrec) De
    close (1)
endif


! Temperature
if( io_temp.eq.1 ) then
    do i = 1, nx-1
        do j = 1, nz-1
            De(j,i) = real(0.25*( temp(j,i)+temp(j+1,i)+temp(j,i+1)+temp(j+1,i+1) ))
        end do
    end do
    open (1,file='temp.0',access='direct',recl=nwords*kindr)
    write (1,rec=nrec) De
    close (1)
endif



! Phase
if( io_melt.eq.1 ) then
    open (1,file='phase.0',access='direct',recl=nwords*kindi)
    write (1,rec=nrec) iphase(1:nz-1,1:nx-1)
    close (1)
endif


! Viscosities (log)
if( io_visc.eq.1 ) then
    De(1:nz-1,1:nx-1) = real(dlog10( visn(1:nz-1,1:nx-1) ))
    open (1,file='visc.0',access='direct',recl=nwords*kindr) 
    write (1,rec=nrec) De
    close (1)
endif



! Heat sources
if( io_src.eq.1 ) then
    De(1:nz-1,1:nx-1) = real(source(1:nz-1,1:nx-1))
    open (1,file='src.0',access='direct',recl=nwords*kindr) 
    write (1,rec=nrec) De
    close (1)
endif


! Energy dissipation
if( io_diss.eq.1 ) then
    do i = 1, nx-1
        do j = 1, nz-1
            if(ishearh.ne.0) then
               De(j,i) = sshrheat(j,i)
            else
               De(j,i) = 0
            endif
        enddo
    enddo
    open (1,file='diss.0',access='direct',recl=nwords*kindr) 
    write (1,rec=nrec) De
    close (1)
endif

deallocate( De )


! 1-D nx array - nodes defined
allocate( D1d(nx) )
nwords = nx

! Surface heat flow
if( io_hfl.eq.1 ) then
    do i = 1,nx
        ii = min(i,nx-1)
        dtmpr = temp(2,i) - temp(1,i)
        dl = -(cord(2,i,2)-cord(1,i,2))/1000
        D1d(i) = real(Eff_conduct(1,ii) * dtmpr/dl)
    end do
    open (1,file='hfl.0',access='direct',recl=nwords*kindr)
    write (1,rec=nrec) D1d
    close (1)
endif


! Topo
if( io_topo.eq.1 ) then
    do i = 1,nx
        D1d(i) = real(cord(1,i,2)/1000)
    end do
    open (1,file='topo.0',access='direct',recl=nwords*kindr)
    write (1,rec=nrec) D1d
    close (1)
endif

deallocate( D1d )


return 
end
