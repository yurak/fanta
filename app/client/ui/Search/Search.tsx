import React from "react";
import SearchIcon from "@/assets/icons/search.svg";
import ClearIcon from "@/assets/icons/closeRing.svg";
import styles from "./Search.module.scss";

const Search = ({
  value,
  onChange,
  placeholder,
}: {
  value: string,
  onChange: (value: string) => void,
  placeholder?: string,
}) => {
  const onChangeHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    onChange(event.target.value);
  };

  const clear = () => {
    onChange("");
  };

  return (
    <div className={styles.inputWrapper}>
      <SearchIcon className={styles.searchIcon} />
      <input
        type="text"
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
