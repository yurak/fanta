import { IClub } from "./Club";
import { Position } from "./Position";

export interface IRoundPlayer {
  id: number,
  player_id: number,
  name: string,
  first_name: string,
  avatar_path: string,
  kit_path: string | null,
  position_classic_arr: Position[],
  position_ital_arr: string[],
  club: IClub,
  base_score: number | null,
  result_score: number,
  appearances: number | null,
  main_appearances: number | null,
  nationality: string | null,
}

export interface IRoundLeague {
  id: number,
  name: string,
}

export interface IRoundClub {
  id: number,
  name: string,
  logo_path: string | null,
  flag_code: string | null,
}

export interface IRoundPlayersMeta {
  tournament_name: string,
  number: number,
  national: boolean,
  fanta: boolean,
  deadlined: boolean,
  leagues: IRoundLeague[],
  clubs: IRoundClub[],
}
