import Popover from "@/ui/Popover";

const PlayerFilters = () => {
  return (
    <>
      All Filters
      <br />
      <Popover
        title="Position"
        renderedReference={({ isOpen, setRef, ...rest }) => (
          <button ref={setRef} disabled={isOpen} {...rest}>
            Reference
          </button>
        )}
      >
        Positions
      </Popover>
    </>
  );
};

export default PlayerFilters;
