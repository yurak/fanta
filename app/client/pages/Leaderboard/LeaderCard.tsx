import { ILeaderboardEntry, LeaderboardMetric } from "@/interfaces/Leaderboard";
import TeamLogos from "./TeamLogos";
import { formatValue } from "./format";
import styles from "./Leaderboard.module.scss";

const LeaderCard = ({
  entry,
  metric,
}: {
  entry?: ILeaderboardEntry,
  metric: LeaderboardMetric,
}) => (
  <div className={styles.card}>
    {entry && (
      <>
        <div className={styles.cardInfo}>
          <div className={styles.cardTop}>
            <div className={styles.cardMedal}>🥇</div>
            <div className={styles.cardValue}>{formatValue(metric, entry.value)}</div>
          </div>
          <TeamLogos logos={entry.team_logos} extra={entry.extra_teams} />
        </div>
        <div className={styles.cardManager}>
          <div className={styles.cardAvatarRing}>
            <img className={styles.cardAvatar} src={entry.avatar_path} alt="" />
          </div>
          <a className={styles.cardName} href={entry.profile_path}>
            {entry.name}
          </a>
        </div>
      </>
    )}
  </div>
);

export default LeaderCard;
