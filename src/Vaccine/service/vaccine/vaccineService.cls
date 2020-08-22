Class Vaccine.service.vaccine.VaccineService Extends %RegisteredObject
{

Property VaccineDao As Vaccine.dao.vaccine.VaccineDao [ Private ];

Method %OnNew() As %Status
{
    Set VaccineDao = ##class(Vaccine.dao.vaccine.VaccineDao).%New()
    Return $$$OK
}

Method All() As Vaccine.dto.vaccine.ListVaccineDto
{
    Set result = ..VaccineDao.All()
    Set ListVaccineDto = ##class(Vaccine.dto.vaccine.ListVaccineDto).%New()
	While result.%Next(){
		w result.ID
		Set vaccineDto = ..OpenId(result.ID)
		Do ListVaccineDto.InsertListVaccineDto(vaccineDto)
	}

	Return ListVaccineDto
}

Method OpenId(pVaccineId As %String) As Vaccine.dto.vaccine.VaccineDto
{
    Return ..VaccineDao.OpenId(pVaccineId)
}

Method Save(pVaccineDto As Vaccine.dto.vaccine.VaccineDto) As %Status
{
    Return ..VaccineDao.Save(pVaccineDto)
}

Method VaccineDaoGet() As Vaccine.dao.vaccine.VaccineDao [ Private ]
{
	Set:('$ISOBJECT(i%VaccineDao)) i%VaccineDao = ##class(Vaccine.dao.vaccine.VaccineDao).%New()
	Return i%VaccineDao
}

}