import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import PopoverInput from "@/ui/PopoverInput";
import { RadioboxGroup } from "@/ui/Radiobox";
import { IRoundLeague } from "@/interfaces/RoundPlayer";

// "All leagues" is represented as 0 in the radio group (it needs a non-null id)
// and mapped back to null in the filter value.
const ALL_LEAGUES = 0;

interface ILeagueOption {
  id: number,
  name: string,
}

interface IProps {
  leagues: IRoundLeague[],
  value: number | null,
  onChange: (value: number | null) => void,
}

// Inline single-select league list, shared by the desktop popover and the
// mobile filters drawer.
export const LeagueRadioGroup = ({ leagues, value, onChange }: IProps) => {
  const { t } = useTranslation();

  const options = useMemo<ILeagueOption[]>(
    () => [{ id: ALL_LEAGUES, name: t("round_players_page.filters.all_leagues") }, ...leagues],
    [leagues, t]
  );

  return (
    <RadioboxGroup<ILeagueOption, number>
      options={options}
      value={value ?? ALL_LEAGUES}
      onChange={(id) => onChange(id === ALL_LEAGUES ? null : id)}
      getOptionValue={(option) => option.id}
      getOptionKey={(option) => option.id}
      formatOptionLabel={(option) => option.name}
    />
  );
};

const LeagueFilter = ({ leagues, value, onChange }: IProps) => {
  const { t } = useTranslation();

  const selectedLabel = value ? leagues.find((league) => league.id === value)?.name ?? "..." : null;

  return (
    <PopoverInput
      label={t("round_players_page.filters.league")}
      selectedLabel={selectedLabel}
      clearValue={() => onChange(null)}
    >
      <LeagueRadioGroup leagues={leagues} value={value} onChange={onChange} />
    </PopoverInput>
  );
};

export default LeagueFilter;
