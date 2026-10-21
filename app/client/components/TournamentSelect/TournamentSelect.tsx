import { useMemo } from "react";
import Select from "@/ui/Select";
import { useTournaments } from "@/api/query/useTournaments";
import { ITournament } from "@/interfaces/Tournament";
import { flagCode } from "@/utils/flagCode";
import styles from "./TournamentSelect.module.scss";

// The flag rather than the crest. The country comes out of `Tournament#icon`, which already
// holds a flag emoji; the emoji itself stands in for the competitions that have no country
// (the world cups carry a globe).
const TournamentSelect = ({
  value,
  onChange,
  filter,
}: {
  value: ITournament | null,
  onChange: (tournament: ITournament) => void,
  filter?: (tournament: ITournament) => boolean,
}) => {
  const tournamentsQuery = useTournaments();
  const options = useMemo(() => {
    const all = tournamentsQuery.data ?? [];

    return filter ? all.filter(filter) : all;
  }, [tournamentsQuery.data, filter]);


  return (
    <Select
      value={value}
      options={options}
      onChange={onChange}
      isLoading={tournamentsQuery.isLoading}
      formatOptionLabel={({ icon, name, short_name }) => {
        const code = flagCode(icon);

        return (
          <span className={styles.option}>
            {code ? (
              <span className={`flag-icon flag-icon-${code} ${styles.flag}`} />
            ) : (
              <span className={styles.emoji}>{icon}</span>
            )}
            {short_name || name}
          </span>
        );
      }}
      getOptionValue={({ id }) => String(id)}
    />
  );
};

export default TournamentSelect;
