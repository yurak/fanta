import { createContext, useCallback, useContext, useMemo, useState } from "react";
import { useTournaments } from "@/api/query/useTournaments";
import { IClub } from "@/interfaces/Club";
import { ITournament } from "@/interfaces/Tournament";

export interface IProps {
  clubs: number[],
  tournaments: number[],
  onChange: (clubs: number[], tournaments: number[]) => void,
}

interface ITournamentWithClubs extends ITournament {
  clubs: IClub[],
}

const getTournamentsAndClubsWithoutTournaments = (
  clubs: number[],
  allTournaments: ITournamentWithClubs[]
): {
  tournaments: ITournamentWithClubs[],
  tournamentsIds: number[],
  clubs: number[],
} => {
  if (clubs.length === 0) {
    return {
      tournaments: [],
      tournamentsIds: [],
      clubs: [],
    };
  }

  const selectedTournaments = allTournaments.filter((tournament) =>
    tournament.clubs.every((club) => clubs.includes(club.id))
  );

  const matchedClubs = selectedTournaments.flatMap((tournament) =>
    tournament.clubs.map((club) => club.id)
  );

  const unMatchedClubs = clubs.filter((valueId) => !matchedClubs.includes(valueId));

  return {
    tournaments: selectedTournaments,
    tournamentsIds: selectedTournaments.map((tournament) => tournament.id),
    clubs: unMatchedClubs,
  };
};

const useClubCheckbox = ({
  clubs: selectedClubs,
  tournaments: selectedTournaments,
  onChange,
}: IProps) => {
  const { data } = useTournaments({ clubs: true });
  const [search, setSearch] = useState("");

  const allTournaments = useMemo<ITournamentWithClubs[]>(
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

  const value = useMemo<number[]>(() => {
    return [
      ...selectedClubs,
      ...allTournaments
        .filter((tournament) => selectedTournaments.includes(tournament.id))
        .flatMap((tournament) => tournament.clubs.map((club) => club.id)),
    ];
  }, [selectedClubs, selectedTournaments, allTournaments]);

  const tournamentsClubs = useMemo(() => {
    return allTournaments.reduce((map, tournament) => {
      return map.set(
        tournament.id,
        tournament.clubs.map((club) => club.id)
      );
    }, new Map<number, number[]>());
  }, [allTournaments]);

  const clubs = useMemo(() => {
    return allTournaments
      .flatMap((tournament) => tournament.clubs)
      .reduce((map, club) => {
        return map.set(club.id, club);
      }, new Map<number, IClub>());
  }, [allTournaments]);

  const onChangeHandler = (clubs: number[]) => {
    const { tournamentsIds, clubs: clubsIds } = getTournamentsAndClubsWithoutTournaments(
      clubs,
      allTournaments
    );

    onChange(clubsIds, tournamentsIds);
  };

  const toggleTournament = (id: number, checked: boolean) => {
    const tournamentClubs = tournamentsClubs.get(id) ?? [];

    if (checked) {
      onChangeHandler([...new Set([...value, ...tournamentClubs])]);
    } else {
      onChangeHandler(value.filter((v) => !tournamentClubs.includes(v)));
    }
  };

  const isTournamentChecked = (id: number): boolean => {
    return selectedTournaments.includes(id);
  };

  const isTournamentIndeterminate = (id: number): boolean => {
    const tournamentClubs = tournamentsClubs.get(id) ?? [];
    return tournamentClubs.some((club) => value.includes(club));
  };

  const toggleClubs = (tournamentId: number, ids: number[]) => {
    const tournamentClubs = tournamentsClubs.get(tournamentId) ?? [];
    onChangeHandler([...value.filter((v) => !tournamentClubs.includes(v)), ...ids]);
  };

  const filterTournaments = useMemo(() => {
    const lowerCaseSearch = search.toLowerCase();

    if (!lowerCaseSearch) {
      return allTournaments;
    }

    return allTournaments
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
  }, [allTournaments, search]);

  const getClubLabel = useCallback(
    (clubsId: number[]) => {
      if (clubsId.length === 0) {
        return null;
      }

      const club = clubs.get(clubsId[0] as number);

      if (!club) {
        return "..."; // Loading
      }

      if (clubsId.length === 1) {
        return club.name;
      }

      return `${club.name} + ${clubsId.length - 1}`;
    },
    [clubs]
  );

  const selectedLabel = useMemo(() => {
    if (value.length === 0) {
      return null;
    }

    const { tournaments, clubs } = getTournamentsAndClubsWithoutTournaments(value, allTournaments);

    return [
      ...(tournaments.length > 0
        ? tournaments.map((tournament) => tournament.short_name ?? tournament.name)
        : []),
      getClubLabel(clubs),
    ]
      .filter(Boolean)
      .join(" + ");
  }, [value, allTournaments, getClubLabel]);

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
    selectedLabel,
  };
};

const ClubCheckboxContext = createContext<null | ReturnType<typeof useClubCheckbox>>(null);

export const useClubCheckboxContext = () => {
  const context = useContext(ClubCheckboxContext);

  if (!context) {
    throw new Error("useClubCheckboxContext must be used within a ClubCheckboxContext");
  }

  return context;
};

export const ClubCheckboxContextProvider = ({
  children,
  ...props
}: IProps & { children: React.ReactNode }) => {
  return (
    <ClubCheckboxContext.Provider value={useClubCheckbox(props)}>
      {children}
    </ClubCheckboxContext.Provider>
  );
};
