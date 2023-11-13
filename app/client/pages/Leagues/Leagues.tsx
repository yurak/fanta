import { useMemo, useState } from "react";
// import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import calendarIcon from "../../../assets/images/icons/calendar.svg";
import { withBootstrap } from "../../bootstrap/withBootstrap";
import { ILeague } from "../../interfaces/League";
import { ITournament } from "../../interfaces/Tournament";
import Search from "../../ui/Search";
import Switcher from "../../ui/Switcher";
import Select from "../../ui/Select";
import Tabs, { ITab } from "../../ui/Tabs";
import styles from "./Leagues.module.scss";

// const getLeagueLink = (league: ILeague): string => `/tours/${league.id}`;
const getAssetsLink = (path: string) => `/assets/${path}`;

interface YearOption {
  value: string;
  label: string;
}

const LeaguesPage = ({
  leagues,
  active_tournaments,
}: {
  leagues: ILeague[];
  active_tournaments: ITournament[];
}) => {
  const yearOptions: YearOption[] = [
    { value: "22/23", label: "22/23" },
    { value: "21/22", label: "21/22" },
    { value: "20/21", label: "20/21" },
    { value: "19/20", label: "19/20" },
  ];

  const [activeLeague, setActiveLeague] = useState<"all" | number>("all");
  const [search, setSearch] = useState("");
  const [showFinished, setShowFinished] = useState(false);
  const [selectedYear, setSelectedYear] = useState<YearOption | null>(yearOptions[1] as YearOption);

  const { t } = useTranslation();

  type LeagueTab = ITab<typeof activeLeague> & { count: number };

  const leaguesTabs: LeagueTab[] = useMemo(
    () => [
      {
        id: "all",
        name: t("league.all"),
        icon: <img src={getAssetsLink("icons/leagues.svg")} alt="" />,
        count: 543,
      },
      ...active_tournaments.map((tournament) => ({
        id: tournament.id,
        name: tournament.short_name ?? tournament.name,
        icon: <img src={getAssetsLink(`tournaments/${tournament.code}.png`)} alt="" />,
        count: tournament.id,
      })),
    ],
    [t, active_tournaments]
  );

  // const [activeTab, setActiveTab] = useState<"all" | number>("all");

  // const visibleLeagues = useMemo(
  //   () =>
  //     leagues.filter((league) => {
  //       if (activeTab === "all") {
  //         return league.status === "active";
  //       }

  //       return league.tournament_id === activeTab;
  //     }),
  //   [leagues, activeTab]
  // );

  console.log({ leagues, active_tournaments, selectedYear });

  return (
    <>
      <div className={styles.header}>
        <div className={styles.heading}>
          <h3 className={styles.title}>{t("header.leagues")}</h3>
          <p className={styles.subtitle}>{t("league.subtitle")}</p>
        </div>
        <div className={styles.yearSelect}>
          <Select
            value={selectedYear}
            options={yearOptions}
            icon={<img src={calendarIcon} />}
            onChange={(value) => setSelectedYear(value)}
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
        <Tabs
          active={activeLeague}
          onChange={setActiveLeague}
          tabs={leaguesTabs}
          nameRender={(tab) => (
            <>
              {tab.name} ({tab.count})
            </>
          )}
        />
      </div>
    </>
  );
};

export default withBootstrap(LeaguesPage);

// <div className="leagues-lists-content">
//           <div className={cn(styles.listHeaders, "default-headers leagues-list-grid")}>
//             <div className="default-header-cell">{t("league.name")}</div>
//             <div className="default-header-cell">{t("league.division")}</div>
//             <div className="default-header-cell">{t("league.season")}</div>
//             <div className="default-header-cell mob-hide">{t("league.tournament")}</div>
//             {/* Uncomment the line below if 'league.leader' is needed */}
//             {/* <div className="default-header-cell mob-hide">{t('league.leader')}</div> */}
//             <div className="default-header-cell mob-hide">{t("league.teams")}</div>
//             <div className="default-header-cell mob-hide">{t("league.round")}</div>
//             <div className="default-header-cell">{t("league.status")}</div>
//           </div>
//           {visibleLeagues.map((league) => {
//             const leagueTournament = active_tournaments.find(
//               (tournament) => tournament.id === league.tournament_id
//             );

//             return (
//               <a key={league.id} href={getLeagueLink(league)}>
//                 <div className="leagues-list-item leagues-list-grid">
//                   <div className="leagues-list-item-param leagues-list-item-name">
//                     <div className="tournament-logo">
//                       {leagueTournament && (
//                         <img
//                           src={getAssetsLink(`tournaments/${leagueTournament.code}.png`)}
//                           alt=""
//                         />
//                       )}
//                     </div>
//                     <div className="league-item-name">{league.name}</div>
//                   </div>
//                   <div className="leagues-list-item-param center">
//                     {/* {league.division ? league.division.name : ""} */}
//                   </div>
//                   <div className="leagues-list-item-param center">
//                     {/* {`${league.season.start_year}-${league.season.end_year}`} */}
//                   </div>
//                   <div className="leagues-list-item-param mob-hide leagues-list-tournament">
//                     {leagueTournament?.name}
//                   </div>
//                   {/* Uncomment the lines below if 'league.leader' is needed */}
//                   {/* <div className="leagues-list-item-param mob-hide leagues-list-leader">
//                 {league.leader ? (
//                   <>
//                     <div className="leader-logo">
//                       Add content for leader logo
//                     </div>
//                     <div className="leader-name">{league.leader.human_name}</div>
//                   </>
//                 ) : ''}
//               </div> */}
//                   <div className="leagues-list-item-param mob-hide leagues-list-number">
//                     {/* {league.results.count} */}
//                   </div>
//                   <div className="leagues-list-item-param mob-hide leagues-list-number">
//                     {/* {league.active_tour?.number || league.tours.count} */}
//                   </div>
//                   <div className="leagues-list-item-param">
//                     <div className="leagues-list-status">
//                       {/* {league.active ? (
//               <div className="league-status league-active-status">t('league.ongoing')</div>
//             ) : league.archived ? (
//               <div className="league-status league-archived-status">
//                 t('league.finished')
//               </div>
//             ) : (
//               ""
//             )} */}
//                     </div>
//                   </div>
//                 </div>
//               </a>
//             );
//           })}
//         </div>
