import { patientFHIRService } from './../../patient/patientFHIR.service';

import { Component, OnInit } from '@angular/core';
import { Injectable } from '@angular/core';

import { Vaccine } from './vaccine';
import { VaccineList } from './vaccineList';
import { VaccineService } from './../vaccine.service';
import { patientList } from 'src/app/patient/patientList';

@Component({
  selector: 'app-vaccine',
  templateUrl: './vaccine.component.html',
  styleUrls: ['./vaccine.component.css']
})

@Injectable({ providedIn: 'root'})

export class VaccineComponent implements OnInit {


  vaccineList: VaccineList = { ListVaccineDto: [] };
  patientList: patientList = { ListPatientDto: []} 

  vaccine : Vaccine = {
    ID:"",
    immunityPeriod:"",
    vaccineCode:{
        text:"",
        coding:{
                system:"",
                code:"",
                display:""
        }
    }
  };



  constructor(    
    private service: VaccineService,
    private fhirService: patientFHIRService
    ) { }

  ngOnInit(): void {
    this.buildVaccineList()
  }
  
  buildVaccineList(): void{
    this.service.getAllVaccines().subscribe(r =>  {this.vaccineList =  r;});
  }


  buildModel(pVaccine): void{
    this.vaccine = Object.assign(pVaccine);
    console.log(this.vaccine)
  }

  postVaccine() {
    this.service.postVaccines(this.vaccine);
    this.buildVaccineList()
    this.resetVaccine()
  }

  postNewVaccine(){
    this.vaccine.ID = ""
    this.service.postVaccines(this.vaccine);
    this.buildVaccineList()
    this.resetVaccine()
  }

  resetVaccine(){
        this.vaccine = {
          ID:"",
          immunityPeriod:"",
          vaccineCode:{
              text:"",
              coding:{
                      system:"",
                      code:"",
                      display:""
              }
          }
      };
      this.buildVaccineList()

  }

  checkPatients()  {
    let  listResultPatient = []
    this.service.checkPatients(this.vaccine.vaccineCode.coding.code).subscribe(r =>{this.patientList = r; });

    this.patientList.ListPatientDto.forEach(patientDto => {

      let resultPatient = this.fhirService.getPatient(patientDto.KEY)
      listResultPatient.push(resultPatient);

      });

    return listResultPatient
  }
  

}
