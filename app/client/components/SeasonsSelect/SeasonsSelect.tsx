import { useEffect, useMemo } from "react";
import Select from "../../ui/Select";
import { useSeasons } from "../../api/query/useSeasons";
import { ISeason } from "../../interfaces/Season";
import calendarIcon from "../../../assets/images/icons/calendar.svg";

const SeasonsSelect = ({
  value,
  onChange,
}: {
  value: ISeason | null;
  onChange: (season: ISeason) => void;
}) => {
  const seasonsQuery = useSeasons();

  const options = useMemo(
    () =>
      seasonsQuery.data.sort((seasonA, seasonB) => {
        return seasonB.start_year - seasonA.start_year;
      }),
    [seasonsQuery.data]
  );

  useEffect(() => {
    if (options[0] && !value) {
      onChange(options[0]);
    }
  }, [options]);

  return (
    <Select
      value={value}
      options={options}
      icon={<img src={calendarIcon} />}
      onChange={onChange}
      isLoading={seasonsQuery.isLoading}
      formatOptionLabel={({ start_year, end_year }) => {
        const startYearShort = start_year.toString().slice(-2);
        const endYearShort = end_year.toString().slice(-2);

        return `${startYearShort}/${endYearShort}`;
      }}
      getOptionValue={({ start_year }) => String(start_year)}
    />
  );
};

export default SeasonsSelect;
