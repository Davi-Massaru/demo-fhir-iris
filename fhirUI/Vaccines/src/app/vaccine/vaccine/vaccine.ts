export interface Vaccine {
    ID:number,
    immunityPeriod:string,
    vaccineCode:{
        text:string,
        coding:{
                system:string,
                code:number,
                display:string
        }
    }
}