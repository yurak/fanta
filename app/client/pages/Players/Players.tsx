import { useTranslation } from "react-i18next";
import PlayersPageConfigurationContextProvider from "@/application/Players/PlayersPageConfigurationContext";
import PlayersPage from "@/components/PlayersPage";
import PageLayout from "@/layouts/PageLayout";

const Players = () => {
  const { t } = useTranslation();

  return (
    <PlayersPageConfigurationContextProvider>
      <PageLayout>
        <PlayersPage title={t("players.players")} />
      </PageLayout>
    </PlayersPageConfigurationContextProvider>
  );
};

export default Players;
