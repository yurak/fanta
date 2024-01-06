import styles from "./PageHeading.module.scss";

const PageHeading = ({ title, description }: { title: string, description?: string }) => (
  <div>
    <h3 className={styles.title}>{title}</h3>
    {description && <p className={styles.description}>{description}</p>}
  </div>
);

export default PageHeading;
