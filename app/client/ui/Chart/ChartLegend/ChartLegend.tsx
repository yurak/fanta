import cn from "classnames";
import styles from "./ChartLegend.module.scss";

export interface IProps {
  legends: Array<{
    label?: string,
    color: string,
    index: number,
    isActive: boolean,
  }>,
  onClick: (index: number) => void,
}

const ChartLegend = ({ legends, onClick }: IProps) => {
  return (
    <div className={styles.legends}>
      {legends.map((legend) => (
        <div
          className={cn(styles.legendsItem, { [styles.isNotActive]: !legend.isActive })}
          key={legend.label}
          onClick={() => onClick(legend.index)}
        >
          <span
            className={styles.legendsItemPoint}
            style={
              {
                "--color": legend.color,
              } as React.CSSProperties
            }
          />
          <span>{legend.label}</span>
        </div>
      ))}
    </div>
  );
};

export default ChartLegend;
