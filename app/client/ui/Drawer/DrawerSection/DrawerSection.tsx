import styles from "./DrawerSection.module.scss";

const DrawerSection = ({ title, children }: { title: string, children: React.ReactNode }) => {
  return (
    <div className={styles.section}>
      <div className={styles.title}>{title}</div>
      <div>{children}</div>
    </div>
  );
};

export default DrawerSection;
