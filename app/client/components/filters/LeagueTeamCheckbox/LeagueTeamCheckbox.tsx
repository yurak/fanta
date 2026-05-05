import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import Checkbox, { CheckboxGroup } from "@/ui/Checkbox";
import PopoverInput from "@/ui/PopoverInput";
import { useLeagueTeams, ILeagueTeam } from "@/api/query/useLeagueTeams";
import NoTeamIcon from "@/assets/icons/noTeam.svg";
import styles from "./LeagueTeamCheckbox.module.scss";

interface IProps {
  leagueId: number,
  value: number[],
  onChange: (value: number[]) => void,
  withoutTeam?: boolean,
  onWithoutTeamChange?: (value: boolean) => void,
}

const LeagueTeamCheckbox = ({ leagueId, value, onChange, withoutTeam, onWithoutTeamChange }: IProps) => {
  const { t } = useTranslation();
  const { data: teams = [] } = useLeagueTeams(leagueId);

  return (
    <div className={styles.list}>
      {onWithoutTeamChange && (
        <Checkbox
          checked={!!withoutTeam}
          onChange={onWithoutTeamChange}
          label={(
            <span className={styles.option}>
              <NoTeamIcon className={styles.logo} />
              <span>{t("players.filters.withoutTeamLabel")}</span>
            </span>
          )}
        />
      )}
      <CheckboxGroup
        options={teams}
        value={value}
        onChange={onChange}
        getOptionValue={(team) => team.id}
        getOptionKey={(team) => team.id}
        formatOptionLabel={(team: ILeagueTeam) => (
          <span className={styles.option}>
            {team.logo_path && <img src={team.logo_path} alt={team.human_name} className={styles.logo} />}
            <span>{team.human_name}</span>
          </span>
        )}
      />
    </div>
  );
};

export const LeagueTeamCheckboxPopover = ({ leagueId, value, onChange, withoutTeam, onWithoutTeamChange }: IProps) => {
  const { t } = useTranslation();
  const { data: teams = [] } = useLeagueTeams(leagueId);

  const selectedLabel = useMemo(() => {
    const parts: string[] = [];

    if (withoutTeam) parts.push(t("players.filters.withoutTeamLabel"));

    if (value.length > 0) {
      const team = teams.find((t) => t.id === value[0]);
      const label = team?.human_name ?? String(value[0]);
      parts.push(value.length === 1 ? label : `${label} +${value.length - 1}`);
    }

    return parts.length > 0 ? parts.join(", ") : null;
  }, [value, teams, withoutTeam]);

  return (
    <PopoverInput
      label={t("players.filters.teamLabel")}
      selectedLabel={selectedLabel}
      clearValue={() => { onChange([]); onWithoutTeamChange?.(false); }}
    >
      <LeagueTeamCheckbox
        leagueId={leagueId}
        value={value}
        onChange={onChange}
        withoutTeam={withoutTeam}
        onWithoutTeamChange={onWithoutTeamChange}
      />
    </PopoverInput>
  );
};

export default LeagueTeamCheckbox;
