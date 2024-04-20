import { createContext, useContext, useEffect, useMemo, useState } from "react";
import cn from "classnames";
import { useTournaments } from "@/api/query/useTournaments";
import { ITournament } from "@/interfaces/Tournament";
import PopoverInput from "@/ui/PopoverInput";
import Checkbox, { CheckboxGroup } from "@/ui/Checkbox";
import ArrowDown from "@/assets/icons/arrow-down.svg";
import SearchIcon from "@/assets/icons/searchBold.svg";
import Input from "@/ui/Input";
import styles from "./ClubCheckbox.module.scss";

interface IProps {
  value: number[],
  onChange: (value: number[]) => void,
}

const useClubCheckbox = ({ value, onChange }: IProps) => {
  const { data } = useTournaments({ clubs: true });
  const [search, setSearch] = useState("");

  const tournaments = useMemo(
    () =>
      (data ?? [])
        .filter((tournament) => tournament.mantra_format)
        .map((tournament) => ({
          ...tournament,
          clubs: (tournament?.clubs ?? []).sort((clubA, clubB) =>
            clubA.name.localeCompare(clubB.name)
          ),
        })),
    [data]
  );

  const tournamentsClubs = useMemo(() => {
    return tournaments.reduce((map, tournament) => {
      return map.set(
        tournament.id,
        tournament.clubs.map((club) => club.id)
      );
    }, new Map<number, number[]>());
  }, [tournaments]);

  const toggleTournament = (id: number, checked: boolean) => {
    const tournamentClubs = tournamentsClubs.get(id) ?? [];

    if (checked) {
      onChange([...new Set([...value, ...tournamentClubs])]);
    } else {
      onChange(value.filter((v) => !tournamentClubs.includes(v)));
    }
  };

  const isTournamentChecked = (id: number): boolean => {
    const tournamentClubs = tournamentsClubs.get(id) ?? [];
    return tournamentClubs.every((club) => value.includes(club));
  };

  const isTournamentIndeterminate = (id: number): boolean => {
    const tournamentClubs = tournamentsClubs.get(id) ?? [];
    return tournamentClubs.some((club) => value.includes(club));
  };

  const toggleClubs = (tournamentId: number, ids: number[]) => {
    const tournamentClubs = tournamentsClubs.get(tournamentId) ?? [];
    onChange([...value.filter((v) => !tournamentClubs.includes(v)), ...ids]);
  };

  const filterTournaments = useMemo(() => {
    const lowerCaseSearch = search.toLowerCase();

    if (!lowerCaseSearch) {
      return tournaments;
    }

    return tournaments
      .map((tournament) => {
        const isTournamentMatched = tournament.name.toLowerCase().includes(lowerCaseSearch);

        return {
          ...tournament,
          ...(!isTournamentMatched && {
            clubs: tournament.clubs.filter((club) =>
              club.name.toLowerCase().includes(lowerCaseSearch)
            ),
          }),
        };
      })
      .filter((tournament) => tournament.clubs.length > 0);
  }, [tournaments, search]);

  const isSearchActive =
    filterTournaments.length === 1 ||
    filterTournaments.flatMap((tournament) => tournament.clubs).length < 10;

  return {
    filterTournaments,
    toggleTournament,
    isTournamentChecked,
    isTournamentIndeterminate,
    toggleClubs,
    value,
    onChange,
    search,
    setSearch,
    isSearchActive,
  };
};

const ClubCheckboxContext = createContext<null | ReturnType<typeof useClubCheckbox>>(null);

const useClubCheckboxContext = () => {
  const context = useContext(ClubCheckboxContext);

  if (!context) {
    throw new Error("useClubCheckboxContext must be used within a ClubCheckboxContext");
  }

  return context;
};

const ClubCheckboxContextProvider = ({
  children,
  ...props
}: IProps & { children: React.ReactNode }) => {
  return (
    <ClubCheckboxContext.Provider value={useClubCheckbox(props)}>
      {children}
    </ClubCheckboxContext.Provider>
  );
};

const Tournament = ({ tournament }: { tournament: ITournament }) => {
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

  return (
    <div key={tournament.id} className={styles.tournamentWrapper}>
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
      {tournament.clubs && isExpanded && (
        <div className={styles.clubs}>
          <CheckboxGroup
            options={tournament.clubs}
            value={value}
            onChange={toggleClubsCheckboxGroup}
            getOptionValue={(club) => club.id}
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
  const { filterTournaments, search, setSearch } = useClubCheckboxContext();

  return (
    <div>
      <div className={styles.search}>
        <Input
          value={search}
          onChange={setSearch}
          placeholder="Search"
          autofocus
          size="small"
          icon={<SearchIcon />}
        />
      </div>
      {filterTournaments.map((tournament) => (
        <Tournament key={tournament.id} tournament={tournament} />
      ))}
    </div>
  );
};

const ClubCheckboxPopoverInner = () => {
  const { value, onChange } = useClubCheckboxContext();

  const selectedLabel = useMemo(() => {
    if (value.length === 0) {
      return null;
    }

    if (value.length === 1) {
      return value[0] ?? null;
    }

    return `${value[0]} +${value.length - 1}`;
  }, [value]);

  return (
    <PopoverInput label="Clubs" selectedLabel={selectedLabel} clearValue={() => onChange([])}>
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
    <ClubCheckbox />
  </ClubCheckboxContextProvider>
);
