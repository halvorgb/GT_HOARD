class Hoard_Map_Highscore
{
  uint finishTime;
  uint64 timeStamp;
  String playerName;
  Hoard_Map_Highscore()
  {
  }
  ~Hoard_Map_Highscore()
  {
  }
  
  Hoard_Map_Highscore@ opAssign(const Hoard_Map_Highscore &highScore)
  {
    this.finishTime = highScore.finishTime;
    this.playerName = highScore.playerName;
    return this;
  }

  String getPlayerName()
  {
    return this.playerName;
  }

  int getTime()
  {
    return this.finishTime;
  }
  
  uint64 getTimeStamp()
  {
    return this.timeStamp;
  }

  void reset()
  {
    this.finishTime = 0;
    this.playerName = "";
  }
  
  // set highscore from a race
  void fromRace( Hoard_Player_Race &race )
  {
    this.finishTime = race.getTime();
    this.playerName = race.getPlayer().getClient().name;
    this.timeStamp = race.getTimeStamp();
  }

}
