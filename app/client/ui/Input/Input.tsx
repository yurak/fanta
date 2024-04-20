import { useEffect, useRef, useState } from "react";
import CloseIcon from "@/assets/icons/closeRing.svg";
import cn from "classnames";
import styles from "./Input.module.scss";

const Input = ({
  value,
  onChange,
  placeholder,
  autofocus,
  helper,
  icon,
  clearable,
  size = "large",
}: {
  value: string,
  onChange: (value: string) => void,
  placeholder?: string,
  autofocus?: boolean,
  helper?: string,
  icon?: React.ReactNode,
  clearable?: boolean,
  size?: "small" | "large",
}) => {
  const [isFocused, setIsFocused] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const onChangeHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    onChange(event.target.value);
  };

  const onFocusHandler = () => {
    setIsFocused(true);
  };

  const onBlurHandler = () => {
    setIsFocused(false);
  };

  const clear = () => {
    onChange("");
  };

  useEffect(() => {
    if (autofocus) {
      inputRef.current?.focus();
    }
  }, [autofocus]);

  const hasValue = value.length > 0;
  const isActivated = hasValue || isFocused;

  return (
    <div>
      <div
        className={cn(styles.wrapper, {
          [styles.isActivated]: isActivated,
          [styles.isFocused]: isFocused,
          [styles.withPlaceholder]: Boolean(placeholder),
          [styles.withLeftIcon]: Boolean(icon),
          [styles.withRightIcon]: clearable,
          [styles.small]: size === "small",
          [styles.large]: size === "large",
        })}
      >
        <input
          className={styles.input}
          value={value}
          onChange={onChangeHandler}
          onFocus={onFocusHandler}
          onBlur={onBlurHandler}
        />
        {placeholder && <span className={styles.placeholder}>{placeholder}</span>}
        {icon && <span className={styles.leftIcon}>{icon}</span>}
        {clearable && hasValue && (
          <button className={styles.clearButton} onClick={clear}>
            <CloseIcon />
          </button>
        )}
      </div>
      {helper && <div className={styles.helper}>{helper}</div>}
    </div>
  );
};

export default Input;
