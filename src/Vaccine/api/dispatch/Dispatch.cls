Class Vaccine.api.dispath.Dispatch Extends %CSP.REST
{

XData UrlMap [ XMLNamespace = "http://www.mynamespace.org" ]
{
<Routes>
<Map Prefix="/VaccineApi*" Forward="Vaccine.api.VaccineApi"/>
</Routes>
}

}
