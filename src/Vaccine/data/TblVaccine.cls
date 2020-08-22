Class Vaccine.data.TblVaccine Extends %Persistent
{

Property VaccineCode As %Library.DynamicObject;

Property ImmunityPeriod As %Library.DynamicObject;

Storage Default
{
<Data name="ImmunityPeriod">
<Attribute>ImmunityPeriod</Attribute>
<Structure>node</Structure>
<Subscript>"ImmunityPeriod"</Subscript>
</Data>
<Data name="TblVaccineDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
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
