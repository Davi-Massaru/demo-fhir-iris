import { HttpClientModule } from '@angular/common/http';

import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { VaccineService } from './vaccine.service';
import { VaccineComponent } from './vaccine/vaccine.component';

@NgModule(
  {
  declarations: [
    VaccineComponent,
  ],
  imports: [
    CommonModule,
    HttpClientModule
  ],
  providers:[
    VaccineService
  ]
})

export class VaccineModule { }
