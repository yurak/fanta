import React from "react";
import SearchIcon from "../../assets/icons/search.svg";
import styles from "./Search.module.scss";

const Search = ({
  value,
  onChange,
  placeholder,
}: {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
}) => {
  const onChangeHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    onChange(event.target.value);
  };

  return (
    <div className={styles.inputWrapper}>
      <span className={styles.iconWrapper}>
        <SearchIcon />
      </span>
      <input
        type="search"
        className={styles.input}
        value={value}
        onChange={onChangeHandler}
        placeholder={placeholder}
      />
    </div>
  );
};

export default Search;
