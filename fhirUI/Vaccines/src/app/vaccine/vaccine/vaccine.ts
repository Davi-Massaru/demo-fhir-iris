export interface Vaccine {
    ID:string,
    immunityPeriod:string,
    vaccineCode:{
        text:string,
        coding:{
                system:string,
                code:string,
                display:string
        }
    }
}