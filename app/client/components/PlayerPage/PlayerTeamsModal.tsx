import { useTranslation } from "react-i18next";
import { IPlayerShow, IPlayerTeam } from "@/interfaces/Player";
import styles from "./PlayerPage.module.scss";

const formatAuctionDate = (date: string | null) => {
  if (!date) {
    return null;
  }

  return new Date(date).toLocaleDateString("en-US", { month: "short", day: "numeric" });
};

const TeamRow = ({ team }: { team: IPlayerTeam }) => {
  const auctionDate = formatAuctionDate(team.auction_date);

  return (
    <div className={`${styles.teamsGrid} ${styles.teamsRow}`}>
      <a className={styles.teamLink} href={`/teams/${team.id}`}>
        <img src={team.logo_path} alt={team.human_name} />
        <span className={styles.teamName}>{team.human_name}</span>
      </a>
      <div className={styles.teamCell}>
        <span className={styles.leagueTag}>
          {[team.league_name, team.division_name].filter(Boolean).join(" ")}
        </span>
      </div>
      <div className={styles.teamCell}>
        {team.auction_id && auctionDate && (
          <a
            className={styles.auctionLink}
            href={`/leagues/${team.league_id}/auctions/${team.auction_id}/transfers`}
          >
            {`${auctionDate} (#${team.auction_number})`}
          </a>
        )}
      </div>
      <div className={`${styles.teamCell} ${styles.priceCell}`}>
        {team.price != null ? `${team.price}M` : "—"}
      </div>
    </div>
  );
};

const PlayerTeamsModal = ({
  player,
  onClose,
}: {
  player: IPlayerShow,
  onClose: () => void,
}) => {
  const { t } = useTranslation();

  return (
    <div className={styles.modalOverlay} onClick={onClose}>
      <div className={styles.modalContent} onClick={(e) => e.stopPropagation()}>
        <div className={styles.modalTitle}>{t("players.teams")}</div>

        <div className={styles.teamsSummary}>
          <div className={styles.summaryBlock}>
            <div className={styles.summaryTitle}>{t("players.total_owners")}</div>
            <div className={styles.summaryValue}>{player.teams.length}</div>
          </div>
          <div className={styles.summaryBlock}>
            <div className={styles.summaryTitle}>{t("players.av_price")}</div>
            <div className={styles.summaryValue}>{`${player.average_price}M`}</div>
          </div>
        </div>

        <div>
          <div className={`${styles.teamsGrid} ${styles.teamsHeader}`}>
            <div>{t("players.team")}</div>
            <div className={styles.teamCell}>{t("players.league")}</div>
            <div className={styles.teamCell}>{t("players.auction")}</div>
            <div className={`${styles.teamCell} ${styles.priceCell}`}>{t("players.price")}</div>
          </div>
          {player.teams.map((team) => (
            <TeamRow key={team.id} team={team} />
          ))}
        </div>
      </div>
    </div>
  );
};

export default PlayerTeamsModal;
