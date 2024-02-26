import { IClub } from "./Club";

export enum PlayerPosition {
  GK = "GK",
  CB = "CB",
  LB = "LB",
  RB = "RB",
  WB = "WB",
  CM = "CM",
  DM = "DM",
  AM = "AM",
  W = "W",
  FW = "FW",
  ST = "ST",
}

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
  position_classic_arr: PlayerPosition[],
  teams_count: number,
}
