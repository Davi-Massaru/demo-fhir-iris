Class Vaccine.dto.vaccine.propertyBuilder.VaccineCodeDto Extends %Library.RegisteredObject
{

Property text As %String;

Property coding As Vaccine.dto.vaccine.propertyBuilder.CodingDto;

Method %OnNew() As %Status
{
    Set ..coding = ##class(Vaccine.dto.vaccine.propertyBuilder.CodingDto).%New()
    Return $$$OK
}

}
