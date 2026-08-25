import { IAuctionMeta, IAuctionRankingEntry, IAuctionTeam, IAuctionTransfer } from "@/interfaces/AuctionTransfers";

export interface IAuctionPurchaseTeamGroup {
  team: IAuctionTeam,
  total_spent: number,
  bought: IAuctionTransfer[],
}

export interface IAuctionPurchases {
  auction: IAuctionMeta,
  stages: number[],
  current_team_id: number | null,
  teams: IAuctionPurchaseTeamGroup[],
  top_spenders: IAuctionRankingEntry[],
  top_buy: IAuctionTransfer[],
}
