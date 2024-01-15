import { RouterProvider, createBrowserRouter } from "react-router-dom";
import Leagues from "./pages/Leagues";
import { withBootstrap } from "./bootstrap/withBootstrap";
import LeagueResults from "./pages/League/LeagueResults";

const router = createBrowserRouter([
  {
    path: "/leagues",
    element: <Leagues />,
  },
  {
    path: "/leagues/:leagueId/results",
    element: <LeagueResults />,
  },
]);

export default withBootstrap(() => <RouterProvider router={router} />);
