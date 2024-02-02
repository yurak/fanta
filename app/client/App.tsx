import { RouterProvider, createBrowserRouter } from "react-router-dom";
import Leagues from "./pages/Leagues";
import { withBootstrap } from "./bootstrap/withBootstrap";
import Results from "./pages/League/Results";

const router = createBrowserRouter([
  {
    path: "/leagues",
    element: <Leagues />,
  },
  {
    path: "/leagues/:leagueId/results",
    element: <Results />,
  },
]);

export default withBootstrap(() => <RouterProvider router={router} />);
