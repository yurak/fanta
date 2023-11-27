import cn from "classnames";
import emptyStateImage from "./../../../assets/images/empty_state.svg";
import styles from "./EmptyState.module.scss";

const EmptyState = ({
  title,
  description,
  size = "normal",
}: {
  title: string;
  description?: string;
  size?: "normal" | "large";
}) => {
  return (
    <div
      className={cn(styles.emptyState, {
        [styles.large]: size === "large",
      })}
    >
      <div className={styles.image}>
        <img src={emptyStateImage} alt="No data" />
      </div>
      <div className={styles.title}>{title}</div>
      {description && <div className={styles.description}>{description}</div>}
    </div>
  );
};

export default EmptyState;
