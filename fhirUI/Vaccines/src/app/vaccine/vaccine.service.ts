import { VaccineList } from './vaccine/vaccineList';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Vaccine } from "./vaccine/vaccine";

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

  postVaccines(pVaccine:Vaccine){
    return this.http.post<Vaccine>(API + 'customrestapi/vaccine/', pVaccine)
  }

}
