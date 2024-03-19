import { useMediaQuery } from "usehooks-ts";
import { useTranslation } from "react-i18next";
import LeaguesListDesktop from "./LeaguesListDesktop";
import LeaguesListMobile from "./LeaguesListMobile";
import EmptyState from "@/ui/EmptyState";
import Button from "@/ui/Button";
import { ILeaguesWithTournament } from "../interfaces";

const LeaguesList = ({
  dataSource,
  isLoading,
  clearFilters,
}: {
  dataSource: ILeaguesWithTournament[],
  isLoading: boolean,
  clearFilters: () => void,
}) => {
  const { t } = useTranslation();
  const isMobile = useMediaQuery("(max-width: 768px)");

  const Component = isMobile ? LeaguesListMobile : LeaguesListDesktop;

  return (
    <Component
      dataSource={dataSource}
      isLoading={isLoading}
      emptyStateComponent={
        <EmptyState
          title={t("league.empty_placeholder_title")}
          description={t("league.empty_placeholder_description")}
          actions={<Button onClick={clearFilters}>{t("league.empty_placeholder_button")}</Button>}
        />
      }
    />
  );
};

export default LeaguesList;
