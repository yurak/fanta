import { useTranslation } from "react-i18next";
import PlayersPageContextProvider from "@/application/Players/PlayersPageConfigurationContext";
import PlayersPage from "@/components/PlayersPage";
import PageLayout from "@/layouts/PageLayout";

const Players = () => {
  const { t } = useTranslation();

  return (
    <PlayersPageContextProvider>
      <PageLayout>
        <PlayersPage title={t("players.players")} />
      </PageLayout>
    </PlayersPageContextProvider>
  );
};

export default Players;
