Class Vaccine.api.dispath.Dispatch Extends %CSP.REST
{

XData UrlMap
{
<Routes>
<Map Prefix="/vaccine*" Forward="Vaccine.api.VaccineApi"/>
<Map Prefix="/vaccinegroup*" Forward="Vaccine.api.VaccineGroupApi"/>
</Routes>
}

}
