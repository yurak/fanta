import { IClub } from "./Club";

export interface IClubTransfer {
  id: number,
  start_date: string,
  old_club: IClub | null,
  old_club_name: string | null,
  new_club: IClub | null,
  new_club_name: string,
  fee: string | null,
  market_value: string | null,
  loan: boolean,
}
