import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import Select from "@/ui/Select";
import { useTournaments } from "@/api/query/useTournaments";

interface TournamentOption {
  id: number | null,
  name: string,
}

const TournamentFilter = ({
  value,
  onChange,
}: {
  value: number | null,
  onChange: (id: number | null) => void,
}) => {
  const { t } = useTranslation();
  const tournamentsQuery = useTournaments();

  const options = useMemo<TournamentOption[]>(() => {
    const mantra = (tournamentsQuery.data ?? [])
      .filter((tournament) => tournament.mantra_format)
      .map((tournament) => ({ id: tournament.id, name: tournament.name }));

    return [{ id: null, name: t("leaderboard.all_tournaments") }, ...mantra];
  }, [tournamentsQuery.data, t]);

  const selected = options.find((option) => option.id === value) ?? null;

  return (
    <Select<TournamentOption>
      value={selected}
      options={options}
      isLoading={tournamentsQuery.isLoading}
      onChange={(option) => onChange(option?.id ?? null)}
      getOptionValue={({ id }) => String(id)}
      formatOptionLabel={({ name }) => name}
    />
  );
};

export default TournamentFilter;
