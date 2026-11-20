import { useTranslation } from "react-i18next";
import cn from "classnames";
import { IDropPlayer } from "@/interfaces/AuctionDrops";
import styles from "./AuctionDrops.module.scss";

interface IProps {
  player: IDropPlayer,
  iconOnly: boolean,
  atLimit: boolean,
  onToggle: (player: IDropPlayer) => void,
}

const DropStatus = ({ player, iconOnly, atLimit, onToggle }: IProps) => {
  const { t } = useTranslation();

  // a player who already left his club this auction is not ours to drop any more
  if (player.status === "left") {
    return <span className={cn(styles.leftBadge, { [styles.statusIcon]: iconOnly })}>{t("auction_drops.left")}</span>;
  }

  const dropped = player.status === "transferable";
  const label = dropped ? t("auction_drops.dropped") : t("auction_drops.drop");

  return (
    <button
      type="button"
      className={cn(styles.dropBtn, { [styles.droppedBtn]: dropped, [styles.statusIcon]: iconOnly })}
      disabled={atLimit && !dropped}
      aria-label={label}
      onClick={(e) => {
        onToggle(player);
        e.currentTarget.blur();
      }}
    >
      {iconOnly ? (dropped ? "✕" : "✓") : label}
    </button>
  );
};

export default DropStatus;
