import Skeleton from "react-loading-skeleton";
import { useTeam } from "../../../../../api/query/useTeam";
import { ITeam } from "../../../../../interfaces/Team";

const TeamLoader = ({
  teamId,
  children,
  skeleton = <Skeleton />,
}: {
  teamId: number;
  children: (item: ITeam) => React.ReactNode;
  skeleton?: React.ReactNode;
}) => {
  const { data, isLoading } = useTeam(teamId);

  return <div>{isLoading || !data ? skeleton : children(data)}</div>;
};

export default TeamLoader;
