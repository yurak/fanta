import styles from "./ChartTooltip.module.scss";

export interface ITooltip {
  left?: number,
  right?: number,
  bottom: number,
  title: string[],
}

interface IProps {
  tooltip: ITooltip | null,
}

const ChartTooltip = ({ tooltip }: IProps) => {
  console.log({ tooltip });

  if (!tooltip) {
    return;
  }

  const { left, right, bottom, title } = tooltip;

  return (
    <div className={styles.tooltip} style={{ bottom, left, right }}>
      <div className={styles.tooltipContainer}>
        <div className={styles.tooltipTitle}>{title.join(" ")}</div>
      </div>
    </div>
  );
};

export default ChartTooltip;
