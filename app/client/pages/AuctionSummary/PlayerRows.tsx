import { useState } from "react";
import { useTranslation } from "react-i18next";
import PlayerAvatar from "@/components/PlayerAvatar";
import { IAuctionTransfer } from "@/interfaces/AuctionTransfers";
import styles from "./AuctionSummary.module.scss";

const LIMIT = 7;
const money = (value: number) => `${value}M`;

const PlayerRow = ({ transfer }: { transfer: IAuctionTransfer }) => (
  <a className={styles.playerRow} href={`/players/${transfer.player.id}`}>
    <PlayerAvatar avatarSrc={transfer.player.avatar_path} clubKitSrc={transfer.player.kit_path} className={styles.playerRowAvatar} />
    <span className={styles.playerRowName}>{transfer.player.name}</span>
    <span className={styles.playerRowPrice}>{money(transfer.price)}</span>
  </a>
);

const PlayerRows = ({ transfers }: { transfers: IAuctionTransfer[] }) => {
  const { t } = useTranslation();
  const [expanded, setExpanded] = useState(false);

  const hidden = transfers.length - LIMIT;
  const visible = expanded ? transfers : transfers.slice(0, LIMIT);

  return (
    <div className={styles.cardPlayers}>
      {visible.map((transfer) => (
        <PlayerRow key={transfer.id} transfer={transfer} />
      ))}

      {hidden > 0 && (
        <button
          type="button"
          className={styles.cardMore}
          onClick={(e) => {
            setExpanded((v) => !v);
            e.currentTarget.blur();
          }}
        >
          {expanded ? t("auction_summary.collapse") : t("auction_summary.show_more", { count: hidden })}
        </button>
      )}
    </div>
  );
};

export default PlayerRows;
