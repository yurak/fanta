import cn from "classnames";
import PlayerAvatar, { PlayerAvatarSkeleton } from "@/components/PlayerAvatar";
import { IPlayer } from "@/interfaces/Player";
import styles from "./PlayersListInfo.module.scss";
import Skeleton from "react-loading-skeleton";

interface IProps {
  player: IPlayer,
}

const PlayersListInfo = ({ player: { avatar_path, club, first_name, name } }: IProps) => {
  return (
    <div className={styles.wrapper}>
      <PlayerAvatar className={styles.avatar} avatarSrc={avatar_path} clubKitSrc={club.kit_path} />
      <div className={styles.info}>
        <div className={styles.lastName}>{name}</div>
        <div className={styles.firstName}>{first_name}</div>
      </div>
    </div>
  );
};

export const PlayersListInfoSkeleton = () => (
  <div className={styles.wrapper}>
    <PlayerAvatarSkeleton className={styles.avatar} />
    <div className={styles.info}>
      <Skeleton className={cn(styles.lastName, styles.lastNameSkeleton)} />
      <Skeleton className={cn(styles.firstName, styles.firstNameSkeleton)} />
    </div>
  </div>
);

export default PlayersListInfo;
