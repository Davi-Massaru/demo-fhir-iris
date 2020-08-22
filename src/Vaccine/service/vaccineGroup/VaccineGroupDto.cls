Class Vaccine.service.vaccineGroup.VaccineGroupService Extends %RegisteredObject
{

Property VaccineGroupDao As Vaccine.dao.vaccineGroup.VaccineGroupDao [ Private ];

Method %OnNew() As %Status
{
    Set i%VaccineGroupDao = ##class(Vaccine.dao.vaccineGroup.VaccineGroupDao).%New()
    Return $$$OK
}

Method OpenId(pVaccineId As %String) As Vaccine.dto.vaccine.VaccineDto
{
    Return ..VaccineGroupDao.OpenId(pVaccineId)
}

Method Save(pVaccineDto As Vaccine.dto.vaccine.VaccineDto) As %Status
{
    Return ..VaccineGroupDao.Save(pVaccineDto)
}

Method All() As Vaccine.dto.vaccine.ListVaccineDto
{
    Set result = ..VaccineGroupDao.All()
}

Method VaccineDaoGet() As Vaccine.dao.vaccineGroup.VaccineGroupDao [ Private ]
{
	Set:('$ISOBJECT(i%VaccineGroupDao)) i%VaccineGroupDao = ##class(Vaccine.dao.vaccineGroup.VaccineGroupDao).%New()
	Return i%VaccineGroupDao
}

}
