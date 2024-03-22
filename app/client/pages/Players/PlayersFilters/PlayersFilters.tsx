import { useState } from "react";
import PopoverInput from "@/ui/PopoverInput";

const PlayerFilters = () => {
  const [position, setPosition] = useState<string[]>([]);
  const [appearences, setAppearences] = useState<string | null>("5 to 10");
  const [totalScore, setTotalScore] = useState<string | null>("2 - 9");

  return (
    <>
      All Filters
      <br />
      <PopoverInput
        label="Position"
        value={position}
        clearValue={() => setPosition([])}
        formatValue={(value) => (value.length > 0 ? value.toString() : null)}
      />
      <PopoverInput
        label="Appeareances"
        value={appearences}
        clearValue={() => setAppearences(null)}
        formatValue={(value) => (value ? `From ${value}` : null)}
      />
      <PopoverInput
        label="Total score"
        value={totalScore}
        clearValue={() => setTotalScore(null)}
        formatValue={(value) => (value ? `TS: ${value}` : null)}
      />
      <PopoverInput
        label="Total score"
        value={totalScore}
        clearValue={() => setTotalScore(null)}
        formatValue={(value) => (value ? `TS: ${value}` : null)}
      />
      <PopoverInput
        label="Total score"
        value={totalScore}
        clearValue={() => setTotalScore(null)}
        formatValue={(value) => (value ? `TS: ${value}` : null)}
      />
      <PopoverInput
        label="Total score"
        value={totalScore}
        clearValue={() => setTotalScore(null)}
        formatValue={(value) => (value ? `TS: ${value}` : null)}
      />
      <PopoverInput
        label="Total score"
        value={totalScore}
        clearValue={() => setTotalScore(null)}
        formatValue={(value) => (value ? `TS: ${value}` : null)}
      />
    </>
  );
};

export default PlayerFilters;
