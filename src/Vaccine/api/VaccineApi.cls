Class Vaccine.api.VaccineApi Extends %CSP.REST
{

ClassMethod Save() As %Status
{
    Set %response.ContentType = "application/json"
    #Dim vaccineDto AS Vaccine.dto.vaccine.VaccineDto = ##class(%DynamicAbstractObject).%FromJSON(%request.Content.Read())
    Set service = ##class(Vaccine.service.vaccine.VaccineService).%New()
    Return service.Save(vaccineDto)
}

ClassMethod OpenId(pVaccineId)
{
    Set %response.ContentType = "application/json"
    Set service = ##class(Vaccine.service.vaccine.VaccineService).%New()
    Set vaccineDto = service.OpenId(pVaccineId)
    Do vaccineDto.WriteJson()
}

XData UrlMap [ XMLNamespace = "http://www.mynamespace.org" ]
{
<Routes>

<Route Url="/" Method="POST" Call="Save" Cors="false" />
<Route Url="/:pVaccineId" Method="GET" Call="OpenId"  Cors="true"/>

</Routes>
}

}
