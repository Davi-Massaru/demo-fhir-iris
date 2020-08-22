Class Vaccine.data.TblVaccineGroup Extends %Persistent
{

Property Accines As list Of Vaccine.data.TblVaccine;

Property PatientPerfilQueryStructure As list Of %Library.DynamicObject;

Storage Default
{
<Data name="TblVaccineGroupDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Accines</Value>
</Value>
<Value name="3">
<Value>PatientPerfilQueryStructure</Value>
</Value>
</Data>
<DataLocation>^Vaccine.data.TblVaccineGroupD</DataLocation>
<DefaultData>TblVaccineGroupDefaultData</DefaultData>
<IdLocation>^Vaccine.data.TblVaccineGroupD</IdLocation>
<IndexLocation>^Vaccine.data.TblVaccineGroupI</IndexLocation>
<StreamLocation>^Vaccine.data.TblVaccineGroupS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
