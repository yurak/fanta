import cn from "classnames";
import Chip from "@/ui/Chip";
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
      {legends.map((legend) => {
        const disabled = !legend.isActive;

        return (
          <Chip key={legend.label} onClick={() => onClick(legend.index)} asDisabled={disabled}>
            <span
              className={cn(styles.legendsItem, { [styles.disabled]: disabled })}
              style={
                {
                  "--color": legend.color,
                } as React.CSSProperties
              }
            >
              {legend.label}
            </span>
          </Chip>
        );
      })}
    </div>
  );
};

export default ChartLegend;
