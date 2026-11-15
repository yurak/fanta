import { useTranslation } from "react-i18next";
import cn from "classnames";
import { FormState, IDropPlayer, IFormCell } from "@/interfaces/AuctionDrops";
import styles from "./AuctionDrops.module.scss";

const FORM_CLASS: Record<FormState, string> = {
  empty: styles.formEmpty,
  skipped: styles.formSkipped,
  out: styles.formOut,
  bench: styles.formBench,
  part: styles.formPart,
  full: styles.formFull,
};

// order shown in the hover legend that decodes the form-cell colors
const FORM_LEGEND: FormState[] = ["full", "part", "bench", "out", "skipped", "empty"];

const BLANK = "–";

interface IProps {
  player: IDropPlayer,
  className?: string,
}

const PlayerForm = ({ player, className }: IProps) => {
  const { t } = useTranslation();
  const cells = player.form ?? [];
  // a padding cell stands for a round that does not exist yet, so it has nothing to detail
  const played = cells.filter((cell) => cell.state !== "empty");

  const opponentLabel = (cell: IFormCell) => {
    if (!cell.opponent?.name) {
      return BLANK;
    }

    return `(${t(cell.opponent.home ? "lineups.home" : "lineups.away")}) ${cell.opponent.name}`;
  };

  return (
    <span className={cn(styles.form, className)}>
      {cells.map((cell, index) => (
        <span key={index} className={cn(styles.formCell, FORM_CLASS[cell.state])}>{cell.score}</span>
      ))}
      {cells.length > 0 && (
        <span className={styles.formLegend} role="tooltip">
          {played.length > 0 && (
            <span className={styles.formDetails}>
              <span className={cn(styles.formDetailsRow, styles.formDetailsHead)}>
                <span>{t("players.form_details.round")}</span>
                <span>{t("players.form_details.opponent")}</span>
                <span className={styles.formDetailsNumber}>{t("players.form_details.minutes")}</span>
                <span className={styles.formDetailsNumber}>{t("players.form_details.score")}</span>
                <span className={styles.formDetailsNumber}>
                  {t("players.form_details.final_score")}
                </span>
              </span>
              {played.map((cell, index) => (
                <span key={index} className={styles.formDetailsRow}>
                  <span className={styles.formDetailsRound}>
                    <span className={cn(styles.formDetailsSwatch, FORM_CLASS[cell.state])} />
                    {cell.round}
                  </span>
                  <span>{opponentLabel(cell)}</span>
                  <span className={styles.formDetailsNumber}>
                    {cell.minutes == null ? BLANK : `${cell.minutes}'`}
                  </span>
                  <span className={styles.formDetailsNumber}>{cell.score || BLANK}</span>
                  <span className={styles.formDetailsNumber}>{cell.final_score || BLANK}</span>
                </span>
              ))}
            </span>
          )}
          {FORM_LEGEND.map((state) => (
            <span key={state} className={styles.formLegendRow}>
              <span className={cn(styles.formLegendSwatch, FORM_CLASS[state])} />
              <span className={styles.formLegendLabel}>{t(`players.form_legend.${state}`)}</span>
            </span>
          ))}
        </span>
      )}
    </span>
  );
};

export default PlayerForm;
