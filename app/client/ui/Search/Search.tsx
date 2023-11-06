import { ChangeEvent } from "react";
import searchSvg from "../../../assets/images/icons/search.svg";
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
  const onChangeHandler = (event: ChangeEvent<HTMLInputElement>) => {
    event.preventDefault();
    onChange(event.target.value);
  };

  return (
    <div className={styles.inputWrapper}>
      <span className={styles.iconWrapper}>
        <img src={searchSvg} alt="Search" />
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
