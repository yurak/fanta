import { useState } from "react";
import { useTranslation } from "react-i18next";
import PlayerAvatar from "@/components/PlayerAvatar";
import PlayerPositions from "@/components/PlayerPositions/PlayerPositions";
import { IAuctionTransfer } from "@/interfaces/AuctionTransfers";
import { Position } from "@/interfaces/Position";
import styles from "./AuctionSummary.module.scss";

const LIMIT = 7;
const money = (value: number) => `${value}M`;
const KNOWN_POSITIONS = new Set<string>(Object.values(Position));

const PlayerRow = ({ transfer }: { transfer: IAuctionTransfer }) => {
  const positions = transfer.player.positions.filter((position) => KNOWN_POSITIONS.has(position));

  return (
    <a className={styles.playerRow} href={`/players/${transfer.player.id}`}>
      <PlayerAvatar avatarSrc={transfer.player.avatar_path} clubKitSrc={transfer.player.kit_path} className={styles.playerRowAvatar} />
      <span className={styles.playerRowName}>{transfer.player.name}</span>
      <span className={styles.playerRowPositions}>
        {positions.length > 0 && <PlayerPositions position={positions} small />}
      </span>
      <span className={styles.playerRowPrice}>{money(transfer.price)}</span>
    </a>
  );
};

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
