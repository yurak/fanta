import Skeleton from "react-loading-skeleton";
import { ITeam } from "../../interfaces/Team";
import styles from "./TeamName.module.scss";

const TeamName = ({ team }: { team: ITeam }) => {
  return (
    <a href={`/teams/${team.id}`} className={styles.teamName}>
      <span className={styles.teamNameImg}>
        <img src={team.logo_path} />
      </span>
      <span className={styles.teamNameName}>{team.human_name}</span>
    </a>
  );
};

export const TeamNameSkeleton = () => {
  return (
    <span className={styles.teamNameSkeleton}>
      <Skeleton containerClassName={styles.teamNameSkeletonImage} />
      <Skeleton containerClassName={styles.teamNameSkeletonName} />
    </span>
  );
};

export default TeamName;
