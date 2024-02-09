import Label from "@/ui/Label";

const LeagueStatus = ({ status }: { status: string }) => {
  if (status === "active") {
    return (
      <Label type="alert" icon="🚀">
        Ongoing
      </Label>
    );
  }

  if (status === "archived") {
    return <Label icon="🏁️">Finished</Label>;
  }

  return <Label>{status}</Label>;
};

export default LeagueStatus;
