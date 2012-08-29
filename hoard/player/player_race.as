class Hoard_Player_Race
{
  uint startTime;
  uint stopTime;
  uint64 startDistance;
  uint64 stopDistance;
  uint64 timeStamp;
  int delta;

  Hoard_Player @player;
  
  Hoard_Player_Race()
  {
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

}
