import Skeleton from "react-loading-skeleton";
import cn from "classnames";
import { ITeam } from "../../interfaces/Team";
import styles from "./TeamName.module.scss";

const TeamName = ({
  team,
  hideName,
  hideLogoOnMobile,
}: {
  team: ITeam,
  hideName?: boolean,
  hideLogoOnMobile?: boolean,
}) => {
  return (
    <a href={`/teams/${team.id}`} className={styles.teamName}>
      <span
        className={cn(styles.teamNameImg, {
          [styles.teamNameMobile]: hideLogoOnMobile,
        })}
      >
        <img src={team.logo_path} />
      </span>
      {!hideName && <span className={styles.teamNameName}>{team.human_name}</span>}
    </a>
  );
};

export const TeamNameSkeleton = ({
  hideName,
  hideLogoOnMobile,
}: {
  hideName?: boolean,
  hideLogoOnMobile?: boolean,
}) => {
  return (
    <span className={styles.teamNameSkeleton}>
      <Skeleton
        containerClassName={cn(styles.teamNameSkeletonImage, {
          [styles.teamNameMobile]: hideLogoOnMobile,
        })}
      />
      {!hideName && <Skeleton containerClassName={styles.teamNameSkeletonName} />}
    </span>
  );
};

export default TeamName;
