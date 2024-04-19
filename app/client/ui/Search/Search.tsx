import React, { useEffect, useRef } from "react";
import SearchIcon from "@/assets/icons/search.svg";
import ClearIcon from "@/assets/icons/closeRing.svg";
import styles from "./Search.module.scss";

const Search = ({
  value,
  onChange,
  placeholder,
  autofocus,
}: {
  value: string,
  onChange: (value: string) => void,
  placeholder?: string,
  autofocus?: boolean,
}) => {
  const inputRef = useRef<HTMLInputElement>(null);

  const onChangeHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    onChange(event.target.value);
  };

  const clear = () => {
    onChange("");
  };

  useEffect(() => {
    if (autofocus) {
      inputRef.current?.focus();
    }
  }, [autofocus]);

  return (
    <div className={styles.inputWrapper}>
      <SearchIcon className={styles.searchIcon} />
      <input
        type="text"
        ref={inputRef}
        className={styles.input}
        value={value}
        onChange={onChangeHandler}
        placeholder={placeholder}
      />
      {value.length > 0 && (
        <button onClick={clear} className={styles.clearButton}>
          <ClearIcon />
        </button>
      )}
    </div>
  );
};

export default Search;
