import { useEffect, useRef } from "react";
import cn from "classnames";
import FocusTrap from "focus-trap-react";
import { useMountTransition } from "@/hooks/useMountTransition";
import { useCreatePortal } from "@/hooks/useCreatePortal";
import CloseIcon from "@/assets/icons/closeRound.svg";
import styles from "./Drawer.module.scss";

const DrawerWrapper = ({
  children,
  isOpen,
  isTransitioning,
  onClose,
}: {
  children: React.ReactNode,
  isOpen: boolean,
  isTransitioning: boolean,
  onClose: () => void,
}) => {
  const createPortal = useCreatePortal("drawer-root");
  const bodyRef = useRef(document.body);

  /**
   * Manage body overflow
   */
  useEffect(() => {
    if (!isOpen) {
      return;
    }

    bodyRef.current.style.overflow = "hidden";

    return () => {
      bodyRef.current.style.overflow = "";
    };
  }, [isOpen]);

  /**
   * Manage close drawer by keyboard
   */
  useEffect(() => {
    if (!isOpen) {
      return;
    }

    const onKeyPress = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        onClose();
      }
    };

    window.addEventListener("keyup", onKeyPress);

    return () => {
      window.removeEventListener("keyup", onKeyPress);
    };
  }, [isOpen]);

  if (!isTransitioning && !isOpen) {
    return null;
  }

  return createPortal(children);
};

const Drawer = ({
  title,
  children,
  isOpen,
  onClose,
}: {
  title: string,
  children: React.ReactNode,
  isOpen: boolean,
  onClose: () => void,
}) => {
  const isTransitioning = useMountTransition(isOpen, 300);

  return (
    <DrawerWrapper isOpen={isOpen} isTransitioning={isTransitioning} onClose={onClose}>
      <FocusTrap active={isOpen} focusTrapOptions={{ initialFocus: false }}>
        <div
          aria-hidden={isOpen ? "false" : "true"}
          className={cn(styles.drawerContainer, {
            [styles.isOpen]: isOpen,
            [styles.isTransitioning]: isTransitioning,
          })}
        >
          <div className={styles.drawer}>
            <div className={styles.header}>
              <span className={styles.title}>{title}</span>
              <button className={styles.closeButton} onClick={onClose}>
                <CloseIcon />
              </button>
            </div>
            <div className={styles.content}>{children}</div>
            <div className={styles.footer}>footer</div>
          </div>
          <div className={styles.backdrop} onClick={onClose} />
        </div>
      </FocusTrap>
    </DrawerWrapper>
  );
};

export default Drawer;