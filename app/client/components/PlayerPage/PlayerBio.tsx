import { useState } from "react";
import { useTranslation } from "react-i18next";
import { IPlayerShow } from "@/interfaces/Player";
import PlayerTeamsModal from "./PlayerTeamsModal";
import styles from "./PlayerPage.module.scss";

const PlayerBio = ({ player }: { player: IPlayerShow }) => {
  const { t } = useTranslation();
  const [teamsOpen, setTeamsOpen] = useState(false);

  return (
    <div className={styles.table}>
      <div className={styles.tableTitle}>{t("players.bio")}</div>

      {player.nationality && (
        <div className={styles.bioRow}>
          <div className={styles.bioKey}>{t("players.country")}</div>
          <div className={styles.bioValue}>
            {player.country}
            <span className={`flag-icon flag-icon-${player.nationality.toLowerCase()} ${styles.flag}`} />
          </div>
        </div>
      )}

      <div className={styles.bioRow}>
        <div className={styles.bioKey}>{t("players.club")}</div>
        <div className={`${styles.bioValue} ${styles.club}`}>
          <div className={styles.clubName}>
            {player.club.tournament_id ? (
              <a
                className={styles.tmLink}
                href={`/tournaments/${player.club.tournament_id}/clubs/${player.club.id}`}
              >
                {player.club.name}
              </a>
            ) : (
              player.club.name
            )}
          </div>
          <object data={player.club.logo_path} type="image/png">
            <img src={player.club.logo_path} alt={player.club.name} />
          </object>
        </div>
      </div>

      {player.tm_url && (
        <div className={styles.bioRow}>
          <div className={styles.bioKey}>{t("players.transfermarkt")}</div>
          <div className={styles.bioValue}>
            <a className={styles.tmLink} href={player.tm_url} target="_blank" rel="noreferrer">
              {`${(player.tm_price ?? 0).toLocaleString("en-US")} €`}
            </a>
          </div>
        </div>
      )}

      {player.birth_date && (
        <div className={styles.bioRow}>
          <div className={styles.bioKey}>{t("players.age")}</div>
          <div className={styles.bioValue}>
            <div>
              <div>{player.age}</div>
              <div className={styles.birth}>{player.birth_date}</div>
            </div>
          </div>
        </div>
      )}

      {player.height && (
        <div className={styles.bioRow}>
          <div className={styles.bioKey}>{t("players.height")}</div>
          <div className={styles.bioValue}>{`${player.height} cm`}</div>
        </div>
      )}

      <div className={`${styles.bioRow} ${styles.bioRowLast}`}>
        <div className={styles.bioKey}>{t("players.teams")}</div>
        <div className={styles.bioValue}>
          <span className={`${styles.tmLink} ${styles.teamsBtn}`} onClick={() => setTeamsOpen(true)}>
            {player.teams.length}
          </span>
        </div>
      </div>

      {teamsOpen && <PlayerTeamsModal player={player} onClose={() => setTeamsOpen(false)} />}
    </div>
  );
};

export default PlayerBio;
