import { ILeaderboardEntry, LeaderboardMetric } from "@/interfaces/Leaderboard";
import { formatValue } from "./format";
import styles from "./Leaderboard.module.scss";

const CurrentUserCard = ({
  entry,
  metric,
}: {
  entry: ILeaderboardEntry,
  metric: LeaderboardMetric,
}) => (
  <a className={styles.userCard} href={entry.profile_path}>
    <span className={styles.userCardPlace}>{entry.rank}</span>
    <span className={styles.userCardManager}>
      <img className={styles.userCardAvatar} src={entry.avatar_path} alt="" />
      <span className={styles.userCardName}>{entry.name}</span>
    </span>
    <span className={styles.userCardValue}>{formatValue(metric, entry.value)}</span>
  </a>
);

export default CurrentUserCard;
