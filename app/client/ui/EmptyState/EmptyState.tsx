import styles from "./EmptyState.module.scss";

const EmptyState = ({
  title,
  description,
  actions,
}: {
  title: string,
  description?: string,
  actions?: React.ReactNode,
}) => {
  return (
    <div className={styles.emptyState}>
      <div className={styles.pseudoIcon}>🐾</div>
      <div className={styles.title}>{title}</div>
      {description && <div className={styles.description}>{description}</div>}
      {actions && <div className={styles.actions}>{actions}</div>}
    </div>
  );
};

export default EmptyState;
