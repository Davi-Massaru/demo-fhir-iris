Class Vaccine.dto.patient.ListPatientDto Extends Vaccine.shared.Dtos
{

Property ListPatientDto As list Of Vaccine.dto.patient.PatientDto;

Method InsertListPatientDto(pPatientDto As Vaccine.dto.patient.PatientDto) As %Status
{
    Do ..ListPatientDto.Insert(pPatientDto)
	Return $$$OK
}

Method GetAtListPatientDto(pIndex As %Integer) As Vaccine.dto.patient.PatientDto
{
    Return ..ListPatientDto.GetAt(pIndex)
}

Method ListPatientDtoSet(pLista As %ListOfDataTypes) As %Status
{
    Set ..ListPatientDto = pLista.%ConstructClone()
    Return $$$OK
}

}
