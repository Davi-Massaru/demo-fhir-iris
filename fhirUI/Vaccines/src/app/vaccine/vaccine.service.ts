
import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Vaccine } from "./vaccine/vaccine";
import { Patient } from '../patient/patient';
import { patientList } from '../patient/patientList';
import { VaccineList } from './vaccine/vaccineList';

const API = 'http://localhost:32783/fhir/r4/';

@Injectable()
export class VaccineService {

  constructor(private http: HttpClient) { }

  getVaccine(pVaccineId){
    return this.http.get<Vaccine>(API + 'customrestapi/vaccine/' + pVaccineId);  
  }

  getAllVaccines(){
    return this.http.get<VaccineList>(API + 'customrestapi/vaccine/');  
  }

  postVaccines(pVaccine){
    return this.http.post(API + 'customrestapi/vaccine/', pVaccine).subscribe(r => console.log(r));
  }

  checkPatients(pVaccineCode){
    return this.http.get<patientList>(API + 'customrestapi/vaccine/immunitypatients/'+ pVaccineCode);
  }
}
