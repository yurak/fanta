import { IClub } from "./Club";

export interface ITournament {
  id: number,
  icon: string,
  logo: string,
  name: string,
  short_name: string,
  mantra_format: boolean,
  clubs?: IClub[],
}
