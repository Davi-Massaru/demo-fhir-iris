import { patientFHIRService } from './patient/patientFHIR.service';
import { HttpClientModule } from '@angular/common/http';

import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { AppRoutingModule } from './app.routing.module';
import { VaccineService } from './vaccine/vaccine.service';
import { FormsModule } from '@angular/forms';
import { AppComponent } from './app.component';
import { VaccineComponent } from './vaccine/vaccine/vaccine.component';

@NgModule({
  declarations: [
    AppComponent,
    VaccineComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    FormsModule,
    HttpClientModule
  ],
  providers: [VaccineService,patientFHIRService],
  bootstrap: [AppComponent]
})
export class AppModule { }
