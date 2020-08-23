import { VaccineList } from './vaccineList';

import { Component, OnInit } from '@angular/core';
import { HttpClientModule } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Vaccine } from './vaccine';
import { VaccineService } from './../vaccine.service';
import { observable } from 'rxjs';


@Component({
  selector: 'app-vaccine',
  templateUrl: './vaccine.component.html',
  styleUrls: ['./vaccine.component.css']
})

@Injectable({ providedIn: 'root'})

export class VaccineComponent implements OnInit {

  vaccineList: VaccineList;
  vaccine : Vaccine = {
     ID:null,
    immunityPeriod:"",
    vaccineCode:{
        text:"",
        coding:{
                system:"",
                code:null,
                display:""
        }
    }
  };

  constructor(    
    private service: VaccineService
    ) { }

  ngOnInit(): void {
    this.service.getAllVaccines().subscribe(vaccines =>  {this.vaccineList =  vaccines; console.log(this.vaccineList)});
  }

  buildModel(pVaccine){
    this.vaccine =pVaccine;
  }

}
