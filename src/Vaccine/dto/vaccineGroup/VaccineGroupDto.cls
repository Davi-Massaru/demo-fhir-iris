Class Vaccine.dto.vaccineGroup.VaccineGroupDto Extends Vaccine.shared.Dtos
{

Property Vaccines As list Of Vaccine.dto.vaccine.VaccineDto;

Property PatientPerfilQueryStructure As %String;

Method InsertVaccine(pVaccine As Vaccine.dto.vaccine.VaccineDto) As %Status
{
    Do ..Vaccines.Insert(pVaccine)
	Return $$$OK
}

Method GetVaccineFromIndex(pIndex) As Vaccine.dto.vaccine.VaccineDto
{
    Return ..Vaccines.GetAt(pIndex)
}

Method CountVaccines() As %Integer
{
    Return ..Vaccines.Count()
}

}
