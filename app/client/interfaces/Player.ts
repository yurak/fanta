import { IClub } from "./Club";
import { IClubTransfer } from "./ClubTransfer";
import { Position } from "./Position";

export interface IPlayer {
  appearances: number,
  appearances_max: number,
  avatar_path: string,
  average_base_score: string,
  average_price: number,
  average_total_score: string,
  club: IClub,
  first_name: string,
  id: number,
  league_price: null | number,
  league_team_logo: null | string,
  name: string,
  position_classic_arr: Position[],
  teams_count: number,
  teams_count_max: number,
}

export interface INationalTeam {
  id: number,
  name: string,
  code: string,
  logo_path: string,
}

export interface IPlayerTeam {
  id: number,
  human_name: string,
  logo_path: string,
  league_id: number,
  league_name: string,
  division_name: string | null,
  auction_id: number | null,
  auction_number: number | null,
  auction_date: string | null,
  price: number | null,
}

export interface IPlayerShow extends IPlayer {
  age: number | null,
  birth_date: string,
  club_transfers: IClubTransfer[],
  country: string,
  height: number | null,
  national_team: INationalTeam | null,
  nationality: string | null,
  number: number | null,
  profile_avatar_path: string,
  profile_kit_path: string,
  season_score: string,
  team_ids: number[],
  teams: IPlayerTeam[],
  tm_price: number | null,
  tm_url: string | null,
}
