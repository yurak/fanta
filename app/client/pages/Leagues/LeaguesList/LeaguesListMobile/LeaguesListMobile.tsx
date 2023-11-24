import DataList from "../../../../ui/DataList";
import { ILeaguesWithTournament } from "../../interfaces";

const LeaguesListMobile = ({
  dataSource,
  isLoading,
}: {
  dataSource: ILeaguesWithTournament[];
  isLoading: boolean;
}) => {
  return (
    <DataList
      dataSource={dataSource}
      renderItem={(item) => <>{item.name}</>}
      itemKey={(item) => item.id}
      isLoading={isLoading}
    />
  );
};

export default LeaguesListMobile;
