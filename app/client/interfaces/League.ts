export interface ILeague {
  id: number;
  division: string;
  division_id: number;
  link: string;
  name: string;
  season_id: number;
  status: string;
  tournament_id: number;
}

export interface ILeagueFullData extends ILeague {
  auction_type: string;
  cloning_status: string;
  leader: string;
  max_avg_def_score: string;
  min_avg_def_score: string;
  promotion: number;
  relegation: number;
  round: number;
  season_end_year: number;
  season_start_year: number;
  teams_count: number;
  transfer_status: string;
}
