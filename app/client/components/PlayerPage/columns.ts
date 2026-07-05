import { BonusKey } from "./bonuses";

export interface IBonusColumn {
  key: string,
  icon: BonusKey,
  header: string, // i18n key under players.*
  title: string, // i18n key under players.* for tooltip
  bool?: boolean,
}

export const OUTFIELD_COLUMNS: IBonusColumn[] = [
  { key: "goals", icon: "goal_scored", header: "g", title: "goals" },
  { key: "scored_penalty", icon: "penalty_scored", header: "sp", title: "scored_penalty" },
  { key: "failed_penalty", icon: "penalty_failed", header: "fp", title: "failed_penalty" },
  { key: "penalties_won", icon: "penalty_earned", header: "ep", title: "earned_penalty" },
];

export const GK_COLUMNS: IBonusColumn[] = [
  { key: "missed_goals", icon: "goal_missed", header: "mg", title: "missed_goals" },
  { key: "missed_penalty", icon: "penalty_missed", header: "mp", title: "missed_penalty" },
  { key: "caught_penalty", icon: "penalty_caught", header: "cp", title: "caught_penalty" },
  { key: "saves", icon: "saves", header: "s", title: "saves" },
];

export const COMMON_COLUMNS: IBonusColumn[] = [
  { key: "assists", icon: "assist", header: "as", title: "assists" },
  { key: "yellow_card", icon: "yellow_card", header: "yc", title: "yellow_card", bool: true },
  { key: "red_card", icon: "red_card", header: "rc", title: "red_card", bool: true },
  { key: "cleansheet", icon: "clean_sheet", header: "cs", title: "cleansheet", bool: true },
  { key: "own_goals", icon: "own_goal", header: "og", title: "own_goals" },
  { key: "conceded_penalty", icon: "penalty_foul", header: "pf", title: "penalty_foul" },
];
