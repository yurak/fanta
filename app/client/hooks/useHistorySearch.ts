import { useCustomSearchParams } from "./useCustomSearchParams";

export const useHistorySearch = (defaultSearch = ""): [string, (value: string) => void] => {
  const [searchParams, setSearchParams] = useCustomSearchParams();

  const search = searchParams.get("s", true) ?? defaultSearch;

  const setSearch = (search: string) => {
    setSearchParams(
      (prev) => {
        if (search) {
          prev.set("s", search, true);
        } else {
          prev.delete("s");
        }

        return prev;
      },
      {
        replace: true,
      }
    );
  };

  return [search, setSearch];
};
