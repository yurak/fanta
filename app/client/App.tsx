import { RouterProvider, createBrowserRouter } from "react-router-dom";
import Leagues from "./pages/Leagues";
import { withBootstrap } from "./bootstrap/withBootstrap";
import Results from "./pages/League/Results";
import Players from "./pages/Players";

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
    path: "/leagues/:leagueId/players",
    element: <Players />,
  },
]);

export default withBootstrap(() => <RouterProvider router={router} />);
