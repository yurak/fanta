import { LeaderboardMetric } from "@/interfaces/Leaderboard";

export const MEDALS: Record<number, string> = {
  1: "🥇",
  2: "🥈",
  3: "🥉",
};

export const formatValue = (metric: LeaderboardMetric, value: number): string => {
  switch (metric) {
    case "win_rate":
      return `${value.toFixed(2)}%`;
    case "avg_total_score":
      return value.toFixed(2);
    default:
      return String(value);
  }
};
