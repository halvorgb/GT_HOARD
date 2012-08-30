// I couldn't manage to add a touchListener inside the player class, so this one is for all the players...
void touchListener( cEntity @ent, cEntity @other, const Vec3 planeNormal, int surfFlags )
{

  // ok, fire the touch shiet!
  players[other.client.get_playerNum()].fireTouched(@ent, @other, planeNormal, surfFlags);
}
