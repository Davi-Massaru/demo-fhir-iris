Class Vaccine.service.vaccineGroup.VaccineGroupService Extends %RegisteredObject
{

Property VaccineGroupDao As Vaccine.dao.vaccineGroup.VaccineGroup [ Private ];

Method %OnNew() As %Status
{
    Set VaccineGroup = ##class().%New()
    Return $$$OK
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
