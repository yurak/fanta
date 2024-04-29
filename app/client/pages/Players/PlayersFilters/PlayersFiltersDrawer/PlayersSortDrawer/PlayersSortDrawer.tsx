import Drawer from "@/ui/Drawer";
import Button from "@/ui/Button";

const PlayersSortDrawer = ({ isOpen, close }: { isOpen: boolean, close: () => void }) => {
  return (
    <Drawer
      title="Sort by"
      isOpen={isOpen}
      onClose={close}
      footer={
        <Button block onClick={close}>
          Apply
        </Button>
      }
      placement="bottom"
    >
      Test
    </Drawer>
  );
};

export default PlayersSortDrawer;
