import { useCallback, useMemo, useState } from "react";
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
import { useSeasons } from "./filters/useSeasons";
import { useFinished } from "./filters/useFinished";
import { useSearch } from "./filters/useSearch";

const LeaguesPage = () => {
  const tournamentsQuery = useTournaments();
  const leaguesQuery = useLeagues();

  const {
    options: seasonsOptions,
    selected: selectedSeason,
    setSelected: setSelectedSeason,
    filterBySeason,
  } = useSeasons();
  const { showFinished, setShowFinished, filterFinished } = useFinished();
  const { filterBySearch, search, setSearch } = useSearch();

  const allLeagues = useMemo<ILeaguesWithTournament[]>(() => {
    const tournamentMap = new Map(
      tournamentsQuery.data.map((tournament) => [tournament.id, tournament])
    );

    return leaguesQuery.data.map((league) => ({
      ...league,
      tournament: tournamentMap.get(league.tournament_id) ?? null,
    }));
  }, [leaguesQuery.data, tournamentsQuery.data]);

  const [activeTournament, setActiveTournament] = useState<number | null>(null);

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

  const filteredLeagues = useMemo(() => {
    return filterFinished(filterBySeason(filterBySearch(showActiveLeagues(allLeagues))));
  }, [allLeagues, filterFinished, showActiveLeagues, filterBySearch, filterBySeason]);

  return (
    <>
      <div className={styles.header}>
        <div className={styles.heading}>
          <PageHeading title={t("header.leagues")} description={t("league.subtitle")} />
        </div>
        <div className={styles.yearSelect}>
          <Select
            value={selectedSeason}
            options={seasonsOptions}
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
