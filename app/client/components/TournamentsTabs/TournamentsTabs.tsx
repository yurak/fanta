import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import Tabs from "../../ui/Tabs";
import { useTournaments } from "../../api/query/useTournaments";
import leaguesIcon from "../../../assets/images/icons/leagues.svg";

const TournamentsTabs = ({
  showAll,
  active,
  onChange,
}: {
  active: number | null;
  onChange: (active: number | null) => void;
  showAll?: boolean;
}) => {
  const { t } = useTranslation();
  const tournamentsQuery = useTournaments();

  const tournaments = useMemo(
    () => [
      ...(showAll
        ? [
            {
              id: null,
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
      nameRender={(tab) => <>{tab.name}</>}
    />
  );
};

export default TournamentsTabs;
