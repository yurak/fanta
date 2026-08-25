import { IAuctionMeta, IAuctionRankingEntry, IAuctionTeam, IAuctionTransfer } from "@/interfaces/AuctionTransfers";

export interface IAuctionSaleTeamGroup {
  team: IAuctionTeam,
  net_income: number,
  dropped: IAuctionTransfer[],
  left: IAuctionTransfer[],
}

export interface IAuctionSales {
  auction: IAuctionMeta,
  teams: IAuctionSaleTeamGroup[],
  top_earners: IAuctionRankingEntry[],
  top_droppers: IAuctionRankingEntry[],
  top_sale: IAuctionTransfer[],
}
