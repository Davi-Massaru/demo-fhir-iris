
import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { VaccineComponent } from './vaccine/vaccine/vaccine.component';


const routes: Routes = [
    { 
        path: 'Vaccines', 
        component: VaccineComponent,
    },
    
];

@NgModule({
    imports: [ 
        RouterModule.forRoot(routes) 
    ],
    exports: [ RouterModule ]
})
export class AppRoutingModule { }

