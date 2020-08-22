Class Vaccine.dto.vaccine.VaccineDto Extends Vaccine.shared.Dtos
{

Property ID As %String;

Property immunityPeriod As %String;

Property vaccineCode As Vaccine.dto.vaccine.propertyBuilder.VaccineCodeDto;

Method %OnNew() As %Status
{
    Set ..vaccineCode = ##class(Vaccine.dto.vaccine.propertyBuilder.VaccineCodeDto).%New()
    Return $$$OK
}

}
