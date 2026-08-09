export type LeaderboardMetric = "win_rate" | "avg_total_score" | "titles" | "matches";

export interface ILeaderboardEntry {
  id: number,
  rank: number,
  value: number,
  matches: number,
  champion_number: number | null,
  name: string,
  avatar_path: string,
  team_logos: string[],
  extra_teams: number,
  profile_path: string,
}
