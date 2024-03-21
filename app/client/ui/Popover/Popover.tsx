import { useState } from "react";
import CloseIcon from "@/assets/icons/closeRound.svg";
import {
  useClick,
  useDismiss,
  useInteractions,
  offset,
  shift,
  useFloating,
  autoUpdate,
  FloatingPortal,
  autoPlacement,
  ReferenceType,
} from "@floating-ui/react";
import styles from "./Popover.module.scss";

interface IReferenceProps extends Record<string, unknown> {
  isOpen: boolean,
  setRef: (node: ReferenceType | null) => void,
}

const Popover = ({
  title,
  children,
  footer,
  renderedReference,
}: {
  title: string,
  children: React.ReactNode,
  footer?: React.ReactNode,
  renderedReference: (props: IReferenceProps) => React.ReactNode,
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const close = () => setIsOpen(false);

  const { refs, floatingStyles, context } = useFloating({
    open: isOpen,
    onOpenChange: setIsOpen,
    middleware: [
      offset(8),
      shift(),
      autoPlacement({
        allowedPlacements: ["top-start", "top-end", "bottom-start", "bottom-end"],
      }),
    ],
    whileElementsMounted: autoUpdate,
  });

  const click = useClick(context);
  const dismiss = useDismiss(context);

  const { getReferenceProps, getFloatingProps } = useInteractions([click, dismiss]);

  return (
    <>
      {renderedReference({ isOpen, setRef: refs.setReference, ...getReferenceProps() })}
      {isOpen && (
        <FloatingPortal>
          <div
            className={styles.popover}
            ref={refs.setFloating}
            style={floatingStyles}
            {...getFloatingProps()}
          >
            <div className={styles.header}>
              <div className={styles.title}>{title}</div>
              <button className={styles.closeButton} onClick={close}>
                <CloseIcon />
              </button>
            </div>
            <div className={styles.content}>{children}</div>
            {footer && <div className={styles.footer}>{footer}</div>}
          </div>
        </FloatingPortal>
      )}
    </>
  );
};

export default Popover;
