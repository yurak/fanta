import { useState } from "react";
import cn from "classnames";
import ArrowDown from "@/assets/icons/arrow-down.svg";
import styles from "./DrawerSection.module.scss";

const DrawerSection = ({
  title,
  children,
  withTopSpace,
  withBottomSpace,
  defaultOpen,
}: {
  title: string,
  children: React.ReactNode,
  withBottomSpace?: boolean,
  withTopSpace?: boolean,
  defaultOpen?: boolean,
}) => {
  const [isOpen, setIsOpen] = useState(defaultOpen ?? false);

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
      {isOpen && (
        <div
          className={cn(styles.content, {
            [styles.withTopSpace]: withTopSpace,
            [styles.withBottomSpace]: withBottomSpace,
          })}
        >
          {children}
        </div>
      )}
    </div>
  );
};

export default DrawerSection;
