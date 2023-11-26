import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import Tabs, { ITab } from "../../ui/Tabs";
import { useTournaments } from "../../api/query/useTournaments";
import leaguesIcon from "../../../assets/images/icons/leagues.svg";

const TournamentsTabs = ({
  showAll,
  active,
  onChange,
  nameRender,
  isLoading,
}: {
  active?: number;
  onChange: (active?: number) => void;
  nameRender?: (tab: ITab<number | undefined>) => React.ReactNode;
  showAll?: boolean;
  isLoading?: boolean;
}) => {
  const { t } = useTranslation();
  const tournamentsQuery = useTournaments();

  const tournaments = useMemo<ITab<number | undefined>[]>(
    () => [
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
    ],
    [t, showAll, tournamentsQuery.data]
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
