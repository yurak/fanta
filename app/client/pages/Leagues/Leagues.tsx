import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { withBootstrap } from "../../bootstrap/withBootstrap";
import { useTournaments } from "../../api/query/useTournaments";
import { useLeagues } from "../../api/query/useLeagues";
import Search from "../../ui/Search";
import TournamentsTabs from "../../components/TournamentsTabs";
import PageHeading from "../../components/PageHeading";
import SeasonsSelect from "../../components/SeasonsSelect";
import LeaguesTable from "./LeaguesTable";
import { ILeaguesWithTournament } from "./interfaces";
import { ISeason } from "../../interfaces/Season";
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

  return (
    <>
      <div className={styles.header}>
        <div className={styles.heading}>
          <PageHeading title={t("header.leagues")} />
        </div>
        <div className={styles.yearSelect}>
          <SeasonsSelect value={selectedSeason} onChange={setSelectedSeason} />
        </div>
        <div className={styles.search}>
          <Search value={search} onChange={setSearch} placeholder="Search league" />
        </div>
      </div>
      <div style={{ marginTop: 28 }}>
        <TournamentsTabs showAll active={activeTournament} onChange={setActiveTournament} />
      </div>
      <div>
        <LeaguesTable
          dataSource={filteredBySearch}
          isLoading={leaguesQuery.isPending || tournamentsQuery.isPending}
        />
      </div>
    </>
  );
};

export default withBootstrap(LeaguesPage);
