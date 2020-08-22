Class Vaccine.data.TblVaccine Extends %Persistent
{

Property VaccineCode As %Library.DynamicObject;

Property ImmunityPeriod As %String;

Storage Default
{
<Data name="TblVaccineDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ImmunityPeriod</Value>
</Value>
</Data>
<Data name="VaccineCode">
<Attribute>VaccineCode</Attribute>
<Structure>node</Structure>
<Subscript>"VaccineCode"</Subscript>
</Data>
<DataLocation>^Vaccine.data.TblVaccineD</DataLocation>
<DefaultData>TblVaccineDefaultData</DefaultData>
<IdLocation>^Vaccine.data.TblVaccineD</IdLocation>
<IndexLocation>^Vaccine.data.TblVaccineI</IndexLocation>
<StreamLocation>^Vaccine.data.TblVaccineS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
