import { useState } from "react";
import Drawer from "@/ui/Drawer";
import FilterIcon from "@/assets/icons/filter.svg";
import Link from "@/ui/Link";

const PlayersFiltersDrawer = () => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <>
      <Link asButton icon={<FilterIcon />} onClick={() => setIsOpen(true)}>
        All filters
      </Link>
      <Drawer title="Filters" isOpen={isOpen} onClose={() => setIsOpen(false)}>
        <Drawer.Section title="Position">Position</Drawer.Section>
        <Drawer.Section title="Total score">Total score</Drawer.Section>
        <Drawer.Section title="Base score">Base score</Drawer.Section>
        <Drawer.Section title="Appearances">Appearances</Drawer.Section>
        <Drawer.Section title="Price">Price</Drawer.Section>
      </Drawer>
    </>
  );
};

export default PlayersFiltersDrawer;
