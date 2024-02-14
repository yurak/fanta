import { IClub } from "./Club";

export interface IPlayer {
  appearances: number,
  avatar_path: string,
  average_base_score: string,
  average_price: number,
  average_total_score: string,
  club: IClub,
  first_name: string,
  id: number,
  league_price: null,
  league_team_logo: null,
  name: string,
  position_classic_arr: string[],
  position_ital_arr: string[],
  teams_count: number,
}
