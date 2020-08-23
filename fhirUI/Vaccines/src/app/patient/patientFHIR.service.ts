import { Patient } from './patient';

export class patientFHIRService {
  constructor() { }

  patient: Patient;


  getPatient(KEY){

    fetch("http://localhost:32783/fhir/r4/"+KEY, {
        "headers": {
          "accept": "application/fhir+json",
          "accept-language": "pt-PT,pt;q=0.9,en-US;q=0.8,en;q=0.7",
          "content-type": "application/fhir+json;charset=UTF-8",
          "sec-fetch-dest": "empty",
          "sec-fetch-mode": "cors",
          "sec-fetch-site": "same-origin",
          "x-requested-with": "XMLHttpRequest"
        },
        "referrer": "http://localhost:32783/csp/user/fhirUI/FHIRAppDemo.html",
        "referrerPolicy": "no-referrer-when-downgrade",
        "body": null,
        "method": "GET",
        "mode": "cors",
        "credentials": "include"
      }).then(r => r.json()).then(r => {
          this.patient =r
      });

      return this.patient
  }
}
