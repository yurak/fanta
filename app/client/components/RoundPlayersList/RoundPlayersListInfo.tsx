import cn from "classnames";
import Skeleton from "react-loading-skeleton";
import PlayerAvatar, { PlayerAvatarSkeleton } from "@/components/PlayerAvatar";
import { IRoundPlayer } from "@/interfaces/RoundPlayer";
import styles from "@/components/PlayersList/PlayersListInfo/PlayersListInfo.module.scss";

const RoundPlayersListInfo = ({ player }: { player: IRoundPlayer }) => {
  const { avatar_path, kit_path, first_name, name } = player;

  return (
    <div className={styles.wrapper}>
      <PlayerAvatar className={styles.avatar} avatarSrc={avatar_path} clubKitSrc={kit_path ?? ""} />
      <div className={styles.info}>
        <div className={styles.lastName}>{name}</div>
        <div className={styles.firstName}>{first_name}</div>
      </div>
    </div>
  );
};

export const RoundPlayersListInfoSkeleton = () => (
  <div className={styles.wrapper}>
    <PlayerAvatarSkeleton className={styles.avatar} />
    <div className={styles.info}>
      <Skeleton className={cn(styles.lastName, styles.lastNameSkeleton)} />
      <Skeleton className={cn(styles.firstName, styles.firstNameSkeleton)} />
    </div>
  </div>
);

export default RoundPlayersListInfo;
