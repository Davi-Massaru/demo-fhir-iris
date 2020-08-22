Class Vaccine.dto.vaccine.VaccineDto Extends Vaccine.shared.Dtos
{

Property ID As %String;

Property immunityPeriod As %String;

Property vaccineCode As Vaccine.dto.vaccine.propertyBuilder.vaccineCode;

Method %OnNew() As %Status
{
    Set ..vaccineCode = ##class(Vaccine.dto.vaccine.propertyBuilder.vaccineCode).%New()
    Return $$$OK
}

Method ConverToInsertFild() As %Library.DynamicObject
{
    Set VaccineCode = {}
    Set VaccineCode.code = ..vaccineCode.coding.code
    Set VaccineCode.system = ..vaccineCode.coding.system
    Set VaccineCode.text = ..vaccineCode.text
    Set VaccineCode.display = ..vaccineCode.coding.display
    Return VaccineCode
}

}
