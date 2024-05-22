import { IClub } from "./Club";
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
  league_price: null,
  league_team_logo: null,
  name: string,
  position_classic_arr: Position[],
  teams_count: number,
  teams_count_max: number,
}
