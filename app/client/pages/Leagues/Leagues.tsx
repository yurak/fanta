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
  const tournamentsQuery = useTournaments();

  const [selectedSeason, setSelectedSeason] = useState<ISeason | null>(null);
  const [activeTournament, setActiveTournament] = useState<number>();
  const [search, setSearch] = useState("");

  const { t } = useTranslation();

  const leaguesQuery = useLeagues({
    tournament: activeTournament,
    season: selectedSeason?.id,
  });

  const allLeagues = useMemo<ILeaguesWithTournament[]>(() => {
    const tournamentMap = new Map(
      tournamentsQuery.data.map((tournament) => [tournament.id, tournament])
    );

    return leaguesQuery.data.map((league) => ({
      ...league,
      tournament: tournamentMap.get(league.tournament_id) ?? null,
    }));
  }, [leaguesQuery.data, tournamentsQuery.data]);

  return (
    <>
      <div className={styles.header}>
        <div className={styles.heading}>
          <PageHeading title={t("header.leagues")} description={t("league.subtitle")} />
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
          dataSource={allLeagues}
          search={search}
          isLoading={leaguesQuery.status === "pending"}
        />
      </div>
    </>
  );
};

export default withBootstrap(LeaguesPage);
