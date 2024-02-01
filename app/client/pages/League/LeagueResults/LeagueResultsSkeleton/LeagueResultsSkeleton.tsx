import Table from "../../../../ui/Table";

const LeagueResultsSkeleton = () => {
  return (
    <Table
      dataSource={[]}
      isLoading
      skeletonItems={8}
      columns={[
        {
          dataKey: "skeleton-column-1",
        },
        {
          dataKey: "skeleton-column-2",
        },
        {
          dataKey: "skeleton-column-3",
        },
        {
          dataKey: "skeleton-column-4",
        },
        {
          dataKey: "skeleton-column-5",
        },
      ]}
    />
  );
};

export default LeagueResultsSkeleton;
