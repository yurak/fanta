import cn from "classnames";
import { IPopoverRefrenceProps } from "@/ui/Popover";
import ExpandDown from "@/assets/icons/expandDown.svg";
import ClearIcon from "@/assets/icons/closeRing.svg";
import styles from "./PopoverInputButton.module.scss";

interface IProps extends IPopoverRefrenceProps {
  placeholder: string,
  selectedLabel?: string | null,
  clearValue: () => void,
}

const PopoverInputButton = ({
  placeholder,
  selectedLabel,
  clearValue,
  isOpen,
  setRef,
  ...props
}: IProps) => {
  const isActive = Boolean(selectedLabel);

  const onClear: React.MouseEventHandler<HTMLButtonElement> = (event) => {
    event.stopPropagation();
    clearValue();
  };

  return (
    <div className={styles.buttonWrapper}>
      <button
        ref={setRef}
        className={cn(styles.button, {
          [styles.isOpen]: isOpen,
          [styles.isActive]: isActive,
        })}
        {...props}
      >
        <span className={styles.buttonInner}>
          {selectedLabel ?? placeholder}
          {!isActive && (
            <span className={styles.iconWrapper}>
              <ExpandDown />
            </span>
          )}
        </span>
      </button>
      {isActive && (
        <button className={cn(styles.iconWrapper, styles.clearButton)} onClick={onClear}>
          <ClearIcon />
        </button>
      )}
    </div>
  );
};

export default PopoverInputButton;
