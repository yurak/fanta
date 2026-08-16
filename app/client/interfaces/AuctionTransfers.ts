export interface IAuctionPlayer {
  id: number,
  name: string,
  first_name: string | null,
  avatar_path: string,
  kit_path: string,
  positions: string[],
}

export interface IAuctionTeam {
  id: number,
  human_name: string,
  logo_path: string,
}

export interface IAuctionTransfer {
  id: number,
  price: number,
  status: "incoming" | "outgoing" | "left",
  player: IAuctionPlayer,
  team: IAuctionTeam,
}

export interface IAuctionRankingEntry {
  team: IAuctionTeam,
  value: number,
}

export interface IAuctionMeta {
  number: number,
  status: string,
  deadline: string | null,
}
