import { useEffect, useRef } from "react";
import cn from "classnames";
import FocusTrap from "focus-trap-react";
import { useMountTransition } from "@/hooks/useMountTransition";
import { useCreatePortal } from "@/hooks/useCreatePortal";
import DrawerSection from "./DrawerSection";
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
  footer,
  isOpen,
  onClose,
  placement = "left",
  noPadding,
}: {
  title: string,
  children: React.ReactNode,
  isOpen: boolean,
  onClose: () => void,
  footer?: React.ReactNode,
  placement?: "left" | "bottom",
  noPadding?: boolean,
}) => {
  const isTransitioning = useMountTransition(isOpen, 300);

  return (
    <DrawerWrapper isOpen={isOpen} isTransitioning={isTransitioning} onClose={onClose}>
      <FocusTrap
        active={isOpen}
        focusTrapOptions={{
          initialFocus: false,
        }}
      >
        <div
          aria-hidden={isOpen ? "false" : "true"}
          className={cn(styles.drawerContainer, {
            [styles.isOpen]: isOpen,
            [styles.isTransitioning]: isTransitioning,
          })}
        >
          <div className={styles.backdrop} onClick={onClose} />
          <div
            className={cn(styles.drawer, {
              [styles.left]: placement === "left",
              [styles.bottom]: placement === "bottom",
            })}
          >
            <div className={styles.header}>
              <span className={styles.title}>{title}</span>
              <button className={styles.closeButton} onClick={onClose}>
                <CloseIcon />
              </button>
            </div>
            <div
              className={cn(styles.content, {
                [styles.noPadding]: noPadding,
              })}
            >
              {children}
            </div>
            {footer && <div className={styles.footer}>{footer}</div>}
          </div>
        </div>
      </FocusTrap>
    </DrawerWrapper>
  );
};

Drawer.Section = DrawerSection;

export default Drawer;
