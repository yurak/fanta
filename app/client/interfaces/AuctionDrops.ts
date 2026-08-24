import { IAuctionMeta } from "@/interfaces/AuctionTransfers";
import { Position } from "@/interfaces/Position";

export type DropStatus = "transferable" | "untouchable" | "left";

export type FormState = "empty" | "skipped" | "out" | "bench" | "part" | "full";

export interface IFormCell {
  state: FormState,
  score?: string | null,
}

export interface IDropPlayer {
  id: number,
  name: string,
  first_name: string | null,
  avatar_path: string,
  kit_path: string,
  positions: Position[],
  player_team_id: number | null,
  status: DropStatus,
  club_logo_path: string | null,
  price: number | null,
  appearances: number,
  rating: number | string | null,
  form: IFormCell[],
}

export interface IDropTeam {
  id: number,
  human_name: string,
  logo_path: string,
  budget: number,
  income: number,
  possible_budget: number,
  players_dropped: number,
  players_left: number,
  available_transfers: number,
}

export interface IAuctionDrops {
  auction: IAuctionMeta,
  team: IDropTeam,
  players: IDropPlayer[],
}
