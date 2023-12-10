import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import Tabs, { ITab } from "../../ui/Tabs";
import { useTournaments } from "../../api/query/useTournaments";
import leaguesIcon from "../../../assets/images/icons/leagues.svg";

export type TournamentTab = ITab<number | undefined>;

const defaultFilterTournament = () => true;

const TournamentsTabs = ({
  showAll,
  active,
  onChange,
  nameRender,
  filterTournament = defaultFilterTournament,
  isLoading,
}: {
  active?: number;
  onChange: (active?: number) => void;
  nameRender?: (tab: TournamentTab) => React.ReactNode;
  filterTournament?: (tab: TournamentTab) => boolean;
  showAll?: boolean;
  isLoading?: boolean;
}) => {
  const { t } = useTranslation();
  const tournamentsQuery = useTournaments();

  const tournaments = useMemo<TournamentTab[]>(
    () =>
      [
        ...(showAll
          ? [
              {
                id: undefined,
                name: t("league.all"),
                icon: <img src={leaguesIcon} alt="" />,
              },
            ]
          : []),
        ...tournamentsQuery.data.map((tournament) => ({
          id: tournament.id,
          name: tournament.short_name ?? tournament.name,
          icon: <img src={tournament.logo} alt="" />,
        })),
      ].filter(filterTournament),
    [t, showAll, tournamentsQuery.data, filterTournament]
  );

  return (
    <Tabs
      active={active}
      onChange={onChange}
      tabs={tournaments}
      nameRender={nameRender}
      isLoading={tournamentsQuery.isLoading || isLoading}
      skeletonItems={12}
    />
  );
};

export default TournamentsTabs;
