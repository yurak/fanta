import cn from "classnames";
import EmptyStateIcon from "../../assets/images/empty-state.svg";
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
      <EmptyStateIcon className={styles.image} />
      <div className={styles.title}>{title}</div>
      {description && <div className={styles.description}>{description}</div>}
    </div>
  );
};

export default EmptyState;
