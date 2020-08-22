Class Vaccine.data.TblVaccineGroup Extends %Persistent
{

Property Vaccines As list Of Vaccine.data.TblVaccine;

Property PatientPerfilQueryStructure As %Library.DynamicObject;

Storage Default
{
<Data name="PatientPerfilQueryStructure">
<Attribute>PatientPerfilQueryStructure</Attribute>
<Structure>node</Structure>
<Subscript>"PatientPerfilQueryStructure"</Subscript>
</Data>
<Data name="TblVaccineGroupDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Vaccines</Value>
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
