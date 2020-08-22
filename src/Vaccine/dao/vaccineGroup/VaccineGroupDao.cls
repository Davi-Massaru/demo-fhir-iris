Class Vaccine.dao.vaccineGroup.VaccineGroupDao Extends %RegisteredObject
{

Method OpenId(pVaccineGroupId As %String) As Vaccine.dto.vaccineGroup.VaccineGroupDto
{
    Set TblVaccineGroup = ##class(Vaccine.data.TblVaccineGroup).%OpenId(pVaccineId)
	Set vaccineGroupDto = ##class(Vaccine.dto.vaccineGroup.VaccineGroupDto).%New()

    Set vaccineGroupDto.ID                          = TblVaccineGroup.%Id()
    Set vaccineGroupDto.PatientPerfilQueryStructure = TblVaccineGroup.PatientPerfilQueryStructure
    Set vaccineGroupDto.Vaccines                    = TblVaccineGroup.Vaccines

    Return vaccineGroupDto
}

Method Save(pVaccineGroupDto As Vaccine.dto.vaccineGroup.VaccineGroupDto) As %Status
{
    Set TblVaccineGroup = ##class(Vaccine.data.TblVaccineGroup).%New()
    If (pVaccineGroupDto.ID '= "") {
        Set:(##class(Vaccine.data.TblVaccineGroup).%ExistsId(pVaccineGroupDto.ID)) TblVaccineGroup = ##class(Vaccine.data.TblVaccineGroup).%OpenId(pVaccineGroupDto.ID)
    }

    Set TblVaccineGroup.PatientPerfilQueryStructure = pVaccineGroupDto.PatientPerfilQueryStructure
    Set TblVaccineGroup.Vaccines = ..ConvertListOfVaccinesDtoToListOfVaccinesData(pVaccineGroupDto.Vaccines)

    Return TblVaccineGroup.%Save()
}

Method ConvertListOfVaccinesDtoToListOfVaccinesData(pVaccineGroupDto As Vaccine.dto.vaccineGroup.VaccineGroupDto) As %ListOfDataTypes
{
    Set vaccinelist = ##class(%ListOfDataTypes).%New()
    Set amountVaccine = pVaccineGroupDto.CountVaccines()
    For i=1:1:amountVaccine{
        Set TblVaccine = ##class(Vaccine.data.TblVaccine).%OpenId(pVaccineGroupDto.GetVaccineFromIndex(i))
        Do vaccinelist.Insert(TblVaccine)
    }

    Return vaccinelist
}

}
