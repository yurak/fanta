import { useCallback, useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { withBootstrap } from "../../bootstrap/withBootstrap";
import { useTournaments } from "../../api/query/useTournaments";
import { useLeagues } from "../../api/query/useLeagues";
import Search from "../../ui/Search";
import Switcher from "../../ui/Switcher";
import Select from "../../ui/Select";
import TournamentsTabs from "../../components/TournamentsTabs";
import PageHeading from "../../components/PageHeading";
import LeaguesTable from "./LeaguesTable";
import calendarIcon from "../../../assets/images/icons/calendar.svg";
import { ILeaguesWithTournament } from "./interfaces";
import styles from "./Leagues.module.scss";

const LeaguesPage = () => {
  const tournamentsQuery = useTournaments();
  const leaguesQuery = useLeagues();

  const allLeagues = useMemo<ILeaguesWithTournament[]>(() => {
    const tournamentMap = new Map(
      tournamentsQuery.data.map((tournament) => [tournament.id, tournament])
    );

    return leaguesQuery.data.map((league) => ({
      ...league,
      tournament: tournamentMap.get(league.tournament_id) ?? null,
    }));
  }, [leaguesQuery.data, tournamentsQuery.data]);

  const yearOptions = useMemo(() => {
    return Object.values(
      allLeagues.reduce((acc, league) => {
        const uniqueKey = `${league.season_start_year}-${league.season_end_year}`;

        return {
          ...acc,
          [uniqueKey]: {
            startYear: league.season_start_year,
            endYear: league.season_end_year,
          },
        };
      }, {} as Record<string, { startYear: number; endYear: number }>)
    ).map((value) => {
      const startYearShort = value.startYear.toString().slice(-2);
      const endYearShort = value.endYear.toString().slice(-2);

      return {
        value,
        label: `${startYearShort}/${endYearShort}`,
      };
    });
  }, [allLeagues]);

  const [activeTournament, setActiveTournament] = useState<number | null>(null);
  const [search, setSearch] = useState("");
  const [showFinished, setShowFinished] = useState(false);
  const [selectedSeason, setSelectedSeason] = useState<(typeof yearOptions)[0] | null>(null);

  useEffect(() => {
    if (yearOptions.length > 0 && !selectedSeason) {
      setSelectedSeason(yearOptions[0] ?? null);
    }
  }, [yearOptions]);

  const { t } = useTranslation();

  const showActiveLeagues = useCallback(
    (leagues: typeof allLeagues) => {
      if (!activeTournament) {
        return leagues;
      }

      return leagues.filter((league) => league.tournament_id === activeTournament);
    },
    [activeTournament]
  );

  const toggleFinished = useCallback(
    (leagues: typeof allLeagues) => {
      if (showFinished) {
        return leagues;
      }

      return leagues.filter((league) => league.status !== "archived");
    },
    [showFinished]
  );

  const searchLeague = useCallback(
    (leagues: typeof allLeagues) => {
      if (!search) {
        return leagues;
      }

      const searchInLowerCase = search.toLowerCase();

      return leagues.filter((league) => league.name.toLowerCase().includes(searchInLowerCase));
    },
    [search]
  );

  const filterBySeason = useCallback(
    (leagues: typeof allLeagues) => {
      if (!selectedSeason) {
        return leagues;
      }

      return leagues.filter(
        (league) =>
          league.season_start_year === selectedSeason.value.startYear &&
          league.season_end_year === selectedSeason.value.endYear
      );
    },
    [selectedSeason]
  );

  const filteredLeagues = useMemo(() => {
    return toggleFinished(filterBySeason(showActiveLeagues(searchLeague(allLeagues))));
  }, [allLeagues, toggleFinished, showActiveLeagues, searchLeague, filterBySeason]);

  return (
    <>
      <div className={styles.header}>
        <div className={styles.heading}>
          <PageHeading title={t("header.leagues")} description={t("league.subtitle")} />
        </div>
        <div className={styles.yearSelect}>
          <Select
            value={selectedSeason}
            options={yearOptions}
            icon={<img src={calendarIcon} />}
            onChange={setSelectedSeason}
          />
        </div>
        <div className={styles.search}>
          <Search value={search} onChange={setSearch} placeholder="Search league" />
        </div>
        <div className={styles.finished}>
          <Switcher checked={showFinished} onChange={setShowFinished} label="🏁️  Show finished" />
        </div>
      </div>
      <div style={{ marginTop: 28 }}>
        <TournamentsTabs showAll active={activeTournament} onChange={setActiveTournament} />
      </div>
      <div>
        <LeaguesTable dataSource={filteredLeagues} />
      </div>
    </>
  );
};

export default withBootstrap(LeaguesPage);
