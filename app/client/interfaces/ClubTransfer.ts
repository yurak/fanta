import { IClub } from "./Club";

export interface IClubTransfer {
  id: number,
  start_date: string,
  old_club: IClub | null,
  old_club_name: string | null,
  new_club: IClub | null,
  new_club_name: string,
  contract_expires_on: string | null,
  loan: boolean,
}
