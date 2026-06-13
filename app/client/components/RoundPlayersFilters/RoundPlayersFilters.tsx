import { useTranslation } from "react-i18next";
import RoundPlayersFilterContextProvider, {
  useRoundPlayersFilterContext,
} from "@/application/RoundPlayers/RoundPlayersFilterContext";
import { useRoundPlayersPageConfigurationContext } from "@/application/RoundPlayers/RoundPlayersPageConfigurationContext";
import { PlayerPositionsCheckboxPopover } from "@/components/filters/PlayerPositionsCheckbox";
import RoundClubCheckbox from "./RoundClubCheckbox/RoundClubCheckbox";
import LeagueFilter from "./LeagueFilter";
import styles from "./RoundPlayersFilters.module.scss";

const RoundPlayersFilters = () => {
  const { t } = useTranslation();
  const { filterValues, onChangeValue } = useRoundPlayersFilterContext();
  const { leagues, clubs, national } = useRoundPlayersPageConfigurationContext();

  return (
    <div className={styles.wrapper}>
      <div className={styles.container}>
        {leagues.length > 0 && (
          <LeagueFilter
            leagues={leagues}
            value={filterValues.leagueId}
            onChange={onChangeValue("leagueId")}
          />
        )}
        <PlayerPositionsCheckboxPopover
          value={filterValues.position}
          onChange={onChangeValue("position")}
        />
        {clubs.length > 0 && (
          <RoundClubCheckbox
            clubs={clubs}
            value={filterValues.clubs}
            onChange={onChangeValue("clubs")}
            label={national ? t("round_players_page.filters.teams") : t("round_players_page.filters.clubs")}
          />
        )}
      </div>
    </div>
  );
};

export default () => (
  <RoundPlayersFilterContextProvider shouldApplyOnValueChange>
    <RoundPlayersFilters />
  </RoundPlayersFilterContextProvider>
);
