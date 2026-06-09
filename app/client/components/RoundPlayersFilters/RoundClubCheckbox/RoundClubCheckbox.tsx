import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import PopoverInput from "@/ui/PopoverInput";
import { CheckboxGroup } from "@/ui/Checkbox";
import Input from "@/ui/Input";
import SearchIcon from "@/assets/icons/searchBold.svg";
import { IRoundClub } from "@/interfaces/RoundPlayer";
import styles from "./RoundClubCheckbox.module.scss";

interface IListProps {
  clubs: IRoundClub[],
  value: number[],
  onChange: (value: number[]) => void,
}

interface IProps extends IListProps {
  label: string,
}

// Search + multi-select list of clubs/national teams, shared by the desktop
// popover and the mobile filters drawer.
export const RoundClubCheckboxList = ({ clubs, value, onChange }: IListProps) => {
  const { t } = useTranslation();
  const [search, setSearch] = useState("");

  const filteredClubs = useMemo(() => {
    const lowerCaseSearch = search.toLowerCase().trim();

    if (!lowerCaseSearch) {
      return clubs;
    }

    return clubs.filter((club) => club.name.toLowerCase().includes(lowerCaseSearch));
  }, [clubs, search]);

  // CheckboxGroup reports the checked ids among the currently visible (filtered)
  // options, so selections outside the search term are merged back in here.
  const handleChange = (checkedIds: number[]) => {
    const visibleIds = filteredClubs.map((club) => club.id);
    onChange([...value.filter((id) => !visibleIds.includes(id)), ...checkedIds]);
  };

  return (
    <>
      <Input
        value={search}
        onChange={setSearch}
        placeholder={t("round_players_page.search_placeholder")}
        size="small"
        icon={<SearchIcon />}
      />
      <div className={styles.clubs}>
        <CheckboxGroup
          options={filteredClubs}
          value={value}
          onChange={handleChange}
          getOptionValue={(club) => club.id}
          getOptionKey={(club) => club.id}
          formatOptionLabel={(club) => (
            <span className={styles.clubLabel}>
              <span>{club.name}</span>
              {club.flag_code ? (
                <span className={`flag-icon flag-icon-${club.flag_code.toLowerCase()}`} />
              ) : (
                club.logo_path && (
                  <img className={styles.logo} src={club.logo_path} alt={club.name} />
                )
              )}
            </span>
          )}
        />
      </div>
    </>
  );
};

const RoundClubCheckbox = ({ clubs, value, onChange, label }: IProps) => {
  const selectedLabel = useMemo(() => {
    if (value.length === 0) {
      return null;
    }

    const first = clubs.find((club) => club.id === value[0]);

    if (!first) {
      return "...";
    }

    return value.length === 1 ? first.name : `${first.name} + ${value.length - 1}`;
  }, [value, clubs]);

  return (
    <PopoverInput label={label} selectedLabel={selectedLabel} clearValue={() => onChange([])}>
      <RoundClubCheckboxList clubs={clubs} value={value} onChange={onChange} />
    </PopoverInput>
  );
};

export default RoundClubCheckbox;
