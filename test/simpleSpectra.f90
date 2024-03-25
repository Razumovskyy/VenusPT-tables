program simpleSpectra
    use SimpleShapes, only: simpleLorentz
    implicit none
    
    integer, parameter :: DP = selected_real_kind(15, 307)
    integer, parameter :: hitranFileUnit = 7777
    character(len=20), parameter :: hitranFile = 'data/HITRAN16/H16.01'

    real(kind=DP) :: startWV, endWV, step
    real(kind=DP) :: lineWV ! cm-1 (wavenumber of the transition)
    real :: refLineIntensity ! cm-1/(molecule*cm-2) (spectral line intensity at 296 K)
    real :: gammaForeign, gammaSelf ! cm-1/atm (air- and self-broadened HWHM at 296 K)
    real :: lineLowerState ! cm-1 (lower state energy of the transition)
    real :: foreignTempCoeff ! dimensionless (coeff for temp dependence of gammaForeign)
    integer :: jointMolIso ! dimensionless (joined reference to Molecule number (MOL) and Isotopologue number (ISO))
    real :: deltaForeign ! cm^-1/atm (pressure shift of the line position at 296 K and 1 atm)

    real :: pressure ! atm
    real :: density ! molecules/(cm^2*km)

    real(kind=DP), allocatable :: spectra(:,:)
    integer :: len ! len of the spectra array
    integer :: i, j ! loop variables

    ! INPUT PARAMETERS !
    pressure = 1.
    density = 1e19
    startWV = 100.
    endWV = 110.
    step = 0.001
    
    len = int((endWV-startWV) / step) + 1

    allocate(spectra(len, 2))

    lineWV = startWV

    do i = 1, len
        write(*,*) i, ' of ', len, ' is processed'
        spectra(i, 1) = startWV + (i-1) * step
        spectra(i, 2) = 0.
        j = 1
        do
            open(hitranFileUnit, access='DIRECT', form='UNFORMATTED', recl=36, file=hitranFile)
        
            read(hitranFileUnit, rec=j) lineWV, refLineIntensity, gammaForeign, gammaSelf, &
                                    lineLowerState, foreignTempCoeff, jointMolIso, deltaForeign
                                    
            if (lineWV >= endWV) exit

            spectra(i, 2) = spectra(i,2) + simpleLorentz(refLineIntensity, spectra(i,1), lineWV, gammaForeign, pressure, density)
    
            j = j + 1
        end do
    end do

end program simpleSpectra

module SimpleShapes
    implicit none
    integer, parameter :: DP = selected_real_kind(15, 307)
    integer, parameter :: pi = 3.14159
contains
    real function simpleLorentz(intensity, nu, nu0, gammaForeign, pressure, density)
        real(kind=DP) nu, nu0
        real :: intensity
        real :: gammaForeign
        real :: pressure, density
        ! density is of dimension molecule/(cm^2*km). It is needed to have a total absorption coeff to be of km-1
        
        simpleLorentz = (intensity*gammaForeign*pressure*density) / (pi*((nu-nu0)**2 + (gammaForeign*pressure)**2))
    end function simpleLorentz
end module SimpleShapes