import Assist from "@/assets/bonuses/assist.svg";
import CleanSheet from "@/assets/bonuses/clean_sheet.svg";
import GoalMissed from "@/assets/bonuses/goal_missed.svg";
import GoalScored from "@/assets/bonuses/goal_scored.svg";
import OwnGoal from "@/assets/bonuses/own_goal.svg";
import PenaltyCaught from "@/assets/bonuses/penalty_caught.svg";
import PenaltyEarned from "@/assets/bonuses/penalty_earned.svg";
import PenaltyFailed from "@/assets/bonuses/penalty_failed.svg";
import PenaltyFoul from "@/assets/bonuses/penalty_foul.svg";
import PenaltyMissed from "@/assets/bonuses/penalty_missed.svg";
import PenaltyScored from "@/assets/bonuses/penalty_scored.svg";
import RedCard from "@/assets/bonuses/red_card.svg";
import Saves from "@/assets/bonuses/saves.svg";
import YellowCard from "@/assets/bonuses/yellow_card.svg";

export const BONUS_ICONS = {
  assist: Assist,
  clean_sheet: CleanSheet,
  goal_missed: GoalMissed,
  goal_scored: GoalScored,
  own_goal: OwnGoal,
  penalty_caught: PenaltyCaught,
  penalty_earned: PenaltyEarned,
  penalty_failed: PenaltyFailed,
  penalty_foul: PenaltyFoul,
  penalty_missed: PenaltyMissed,
  penalty_scored: PenaltyScored,
  red_card: RedCard,
  saves: Saves,
  yellow_card: YellowCard,
} as const;

export type BonusKey = keyof typeof BONUS_ICONS;
