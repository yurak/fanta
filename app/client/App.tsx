import { RouterProvider, createBrowserRouter } from "react-router-dom";
import Leagues from "./pages/Leagues";
import { withBootstrap } from "./bootstrap/withBootstrap";
import Results from "./pages/League/Results";
import Players from "./pages/Players";
import Player from "./pages/Player";
import LeaguePlayers from "./pages/League/LeaguePlayers";
import RoundPlayers from "./pages/RoundPlayers";

const router = createBrowserRouter([
  {
    path: "/leagues",
    element: <Leagues />,
  },
  {
    path: "/leagues/:leagueId/results",
    element: <Results />,
  },
  {
    path: "/players",
    element: <Players />,
  },
  {
    path: "/players/:playerId",
    element: <Player />,
  },
  {
    path: "/leagues/:leagueId/players",
    element: <LeaguePlayers />,
  },
  {
    path: "/tournament_rounds/:roundId/round_players",
    element: <RoundPlayers />,
  },
]);

export default withBootstrap(() => <RouterProvider router={router} />);
