import { useCallback, useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { useTournaments } from "@/api/query/useTournaments";
import { useLeagues } from "@/api/query/useLeagues";
import Search from "@/ui/Search";
import TournamentsTabs, { TournamentTab } from "@/components/TournamentsTabs";
import Heading from "@/components/Heading";
import SeasonsSelect from "@/components/SeasonsSelect";
import { ISeason } from "@/interfaces/Season";
import PageLayout from "@/layouts/PageLayout";
import LeaguesList from "./LeaguesList";
import { ILeaguesWithTournament } from "./interfaces";
import styles from "./Leagues.module.scss";

const LeaguesPage = () => {
  const { t } = useTranslation();

  const [selectedSeason, setSelectedSeason] = useState<ISeason | null>(null);
  const [activeTournament, setActiveTournament] = useState<number>();
  const [search, setSearch] = useState("");

  const tournamentsQuery = useTournaments();
  const leaguesQuery = useLeagues({
    season: selectedSeason?.id,
  });

  /**
   * Add tournament info to leagues
   */
  const allLeagues = useMemo<ILeaguesWithTournament[]>(() => {
    const tournamentMap = new Map(
      tournamentsQuery.data.map((tournament) => [tournament.id, tournament])
    );

    return leaguesQuery.data.map((league) => ({
      ...league,
      tournament: tournamentMap.get(league.tournament_id) ?? null,
    }));
  }, [leaguesQuery.data, tournamentsQuery.data]);

  /**
   * Filter by tournament
   */
  const filteredByTournament = useMemo(() => {
    if (!activeTournament) {
      return allLeagues;
    }

    return allLeagues.filter((league) => league.tournament_id === activeTournament);
  }, [allLeagues, activeTournament]);

  /**
   * Filter by search
   */
  const filteredBySearch = useMemo(() => {
    if (!search) {
      return filteredByTournament;
    }

    const searchInLowerCase = search.toLowerCase();

    return filteredByTournament.filter((league) =>
      league.name.toLowerCase().includes(searchInLowerCase)
    );
  }, [filteredByTournament, search]);

  const getLeagueCountByTournament = useCallback(
    (tournamentId?: number) => {
      if (!tournamentId) {
        return allLeagues.length;
      }

      return allLeagues.filter((league) => league.tournament_id === tournamentId).length;
    },
    [allLeagues]
  );

  const filterTournament = useCallback(
    (tab: TournamentTab) => getLeagueCountByTournament(tab.id) > 0,
    [getLeagueCountByTournament]
  );

  useEffect(() => {
    if (leaguesQuery.dataUpdatedAt) {
      const currentTabCount = getLeagueCountByTournament(activeTournament);

      if (currentTabCount === 0) {
        setActiveTournament(undefined);
      }
    }
  }, [leaguesQuery.dataUpdatedAt]);

  return (
    <PageLayout>
      <div className={styles.header}>
        <div className={styles.heading}>
          <Heading title={t("header.leagues")} noSpace />
        </div>
        <div className={styles.yearSelect}>
          <SeasonsSelect value={selectedSeason} onChange={setSelectedSeason} />
        </div>
        <div className={styles.search}>
          <Search
            value={search}
            onChange={setSearch}
            placeholder={t("league.search_placeholder")}
          />
        </div>
      </div>
      <div className={styles.tabs}>
        <TournamentsTabs
          showAll
          active={activeTournament}
          nameRender={(tab) => `${tab.name} (${getLeagueCountByTournament(tab.id)})`}
          filterTournament={filterTournament}
          onChange={setActiveTournament}
          isLoading={leaguesQuery.isPending}
        />
      </div>
      <LeaguesList
        dataSource={filteredBySearch}
        isLoading={leaguesQuery.isPending || tournamentsQuery.isPending}
      />
    </PageLayout>
  );
};

export default LeaguesPage;
