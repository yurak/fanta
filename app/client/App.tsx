import { RouterProvider, createBrowserRouter } from "react-router-dom";
import Leagues from "./pages/Leagues";
import { withBootstrap } from "./bootstrap/withBootstrap";
import Results from "./pages/League/Results";
import Players from "./pages/Players";
import Player from "./pages/Player";
import LeaguePlayers from "./pages/League/LeaguePlayers";
import RoundPlayers from "./pages/RoundPlayers";
import Leaderboard from "./pages/Leaderboard";
import AuctionSales from "./pages/AuctionSales";
import AuctionPurchases from "./pages/AuctionPurchases";
import AuctionDrops from "./pages/AuctionDrops";

const router = createBrowserRouter([
  {
    path: "/leaderboard",
    element: <Leaderboard />,
  },
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
  {
    path: "/leagues/:leagueId/auctions/:auctionId/sales",
    element: <AuctionSales />,
  },
  {
    path: "/leagues/:leagueId/auctions/:auctionId/purchases",
    element: <AuctionPurchases />,
  },
  {
    path: "/leagues/:leagueId/auctions/:auctionId/drops",
    element: <AuctionDrops />,
  },
]);

export default withBootstrap(() => <RouterProvider router={router} />);
