Class Vaccine.api.VaccineApi Extends %CSP.REST
{

ClassMethod Save() As %Status
{
    Set %response.ContentType = "application/json"
    #Dim vaccineDto AS Vaccine.dto.vaccine.VaccineDto = ##class(%DynamicAbstractObject).%FromJSON(%request.Content.Read())
    Set service = ##class(Vaccine.service.vaccine.VaccineService).%New()
    Return service.Save(vaccineDto)
}

ClassMethod OpenId(pVaccineId) As %Status
{
    Set %response.ContentType = "application/json"
    Set service = ##class(Vaccine.service.vaccine.VaccineService).%New()
    Set vaccineDto = service.OpenId(pVaccineId)
    Do vaccineDto.WriteJson()
    Return $$$OK
}

ClassMethod AllVaccines() As %Status
{
    Set %response.ContentType = "application/json"
    Set service = ##class(Vaccine.service.vaccine.VaccineService).%New()
    Set AllvaccineDto = service.All()
    Do AllvaccineDto.WriteJson()
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
<Route Url="/" Method="GET" Call="AllVaccines"  Cors="true"/>
<Route Url="/ping/" Method="GET" Call="Ping"  Cors="true"/>

</Routes>
}

}
