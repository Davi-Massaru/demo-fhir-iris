Class Vaccine.api.VaccineGroupApi Extends %CSP.REST
{

ClassMethod Save() As %Status
{
    Set %response.ContentType = "application/json"
    #Dim vaccineGroupDto AS Vaccine.dto.vaccineGroup.VaccineGroupDto = ##class(%DynamicAbstractObject).%FromJSON(%request.Content.Read())
    Set service = ##class(Vaccine.service.vaccineGroup.VaccineGroupService).%New()
    Return service.Save(vaccineGroupDto)
}

ClassMethod OpenId(pVaccineId) As %Status
{
    Set %response.ContentType = "application/json"
    Set service = ##class(Vaccine.service.vaccineGroup.VaccineGroupService).%New()
    Set vaccineDto = service.OpenId(pVaccineId)
    Do vaccineDto.WriteJson()
    Return $$$OK
}

ClassMethod Ping() As %Status
{
    Set %response.ContentType = "application/json"
    w "{ ""ping"": ""OK""}"
    Return $$$OK
}

XData UrlMap
{
<Routes>

<Route Url="/" Method="POST" Call="Save" Cors="false" />
<Route Url="/:pVaccineId" Method="GET" Call="OpenId"  Cors="true"/>
<Route Url="/ping/" Method="GET" Call="Ping"  Cors="true"/>

</Routes>
}

}
