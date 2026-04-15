import Label from "@/ui/Label";

const LeagueStatus = ({ status, demo }: { status: string, demo?: boolean }) => {
  if (status === "active") {
    if (demo) {
      return (
        <Label type="demo" icon="🧪">
          Demo
        </Label>
      );
    }
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
