import { useTranslation } from "react-i18next";
import PlayerAvatar from "@/components/PlayerAvatar";
import PlayerPositions from "@/components/PlayerPositions/PlayerPositions";
import { IDropPlayer } from "@/interfaces/AuctionDrops";
import DropStatus from "./DropStatus";
import { playerPositions } from "./dropPlayer";
import styles from "./AuctionDrops.module.scss";

interface IProps {
  player: IDropPlayer,
  atLimit: boolean,
  onToggle: (player: IDropPlayer) => void,
}

const MobilePlayerRow = ({ player, atLimit, onToggle }: IProps) => {
  const { t } = useTranslation();
  const positions = playerPositions(player);
  const price = player.price != null ? `${player.price}M` : "—";

  return (
    <div className={styles.mobileItem}>
      <a className={styles.mobileAvatarLink} href={`/players/${player.id}`}>
        <PlayerAvatar avatarSrc={player.avatar_path} clubKitSrc={player.kit_path} className={styles.mobileAvatar} />
      </a>
      <div className={styles.mobileInfo}>
        <div className={styles.mobileTop}>
          <a className={styles.mobileName} href={`/players/${player.id}`}>
            <span className={styles.mobileNameText}>{player.first_name} {player.name}</span>
          </a>
          <span className={styles.mobilePrice}>{price}</span>
        </div>
        <div className={styles.mobileBottom}>
          {positions.length > 0 && (
            <span>
              <PlayerPositions position={positions} />
            </span>
          )}
          {player.club_logo_path && (
            <>
              <span className={styles.mobileDivider} />
              <span className={styles.mobileLogo}><img src={player.club_logo_path} alt="" /></span>
            </>
          )}
          <span className={styles.mobileDivider} />
          <span className={styles.mobileMeta}>{player.appearances} {t("auction_drops.apps_short")}</span>
          <span className={styles.mobileDivider} />
          <span className={styles.mobileMeta}>{player.rating}</span>
        </div>
      </div>
      <DropStatus player={player} iconOnly atLimit={atLimit} onToggle={onToggle} />
    </div>
  );
};

export default MobilePlayerRow;
