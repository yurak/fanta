import styles from "./DrawerButton.module.scss";
import ArrowDown from "@/assets/icons/arrow-down.svg";

const DrawerButton = ({
  onClick,
  title,
  value,
}: {
  onClick: () => void,
  title: string,
  value?: string,
}) => {
  return (
    <button onClick={onClick} className={styles.button}>
      <span className={styles.title}>{title}</span>
      <span className={styles.valueWrapper}>
        {value && <span className={styles.value}>{value}</span>}
        <span className={styles.icon}>
          <ArrowDown />
        </span>
      </span>
    </button>
  );
};

export default DrawerButton;
