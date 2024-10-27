import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import cn from "classnames";
import { ITournament } from "@/interfaces/Tournament";
import PopoverInput from "@/ui/PopoverInput";
import Checkbox, { CheckboxGroup } from "@/ui/Checkbox";
import Input from "@/ui/Input";
import { ClubCheckboxContextProvider, IProps, useClubCheckboxContext } from "./ClubCheckboxContext";
import ArrowDown from "@/assets/icons/arrow-down.svg";
import SearchIcon from "@/assets/icons/searchBold.svg";
import styles from "./ClubCheckbox.module.scss";

const Tournament = ({
  tournament,
  showLeagueSelect,
}: {
  tournament: ITournament,
  showLeagueSelect: boolean,
}) => {
  const {
    toggleTournament,
    isTournamentChecked,
    isTournamentIndeterminate,
    toggleClubs,
    value,
    isSearchActive,
  } = useClubCheckboxContext();

  const [isExpanded, setIsExpanded] = useState(false);

  const toggleExpanded = () => setIsExpanded((expaned) => !expaned);
  const toggleTournamentCheckbox = (checked: boolean) => toggleTournament(tournament.id, checked);
  const isChecked = isTournamentChecked(tournament.id);
  const isIndeterminate = isTournamentIndeterminate(tournament.id);
  const toggleClubsCheckboxGroup = (ids: number[]) => toggleClubs(tournament.id, ids);

  useEffect(() => {
    if (isSearchActive) {
      setIsExpanded(true);
    } else {
      setIsExpanded(false);
    }
  }, [isSearchActive]);

  const showLeagueTeams = showLeagueSelect ? isExpanded : true;

  return (
    <div key={tournament.id} className={styles.tournamentWrapper}>
      {showLeagueSelect && (
        <button className={styles.tournament} onClick={toggleExpanded}>
          <Checkbox
            checked={isChecked}
            indeterminate={isIndeterminate}
            onChange={toggleTournamentCheckbox}
          />
          <span className={styles.tournamentName}>{tournament.name}</span>
          <img src={tournament.logo} alt={tournament.name} className={styles.logo} />
          <span
            className={cn(styles.icon, {
              [styles.iconActive]: isExpanded,
            })}
          >
            <ArrowDown />
          </span>
        </button>
      )}
      {showLeagueTeams && tournament.clubs && (
        <div
          className={cn(styles.clubs, {
            [styles.clubsOffset]: showLeagueSelect,
          })}
        >
          <CheckboxGroup
            options={tournament.clubs}
            value={value}
            onChange={toggleClubsCheckboxGroup}
            getOptionValue={(club) => club.id}
            getOptionKey={(club) => club.id}
            formatOptionLabel={(club) => (
              <span className={styles.clubLabel}>
                <span>{club.name}</span>
                <img className={styles.logo} src={club.logo_path} />
              </span>
            )}
          />
        </div>
      )}
    </div>
  );
};

const ClubCheckbox = () => {
  const { filterTournaments, leagueId } = useClubCheckboxContext();

  return (
    <>
      {filterTournaments.map((tournament) => (
        <Tournament key={tournament.id} tournament={tournament} showLeagueSelect={!leagueId} />
      ))}
    </>
  );
};

const ClubSearch = ({ autofocus }: { autofocus?: boolean }) => {
  const { search, setSearch } = useClubCheckboxContext();
  const { t } = useTranslation();

  return (
    <Input
      value={search}
      onChange={setSearch}
      placeholder={t("players.filters.searchPlaceholder")}
      autofocus={autofocus}
      size="small"
      icon={<SearchIcon />}
    />
  );
};

const ClubCheckboxPopoverInner = () => {
  const { onChange, selectedLabel, leagueId } = useClubCheckboxContext();
  const { t } = useTranslation();

  return (
    <PopoverInput
      label={t("players.filters.clubsLabel")}
      selectedLabel={selectedLabel}
      clearValue={() => onChange([])}
      subHeader={!leagueId && <ClubSearch autofocus />}
    >
      <ClubCheckbox />
    </PopoverInput>
  );
};

export const ClubCheckboxPopover = (props: IProps) => {
  return (
    <ClubCheckboxContextProvider {...props}>
      <ClubCheckboxPopoverInner />
    </ClubCheckboxContextProvider>
  );
};

export default (props: IProps) => (
  <ClubCheckboxContextProvider {...props}>
    {!props.leagueId && <ClubSearch />}
    <ClubCheckbox />
  </ClubCheckboxContextProvider>
);
