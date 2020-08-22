Class Vaccine.dao.vaccine.VaccineDao Extends %RegisteredObject
{

Method OpenId(pVaccineId As %String) As Vaccine.dto.vaccine.VaccineDto
{
    Set TblVaccine = ##class(Vaccine.data.TblVaccine).%OpenId(pVaccineId)
	Set vaccineDto = ##class(Vaccine.dto.vaccine.VaccineDto).%New()

    Set vaccineDto.ID                         = TblVaccine.%Id()
    Set vaccineDto.immunityPeriod             = TblVaccine.ImmunityPeriod

    Set vaccineDto.vaccineCode.text           = TblVaccine.VaccineCode.text
    Set vaccineDto.vaccineCode.coding.code    = TblVaccine.VaccineCode.coding.code
    Set vaccineDto.vaccineCode.coding.system  = TblVaccine.VaccineCode.coding.system
    Set vaccineDto.vaccineCode.coding.display = TblVaccine.VaccineCode.coding.display
    Return vaccineDto
}

Method Save(pVaccineDto As Vaccine.dto.vaccine.VaccineDto) As %Status
{

    Set TblVaccine = ##class(Vaccine.data.TblVaccine).%New()
    If (pVaccineDto.ID '= "") {
        Set:(##class(Vaccine.data.TblVaccine).%ExistsId(pVaccineDto.ID)) TblVaccine = ##class(Vaccine.data.TblVaccine).%OpenId(pVaccineDto.ID)
    }

    Set TblVaccine.VaccineCode = pVaccineDto.vaccineCode
    Set TblVaccine.ImmunityPeriod = pVaccineDto.immunityPeriod
   
    Return TblVaccine.%Save()
}

}
