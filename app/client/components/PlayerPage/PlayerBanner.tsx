import PlayerAvatar from "@/components/PlayerAvatar";
import PlayerPositions from "@/components/PlayerPositions/PlayerPositions";
import { IPlayerShow } from "@/interfaces/Player";
import styles from "./PlayerPage.module.scss";

const PlayerBanner = ({ player }: { player: IPlayerShow }) => {
  return (
    <div className={styles.banner} style={{ backgroundColor: `#${player.club.color}` }}>
      <div className={styles.bannerBase}>
        <div className={styles.firstName}>{player.first_name}</div>
        <div className={styles.lastName}>{player.name}</div>
        <div className={styles.baseRow}>
          <div className={styles.bannerPositions}>
            <PlayerPositions position={player.position_classic_arr} />
          </div>
          <div className={styles.score}>{player.season_score}</div>
        </div>
      </div>
      <div className={styles.bannerAvatar}>
        <PlayerAvatar
          avatarSrc={player.profile_avatar_path}
          clubKitSrc={player.profile_kit_path}
          className={styles.avatar}
        />
      </div>
    </div>
  );
};

export default PlayerBanner;
