import { useCallback, useEffect, useMemo, useState } from "react";
import { useLeagues } from "../../../api/query/useLeagues";
import { ILeaguesWithTournament } from "../interfaces";

interface ISeasonOption {
  value: { startYear: number; endYear: number };
  label: string;
}

export const useSeasons = () => {
  const leaguesQuery = useLeagues();

  const [selected, setSelected] = useState<ISeasonOption | null>(null);

  const options = useMemo(() => {
    return Object.values(
      leaguesQuery.data.reduce((acc, league) => {
        const uniqueKey = `${league.season_start_year}-${league.season_end_year}`;

        return {
          ...acc,
          [uniqueKey]: {
            startYear: league.season_start_year,
            endYear: league.season_end_year,
          },
        };
      }, {} as Record<string, ISeasonOption["value"]>)
    ).map((value) => {
      const startYearShort = value.startYear.toString().slice(-2);
      const endYearShort = value.endYear.toString().slice(-2);

      return {
        value,
        label: `${startYearShort}/${endYearShort}`,
      };
    });
  }, [leaguesQuery.data]);

  useEffect(() => {
    if (options.length > 0 && !selected) {
      setSelected(options[0] ?? null);
    }
  }, [options]);

  const filterBySeason = useCallback(
    (leagues: ILeaguesWithTournament[]) => {
      if (!selected) {
        return leagues;
      }

      return leagues.filter(
        (league) =>
          league.season_start_year === selected.value.startYear &&
          league.season_end_year === selected.value.endYear
      );
    },
    [selected]
  );

  return {
    options,
    selected,
    setSelected,
    filterBySeason,
  };
};
