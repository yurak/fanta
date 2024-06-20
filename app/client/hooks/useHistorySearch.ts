import { useSearchParamsContext } from "@/application/SearchParamsContext";

export const useHistorySearch = (defaultSearch = ""): [string, (value: string) => void] => {
  const { searchParams, setSearchParams } = useSearchParamsContext();

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
