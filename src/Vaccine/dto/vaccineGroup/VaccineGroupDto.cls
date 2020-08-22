Class Vaccine.dto.vaccineGroup.VaccineGroupDto Extends Vaccine.shared.Dtos
{

Property ID As %String;

Property Vaccines As list Of Vaccine.dto.vaccine.VaccineDto;

Property PatientPerfilQueryStructure As %Library.DynamicObject;

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

Method VaccinesSet(pListOfVaccines As %ListOfDataTypes) As %Status
{
    Set ..Vaccines = pListOfVaccines.%ConstructClone()
    Return $$$OK
}

}
