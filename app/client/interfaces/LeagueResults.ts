import { ITeam } from "./Team";

type ScoreType = string;

export interface ILeagueResultsHistory {
  pos: number;
  p: number;
  sg: number;
  mg: number;
  w: number;
  d: number;
  l: number;
  ts: ScoreType;
}

export interface ILeagueResults {
  id: number;
  best_lineup: string;
  form: ("W" | "D" | "L")[];
  history: (null | ILeagueResultsHistory)[];
  league_id: number;
  next_opponent_id: number;
  points: number;
  matches_played: number;
  wins: number;
  draws: number;
  loses: number;
  scored_goals: number;
  missed_goals: number;
  goals_difference: number;
  team: ITeam;
  total_score: ScoreType;
}
