import { useState } from "react";
import { flushSync } from "react-dom";
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
  FloatingFocusManager,
  size,
} from "@floating-ui/react";
import styles from "./Popover.module.scss";

export interface IReferenceProps extends Record<string, unknown> {
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
  const [maxHeight, setMaxHeight] = useState<number>();

  const { refs, floatingStyles, context } = useFloating({
    open: isOpen,
    onOpenChange: setIsOpen,
    middleware: [
      offset(8),
      shift(),
      autoPlacement({
        allowedPlacements: ["top-start", "top-end", "bottom-start", "bottom-end"],
      }),
      size({
        padding: 16,
        apply({ availableHeight }) {
          flushSync(() => setMaxHeight(availableHeight));
        },
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
          <FloatingFocusManager context={context} modal={false} initialFocus={refs.floating}>
            <div
              className={styles.popover}
              ref={refs.setFloating}
              style={{ ...floatingStyles, maxHeight }}
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
          </FloatingFocusManager>
        </FloatingPortal>
      )}
    </>
  );
};

export default Popover;
