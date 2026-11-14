import { useTranslation } from "react-i18next";
import cn from "classnames";
import { FormState, IDropPlayer } from "@/interfaces/AuctionDrops";
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

interface IProps {
  player: IDropPlayer,
  className?: string,
}

const PlayerForm = ({ player, className }: IProps) => {
  const { t } = useTranslation();
  const cells = player.form ?? [];

  return (
    <span className={cn(styles.form, className)}>
      {cells.map((cell, index) => (
        <span key={index} className={cn(styles.formCell, FORM_CLASS[cell.state])}>{cell.score}</span>
      ))}
      {cells.length > 0 && (
        <span className={styles.formLegend} role="tooltip">
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
