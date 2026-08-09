import cn from "classnames";
import { ILeaderboardEntry, LeaderboardMetric } from "@/interfaces/Leaderboard";
import TeamLogos from "./TeamLogos";
import { MEDALS, formatValue } from "./format";
import styles from "./Leaderboard.module.scss";

const LeaderboardRow = ({
  entry,
  metric,
  highlighted,
}: {
  entry: ILeaderboardEntry,
  metric: LeaderboardMetric,
  highlighted?: boolean,
}) => (
  <div className={cn(styles.row, { [styles.rowHighlighted]: highlighted })}>
    <div className={cn(styles.cell, styles.placeCell)}>
      <span className={styles.place}>{MEDALS[entry.rank] ?? entry.rank}</span>
    </div>
    <div className={cn(styles.cell, styles.managerCell)}>
      <img className={styles.avatar} src={entry.avatar_path} alt="" />
      <a className={styles.name} href={entry.profile_path}>
        {entry.name}
      </a>
    </div>
    <div className={cn(styles.cell, styles.logosCell)}>
      <TeamLogos logos={entry.team_logos} extra={entry.extra_teams} />
    </div>
    {metric !== "matches" && (
      <div className={cn(styles.cell, styles.secondaryCell)}>
        {metric === "titles" ? (entry.champion_number ?? "—") : entry.matches}
      </div>
    )}
    <div className={cn(styles.cell, styles.valueCell)}>{formatValue(metric, entry.value)}</div>
  </div>
);

export default LeaderboardRow;
