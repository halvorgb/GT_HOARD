class Hoard_Map
{
  String name;
  
  uint id;
  Hoard_Map_Highscore highScore;
  
  Hoard_Map()
  {
    this.reset();
  }
  
  ~Hoard_Map()
  {
  }

  uint getId()
  {
    return this.id;
  }
  
  void setId(uint id)
  {
    this.id = id;
  }

  void reset ()
  {
    Cvar mapName( "mapname", "", 0);
    this.id = 0;
    this.name = mapName.string;

    this.highScore.reset();
  }
  
  Hoard_Map_Highscore @getHighScore()
  {
    return @this.highScore;
  }

  bool allowEndGame()
  {
    // lol, might I recommend timelimit 0? :D
    return true;
  }
  
  void setUpMatch()
  {
    int i, j;
    cEntity @ent;
    cTeam @team;

    for ( i = TEAM_PLAYERS; i < GS_MAX_TEAMS; i++)
      {
	@team = @G_GetTeam(i);
	team.stats.clear();
      }

    G_RemoveDeadBodies();


  }
}
