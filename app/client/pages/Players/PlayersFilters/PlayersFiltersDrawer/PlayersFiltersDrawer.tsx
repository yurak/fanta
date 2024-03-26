import { useState } from "react";
import Drawer from "@/ui/Drawer";
import Button from "@/ui/Button";

const PlayersFiltersDrawer = () => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <>
      <Button onClick={() => setIsOpen(true)}>All filters</Button>
      <Drawer title="Filters" isOpen={isOpen} onClose={() => setIsOpen(false)}>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
        <div>content</div>
      </Drawer>
    </>
  );
};

export default PlayersFiltersDrawer;
