import { useTranslation } from "react-i18next";
import PlayersPage from "@/components/PlayersPage";
import PageLayout from "@/layouts/PageLayout";

const Players = () => {
  const { t } = useTranslation();

  return (
    <PageLayout>
      <PlayersPage title={t("players.players")} />
    </PageLayout>
  );
};

export default Players;
