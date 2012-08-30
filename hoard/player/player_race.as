class Hoard_Player_Race
{
  uint startTime;
  uint stopTime;
  uint64 startDistance;
  uint64 stopDistance;
  uint64 timeStamp;
  int delta;
  uint halfwayTime;

  Hoard_Player @player;
  
  Hoard_Player_Race()
  {
    this.halfwayTime = 0;
    this.delta = 0;
    this.stopTime = 0;
    this.startTime = 0;
  }
  ~Hoard_Player_Race() {}
  
  void setPlayer( Hoard_Player @player )
  {
    @this.player = @player;
  }
  
  Hoard_Player @getPlayer()
  {
    return @this.player;
  }


  bool inRace()
  {
    if (this.startTime != 0 && this.stopTime == 0)
      return true;
    return false;
  }
  
  bool isFinished()
  {
    return (this.stopTime != 0);
  }
  
  uint getTime()
  {
       
    return (this.stopTime - this.startTime);
  }

  uint getCurrentDistance()
  {
    if (this.startDistance > 0)
      return (this.player.distance - this.startDistance)/1000;
    return 0;
  }
  
  uint getStartTime()
  {
    return this.startTime;
  }
  
  uint getCurrentTime()
  {
    return levelTime - this.startTime;
  }
  void start()
  {
    this.stopTime = 0;
    this.startTime = levelTime;
    this.startDistance = this.player.distance;
  }
  
  bool stop()
  {
    if ( !player.isRacing() )
      return false;
    
    this.stopTime = levelTime;
    this.stopDistance = this.player.distance;
    this.timeStamp = localTime;
    return true;
  }
  String toString()
  {
    String raceString;
    raceString += "\"" + this.getTime() + "\" \"" + this.player.getName() + "\" \"" + localTime + "\" ";
    raceString += "\n";
    
    return raceString;
  }

  uint64 getTimeStamp()
  {
    return this.timeStamp;
  }

  int getHalfwayTime()
  {
    return this.halfwayTime;
  }
  
  void setHalfwayTime()
  {
    //this.halfway = levelTime - this.startTime;
    
    uint newTime = levelTime - this.startTime;
    uint serverBestTime = map.getHighScore().getHalfwayTime();
    uint personalBestTime = this.player.getBestHalfwayTime();
    bool noDelta = 0 == serverBestTime;

    
    //this.halfwayTime = (noDelta ? 0 : newTime - serverBestTime);
    this.halfwayTime = newTime;
    G_CenterPrintMsg( this.player.getClient().getEnt(), "Halfway Time: " + TimeToString(newTime) + (noDelta ? "" : ("\n" + diffString(serverBestTime, newTime) )) );

    //print this time for spectators as well!
    cTeam @spectators = @G_GetTeam(TEAM_SPECTATOR );
    cEntity @other;
    for ( int i = 0; @spectators.ent(i) != null; i++)
      {
	@other= @spectators.ent(i);
	if ( @other.client != null && other.client.chaseActive )
	  {
	    if (other.client.chaseTarget == this.player.getClient().get_playerNum() + 1)
	      {
		G_CenterPrintMsg( other.client.getEnt(), "Halfway Time : " + TimeToString(newTime) + (noDelta ? "" : ("\n" + diffString(serverBestTime, newTime) )) );
	      }
	  }
      }
    
    
    // award sending, does not set new recordtimes as halfwaytimes are set if the race time is a record.
    if ( newTime < serverBestTime || serverBestTime == 0)
      this.player.sendAward( S_COLOR_GREEN + "Halfway Record!" );
    if (newTime < personalBestTime || personalBestTime == 0)
      this.player.sendAward( S_COLOR_YELLOW + "Personal Halfway record!");

    
    // console output nah   
    
  }
}
  
