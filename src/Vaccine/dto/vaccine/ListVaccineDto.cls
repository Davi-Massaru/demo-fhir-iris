Class Vaccine.dto.vaccine.ListVaccineDto Extends Vaccine.shared.Dtos
{

Property ListVaccineDto As list Of Vaccine.dto.vaccine.VaccineDto;

Method InsertListVaccineDto(pVaccineDto As Vaccine.dto.vaccine.VaccineDto) As %Status
{
    Do ..ListVaccineDto.Insert(pVaccineDto)
	Return $$$OK
}

Method GetAtListVaccineDto(pIndex As %Integer) As Vaccine.dto.vaccine.VaccineDto
{
    Return ..ListVaccineDto.GetAt(pIndex)
}

Method ListVaccineDtoSet(pLista As %ListOfDataTypes) As %Status
{
    Set ..ListVaccineDto = pLista.%ConstructClone()
    Return $$$OK
}

}
