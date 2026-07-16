import cn from "classnames";
import { useTranslation } from "react-i18next";
import PlayerAvatar, { PlayerAvatarSkeleton } from "@/components/PlayerAvatar";
import { IPlayer } from "@/interfaces/Player";
import styles from "./PlayersListInfo.module.scss";
import Skeleton from "react-loading-skeleton";

interface IProps {
  player: IPlayer,
}

const PlayersListInfo = ({ player: { avatar_path, club, first_name, name, newbie } }: IProps) => {
  const { t } = useTranslation();

  return (
    <div className={styles.wrapper}>
      <PlayerAvatar className={styles.avatar} avatarSrc={avatar_path} clubKitSrc={club.kit_path} />
      <div className={styles.info}>
        <div className={styles.lastName}>
          <span className={styles.lastNameText}>{name}</span>
          {newbie && <span className={styles.newbie}>{t("players.newbie")}</span>}
        </div>
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
