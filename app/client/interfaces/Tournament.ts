export interface ITournament {
  code: string;
  created_at: string;
  eurocup: boolean;
  icon: string;
  id: number;
  lineup_first_goal: number;
  lineup_increment: number;
  name: string;
  short_name: string | null;
  sofa_number: string;
  source_calendar_url: string;
  source_id: number;
  updated_at: string;
}
