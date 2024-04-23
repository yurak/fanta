import { useState } from "react";
import cn from "classnames";
import ArrowDown from "@/assets/icons/arrow-down.svg";
import styles from "./DrawerSection.module.scss";

const DrawerSection = ({ title, children }: { title: string, children: React.ReactNode }) => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className={styles.section}>
      <button className={styles.title} onClick={() => setIsOpen((o) => !o)}>
        {title}
        <span
          className={cn(styles.icon, {
            [styles.isActive]: isOpen,
          })}
        >
          <ArrowDown />
        </span>
      </button>
      {isOpen && <div className={styles.content}>{children}</div>}
    </div>
  );
};

export default DrawerSection;
