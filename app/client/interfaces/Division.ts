export interface IDivisionResult {
  id: number,
  points: number,
  team_code: string,
  team_id: number,
  team_logo: string,
  team_name: string,
}

export interface IDivisionLeague {
  id: number,
  division: string | null,
  name: string,
  promotion: number,
  relegation: number,
  status: string,
  results: IDivisionResult[],
}

export interface IDivisionLevel {
  id: number,
  level: string,
  leagues: IDivisionLeague[],
}

export interface IDivisionsMeta {
  season_id: number,
  my_league_ids: number[],
  my_team_ids: number[],
}

export interface IDivisionsResponse {
  data: IDivisionLevel[],
  meta: IDivisionsMeta,
}
