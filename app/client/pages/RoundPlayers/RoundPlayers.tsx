import { useState } from "react";
import Skeleton from "react-loading-skeleton";
import { useTranslation } from "react-i18next";
import { useParams } from "react-router-dom";
import RoundPlayersPageConfigurationContextProvider from "@/application/RoundPlayers/RoundPlayersPageConfigurationContext";
import RoundPlayersPage from "@/components/RoundPlayersPage";
import PageLayout from "@/layouts/PageLayout";
import { useRoundPlayersMeta } from "@/api/query/useRoundPlayersMeta";
import { useSearchParamsContext } from "@/application/SearchParamsContext";
import { IRoundPlayersMeta } from "@/interfaces/RoundPlayer";
import styles from "./RoundPlayers.module.scss";

// Keeps legacy server-rendered links working by mapping the old `?order=...`
// param onto the sort params the React page reads. The `league` param name is
// already shared. Legacy `position` is NOT remapped: it used Italian position
// codes, while the React picker uses classic codes (a different value set).
const useLegacyParamsMigration = () => {
  const { searchParams, setSearchParams } = useSearchParamsContext();

  useState(() => {
    if (typeof window === "undefined") {
      return null;
    }

    const order = searchParams.get("order");
    if (order && !searchParams.get("sortBy")) {
      searchParams.set("sortBy", order);
      searchParams.set("sortOrder", "desc");
      searchParams.delete("order");
      setSearchParams((prev) => prev, { replace: true });
    }

    return null;
  });
};

const RoundPlayersTitle = ({
  meta,
  isFetching,
}: {
  meta?: IRoundPlayersMeta,
  isFetching: boolean,
}) => {
  const { t } = useTranslation();

  if (isFetching || !meta) {
    return <Skeleton containerClassName={styles.skeleton} />;
  }

  return (
    <>
      {t("round_players_page.title")
        .replace("%{tournament}", meta.tournament_name)
        .replace("%{number}", String(meta.number))}
    </>
  );
};

const RoundPlayers = () => {
  useLegacyParamsMigration();

  const params = useParams<{ roundId: string }>();
  const roundId = Number(params.roundId);

  const { data: meta, isLoading, isPending } = useRoundPlayersMeta(roundId);

  return (
    <RoundPlayersPageConfigurationContextProvider roundId={roundId} meta={meta}>
      <PageLayout>
        <RoundPlayersPage
          title={<RoundPlayersTitle meta={meta} isFetching={isLoading || isPending} />}
        />
      </PageLayout>
    </RoundPlayersPageConfigurationContextProvider>
  );
};

export default RoundPlayers;
