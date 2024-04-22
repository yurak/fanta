import cn from "classnames";
import { useAppContext } from "@/application/AppContext";
import { Position } from "@/interfaces/Position";
import { Positions } from "@/domain/Positions";
import styles from "./PlayerPositions.module.scss";

const PlayerPositions = ({
  position,
  outlined,
}: {
  position: Position | Position[],
  outlined?: boolean,
}) => {
  const { italPositionNaming } = useAppContext();

  const positions = Array.isArray(position) ? position : [position];

  const positionLabels = positions.map((position) => {
    return {
      id: position,
      color: Positions.getColorById(position),
      label: Positions.getLabelById(position, italPositionNaming),
    };
  });

  return (
    <div className={styles.positions}>
      {positionLabels.map((position) => (
        <span
          key={position.id}
          className={cn(styles.position, {
            [styles.yellow]: position.color === "yellow",
            [styles.green]: position.color === "green",
            [styles.blue]: position.color === "blue",
            [styles.purple]: position.color === "purple",
            [styles.red]: position.color === "red",
            [styles.outlined]: outlined,
          })}
        >
          {position.label}
        </span>
      ))}
    </div>
  );
};

export default PlayerPositions;
