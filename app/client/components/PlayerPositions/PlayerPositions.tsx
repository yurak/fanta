import { IPlayer } from "@/interfaces/Player";
import cn from "classnames";
import { positionMappers } from "./constants";
import styles from "./PlayerPositions.module.scss";

const PlayerPositions = ({ positions }: { positions: IPlayer["position_classic_arr"] }) => {
  const isFantaFormat = true;

  const positionLabels = positions.map((position) => {
    const { color, label, fantaLabel } = positionMappers[position];

    return {
      id: position,
      color,
      label: isFantaFormat ? fantaLabel : label,
    };
  });

  return (
    <div className={styles.positions}>
      {positionLabels.map((position) => (
        <span
          key={position.id}
          className={cn(styles.position, {
            [styles.yellow]: position.color == "yellow",
            [styles.green]: position.color == "green",
            [styles.blue]: position.color == "blue",
            [styles.purple]: position.color == "purple",
            [styles.red]: position.color == "red",
          })}
        >
          {position.label}
        </span>
      ))}
    </div>
  );
};

export default PlayerPositions;
