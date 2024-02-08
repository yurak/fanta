import { ChartType, TooltipItem } from "chart.js";
import styles from "./ChartTooltip.module.scss";

export interface ITooltip<TType extends ChartType = ChartType> {
  left?: number,
  right?: number,
  bottom: number,
  title: string[],
  dataPoints: TooltipItem<TType>[],
}

interface IProps {
  tooltip: ITooltip | null,
}

const ChartTooltip = ({ tooltip }: IProps) => {
  if (!tooltip) {
    return;
  }

  const { left, right, bottom, title, dataPoints } = tooltip;

  return (
    <div className={styles.tooltip} style={{ bottom, left, right }}>
      <div className={styles.tooltipContainer}>
        <div className={styles.tooltipTitle}>{title.join(" ")}</div>
        <div className={styles.points}>
          {dataPoints.map((point) => (
            <div className={styles.pointItem} key={point.datasetIndex}>
              <span
                className={styles.point}
                style={{ backgroundColor: point.dataset.backgroundColor as string }}
              />
              <div className={styles.pointLabel}>{point.dataset.label}</div>
              <div>{point.formattedValue}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default ChartTooltip;
