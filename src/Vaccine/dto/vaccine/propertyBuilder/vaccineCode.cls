Class Vaccine.dto.vaccine.propertyBuilder.vaccineCode Extends %Library.RegisteredObject
{

Property text As %String;

Property coding As Vaccine.dto.vaccine.propertyBuilder.coding;

Method %OnNew() As %Status
{
    Set ..coding = ##class(Vaccine.dto.vaccine.propertyBuilder.coding).%New()
    Return $$$OK
}

}
