import { useState } from "react";
import Heading from "@/components/Heading";
import SeasonsSelect from "@/components/SeasonsSelect";
import PageLayout from "@/layouts/PageLayout";
import { ISeason } from "@/interfaces/Season";
import Search from "@/ui/Search";
import styles from "./Players.module.scss";

const Players = () => {
  const [search, setSearch] = useState("");
  const [selectedSeason, setSelectedSeason] = useState<ISeason | null>(null);

  return (
    <PageLayout>
      <div className={styles.header}>
        <div className={styles.heading}>
          <Heading title="Players" noSpace />
        </div>
        <div className={styles.yearSelect}>
          <SeasonsSelect value={selectedSeason} onChange={setSelectedSeason} />
        </div>
        <div className={styles.search}>
          <Search value={search} onChange={setSearch} placeholder="Search player" />
        </div>
      </div>
      <div>Players page</div>
    </PageLayout>
  );
};

export default Players;
