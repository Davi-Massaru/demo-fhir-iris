
import { Component, OnInit } from '@angular/core';
import { Injectable } from '@angular/core';

import { Vaccine } from './vaccine';
import { VaccineList } from './vaccineList';
import { VaccineService } from './../vaccine.service';

@Component({
  selector: 'app-vaccine',
  templateUrl: './vaccine.component.html',
  styleUrls: ['./vaccine.component.css']
})

@Injectable({ providedIn: 'root'})

export class VaccineComponent implements OnInit {


  vaccineList: VaccineList = { ListVaccineDto: [] };
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
    private service: VaccineService
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
  }

  postNewVaccine(){
    this.vaccine.ID = ""
    this.service.postVaccines(this.vaccine);
    this.buildVaccineList()
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
  
  }
}
