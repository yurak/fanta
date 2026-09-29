import { ISeason } from "./Season";
import { ITournament } from "./Tournament";

export interface IWishlist {
  id: number,
  shared: boolean,
  players_count: number,
  max_players: number,
  editable: boolean,
  owner: { id: number, name: string },
  tournament: ITournament,
  season: ISeason,
}

export interface IWishlistToggle {
  player_id: number,
  wishlisted: boolean,
  wishlist: IWishlist,
}
