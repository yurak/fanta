import { useTranslation } from "react-i18next";
import PlayersFilterContextProvider, {
  usePlayersFilterContext,
} from "@/application/Players/PlayersFilterContext";
import { PlayerPositionsCheckboxPopover } from "@/components/filters/PlayerPositionsCheckbox";
import PlayersFilterConstants from "@/domain/PlayersFilterConstants";
import { RangeSliderPopover } from "@/ui/RangeSlider";
import { ClubCheckboxPopover } from "@/components/ClubCheckbox";
import styles from "./PlayersFilters.module.scss";

const PlayerFilters = () => {
  const { t } = useTranslation();
  const { filterValues, onChangeValue } = usePlayersFilterContext();

  return (
    <div className={styles.wrapper}>
      <div className={styles.container}>
        <ClubCheckboxPopover value={filterValues.clubs} onChange={onChangeValue("clubs")} />
        <PlayerPositionsCheckboxPopover
          value={filterValues.position}
          onChange={onChangeValue("position")}
        />
        <RangeSliderPopover
          min={PlayersFilterConstants.TOTAL_SCORE_MIN}
          max={PlayersFilterConstants.TOTAL_SCORE_MAX}
          value={filterValues.totalScore}
          step={0.1}
          label={t("players.filters.totalScoreLabel")}
          valueLabel={t("players.filters.totalScoreShortLabel")}
          onChange={onChangeValue("totalScore")}
        />
        <RangeSliderPopover
          min={PlayersFilterConstants.BASE_SCORE_MIN}
          max={PlayersFilterConstants.BASE_SCORE_MAX}
          step={0.1}
          value={filterValues.baseScore}
          label={t("players.filters.baseScoreLabel")}
          valueLabel={t("players.filters.baseScoreShortLabel")}
          onChange={onChangeValue("baseScore")}
        />
        <RangeSliderPopover
          min={PlayersFilterConstants.APPEARANCES_MIN}
          max={PlayersFilterConstants.APPEARANCES_MAX}
          value={filterValues.appearances}
          label={t("players.filters.appearancesLabel")}
          valueLabel={t("players.filters.appearancesShortLabel")}
          onChange={onChangeValue("appearances")}
        />
        <RangeSliderPopover
          min={PlayersFilterConstants.TEAMS_COUNT_MIN}
          max={PlayersFilterConstants.TEAMS_COUNT_MAX}
          value={filterValues.teamsCount}
          label={t("players.filters.numberOfTeamsLabel")}
          onChange={onChangeValue("teamsCount")}
        />
        <RangeSliderPopover
          min={PlayersFilterConstants.PRICE_MIN}
          max={PlayersFilterConstants.PRICE_MAX}
          value={filterValues.price}
          label={t("players.filters.priceLabel")}
          onChange={onChangeValue("price")}
        />
      </div>
    </div>
  );
};

export default () => (
  <PlayersFilterContextProvider shouldApplyOnValueChange>
    <PlayerFilters />
  </PlayersFilterContextProvider>
);
