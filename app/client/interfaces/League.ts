export interface ILeague {
  id: number,
  division: string | null,
  division_id: number | null,
  link: string,
  name: string,
  season_id: number,
  status: string,
  tournament_id: number,
}

export interface ILeagueFullData extends ILeague {
  auction_type: string,
  cloning_status: string,
  leader: string,
  leader_logo: string,
  max_avg_def_score: string,
  min_avg_def_score: string,
  promotion: number,
  relegation: number,
  round: number,
  season_end_year: number,
  season_start_year: number,
  teams_count: number,
  transfer_status: string,
  mantra_format: boolean,
}
