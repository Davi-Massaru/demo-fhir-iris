Class Vaccine.data.TblVaccine Extends %Persistent
{

Property vaccineCode As %Library.DynamicObject;

Property immunityPeriod As %Library.DynamicObject;

Storage Default
{
<Data name="TblVaccineDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>vaccineCode</Value>
</Value>
<Value name="3">
<Value>immunityPeriod</Value>
</Value>
</Data>
<DataLocation>^Vaccine.data.TblVaccineD</DataLocation>
<DefaultData>TblVaccineDefaultData</DefaultData>
<IdLocation>^Vaccine.data.TblVaccineD</IdLocation>
<IndexLocation>^Vaccine.data.TblVaccineI</IndexLocation>'
<StreamLocation>^Vaccine.data.TblVaccineS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
