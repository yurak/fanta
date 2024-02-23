import PlayerAvatar from "@/components/PlayerAvatar";
import { IPlayer } from "@/interfaces/Player";
import styles from "./PlayersListInfo.module.scss";

interface IProps {
  player: IPlayer,
}

const PlayersListInfo = ({ player: { avatar_path, club, first_name, name } }: IProps) => {
  return (
    <div className={styles.wrapper}>
      <div className={styles.avatar}>
        <PlayerAvatar avatarSrc={avatar_path} clubKitSrc={club.kit_path} />
      </div>
      <div>
        <div className={styles.lastName}>{name}</div>
        <div className={styles.firstName}>{first_name}</div>
      </div>
    </div>
  );
};

export default PlayersListInfo;
