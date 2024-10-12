import cn from "classnames";
import { IPopoverRefrenceProps } from "@/ui/Popover";
import ExpandDown from "@/assets/icons/expandDown.svg";
import ClearIcon from "@/assets/icons/closeRing.svg";
import styles from "./PopoverInputButton.module.scss";

interface IProps extends IPopoverRefrenceProps {
  placeholder: string,
  selectedLabel?: React.ReactNode,
  isPristine: boolean,
  clearValue: () => void,
}

const PopoverInputButton = ({
  placeholder,
  selectedLabel,
  clearValue,
  isOpen,
  isPristine,
  setRef,
  ...props
}: IProps) => {
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
          [styles.isActive]: !isPristine,
        })}
        {...props}
      >
        <span className={styles.buttonInner}>
          {selectedLabel ?? placeholder}
          {isPristine && (
            <span className={styles.iconWrapper}>
              <ExpandDown />
            </span>
          )}
        </span>
      </button>
      {!isPristine && (
        <button className={cn(styles.iconWrapper, styles.clearButton)} onClick={onClear}>
          <ClearIcon />
        </button>
      )}
    </div>
  );
};

export default PopoverInputButton;
