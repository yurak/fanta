export interface IAuctionRow {
  href: string,
  icon: string,
  icon_active: boolean,
  title: string,
  title_status: string | null,
  item_status: string,
  transfers: string,
  transfers_status: string | null,
  status: string,
  status_text: string,
  status_icon: string,
  date: string,
  arrow_icon: string,
}

export interface IAuctionEntry {
  hidden: boolean,
  rows: IAuctionRow[],
}

export interface IAuctionsIndex {
  auctions: IAuctionEntry[],
}
