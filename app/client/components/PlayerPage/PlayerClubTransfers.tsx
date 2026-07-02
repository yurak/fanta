import { useTranslation } from "react-i18next";
import { IClub } from "@/interfaces/Club";
import { IClubTransfer } from "@/interfaces/ClubTransfer";
import styles from "./PlayerPage.module.scss";

const formatDate = (date: string | null) => {
  if (!date) {
    return "—";
  }

  return new Date(date).toLocaleDateString("en-GB");
};

const ClubCell = ({ club, name }: { club: IClub | null, name: string | null }) => {
  if (!club) {
    return (
      <div className={styles.transferClub}>
        <span>{name || "—"}</span>
      </div>
    );
  }

  return (
    <div className={styles.transferClub}>
      <img
        src={club.logo_path}
        alt={club.name}
        onError={(e) => {
          e.currentTarget.style.visibility = "hidden";
        }}
      />
      {club.tournament_id ? (
        <a className={styles.tmLink} href={`/tournaments/${club.tournament_id}/clubs/${club.id}`}>
          {club.name}
        </a>
      ) : (
        <span>{club.name}</span>
      )}
    </div>
  );
};

const PlayerClubTransfers = ({ transfers }: { transfers: IClubTransfer[] }) => {
  const { t } = useTranslation();

  return (
    <div className={styles.table}>
      <div className={styles.tableTitle}>{t("players.club_transfers")}</div>

      {transfers.length === 0 ? (
        <div className={styles.emptyRow}>{t("players.no_transfers")}</div>
      ) : (
        <div className={styles.transfersScroll}>
          <div className={styles.transfersInner}>
            <div className={`${styles.transfersGrid} ${styles.perfHeaders}`}>
              <div className={styles.headerCell}>{t("players.transfer_date")}</div>
              <div className={styles.headerCell}>{t("players.old_club")}</div>
              <div />
              <div className={styles.headerCell}>{t("players.new_club")}</div>
              <div className={styles.headerCell}>{t("players.contract_until")}</div>
              <div className={styles.headerCell}>{t("players.loan")}</div>
            </div>
            {transfers.map((transfer) => (
              <div key={transfer.id} className={`${styles.transfersGrid} ${styles.transfersRow}`}>
                <div className={styles.transferCell}>{formatDate(transfer.start_date)}</div>
                <ClubCell club={transfer.old_club} name={transfer.old_club_name} />
                <div className={styles.transferArrow}>→</div>
                <ClubCell club={transfer.new_club} name={transfer.new_club_name} />
                <div className={styles.transferCell}>{formatDate(transfer.contract_expires_on)}</div>
                <div className={styles.transferCell}>
                  {transfer.loan ? <span className={styles.loanTag}>✓</span> : "—"}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

export default PlayerClubTransfers;
