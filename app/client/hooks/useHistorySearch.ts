import { useSearchParams } from "react-router-dom";

export const useHistorySearch = (defaultSearch = ""): [string, (value: string) => void] => {
  const [searchParams, setSearchParams] = useSearchParams();

  const search = searchParams.get("s") ?? defaultSearch;

  const setSearch = (search: string) => {
    setSearchParams(
      (prev) => {
        if (search) {
          prev.set("s", search.toString());
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
