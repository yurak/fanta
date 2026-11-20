import { useTranslation } from "react-i18next";
import Skeleton from "react-loading-skeleton";
import { useRoundPlayerTeams } from "@/api/query/useRoundPlayerTeams";
import { IRoundPlayer } from "@/interfaces/RoundPlayer";
import styles from "./FieldingTeamsModal.module.scss";

const FieldingTeamsModal = ({
  roundId,
  player,
  onClose,
}: {
  roundId: number,
  player: IRoundPlayer,
  onClose: () => void,
}) => {
  const { t } = useTranslation();
  const { data, isLoading } = useRoundPlayerTeams(roundId, player.id);

  return (
    <div className={styles.overlay} onClick={onClose} role="presentation">
      {/* the click guard keeps a press inside the panel from closing it */}
      <div className={styles.panel} onClick={(event) => event.stopPropagation()} role="presentation">
        <button type="button" className={styles.close} onClick={onClose} aria-label={t("header.close")}>
          ×
        </button>
        <div className={styles.title}>
          {[player.first_name, player.name].filter(Boolean).join(" ")}
        </div>
        <div className={styles.subtitle}>{t("round_players_page.fielded_by")}</div>

        {isLoading && <Skeleton count={5} height={40} />}

        {!isLoading && data?.length === 0 && (
          <div className={styles.empty}>{t("round_players_page.fielded_by_none")}</div>
        )}

        <div className={styles.list}>
          {data?.map((team) => (
            <a key={team.id} className={styles.row} href={`/teams/${team.id}`}>
              <img className={styles.logo} src={team.logo_path} alt={team.name} />
              <span className={styles.name}>{team.name}</span>
            </a>
          ))}
        </div>
      </div>
    </div>
  );
};

export default FieldingTeamsModal;
