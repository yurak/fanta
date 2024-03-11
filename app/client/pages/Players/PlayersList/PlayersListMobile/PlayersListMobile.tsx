import { IPlayer } from "@/interfaces/Player";
import { ITableSorting } from "@/ui/Table/interfaces";

const PlayersListMobile = ({
  items,
  isLoading,
  sorting,
}: {
  items: IPlayer[],
  isLoading: boolean,
  sorting: ITableSorting,
}) => {
  console.log({
    items,
    isLoading,
    sorting,
  });

  return <>mobile list</>;
};

export default PlayersListMobile;
