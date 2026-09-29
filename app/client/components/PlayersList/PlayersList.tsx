import { useMediaQuery } from "usehooks-ts";
import { useTranslation } from "react-i18next";
import EmptyState from "@/ui/EmptyState";
import Button from "@/ui/Button";
import { usePlayersContext } from "@/application/Players/PlayersContext";
import PlayersListMobile from "./PlayersListMobile";
import PlayersListDesktop from "./PlayersListDesktop";

const PlayersList = ({ emptyState }: { emptyState?: React.ReactNode }) => {
  const { t } = useTranslation();

  const { openSidebar, clearAllFilter } = usePlayersContext();

  const isMobile = useMediaQuery("(max-width: 768px)");

  const defaultEmptyState = (
    <EmptyState
      title={t("players.results.playersNotFound")}
      description={t("players.results.playersNotFoundDescription")}
      actions={
        <>
          <Button onClick={openSidebar}>{t("players.filters.changeFilters")}</Button>
          <Button variant="secondary" onClick={clearAllFilter}>
            {t("players.filters.clearFilters")}
          </Button>
        </>
      }
    />
  );

  const Component = isMobile ? PlayersListMobile : PlayersListDesktop;

  return <Component emptyStateComponent={emptyState ?? defaultEmptyState} />;
};

export default PlayersList;
