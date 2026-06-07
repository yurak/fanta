import { useMediaQuery } from "usehooks-ts";
import { useTranslation } from "react-i18next";
import EmptyState from "@/ui/EmptyState";
import Button from "@/ui/Button";
import { useRoundPlayersContext } from "@/application/RoundPlayers/RoundPlayersContext";
import RoundPlayersListMobile from "./RoundPlayersListMobile";
import RoundPlayersListDesktop from "./RoundPlayersListDesktop";

const RoundPlayersList = () => {
  const { t } = useTranslation();

  const { clearAllFilter } = useRoundPlayersContext();

  const isMobile = useMediaQuery("(max-width: 768px)");

  const emptyStateComponent = (
    <EmptyState
      title={t("round_players_page.not_found")}
      description={t("round_players_page.not_found_description")}
      actions={
        <Button variant="secondary" onClick={clearAllFilter}>
          {t("round_players_page.clear_filters")}
        </Button>
      }
    />
  );

  const Component = isMobile ? RoundPlayersListMobile : RoundPlayersListDesktop;

  return <Component emptyStateComponent={emptyStateComponent} />;
};

export default RoundPlayersList;
