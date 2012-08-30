int itemCount;
// this holds every item all the time.
array<cEntity@> itemStorage;


array<cEntity@> getItemsCopy()
{
  // initialize array to be returned
  array<cEntity@> newArr(itemCount);
  
  // we now know the itemCount!
  for (int i = 0; i < itemCount; i++)
    {
      @newArr[i] = @copyItem(@itemStorage[i]);
    }
  return newArr;
}

// this is ran one time, it is the mold for creating copies.
void createItemsList()
{ 
  // initialize array
  itemCount = 0;
  itemStorage = array<cEntity@>(numEntities);

  // replace all items on the map with new replacementItems, it works.
  for ( int i = 0; i <= numEntities; i++ )
    {
      cEntity @ent = @G_GetEntity(i);
      if (@ent == null)
	continue;
      if(ent.type == ET_ITEM)
	{
	  cItem @Item = @ent.item;
	  if( @Item != null && ent.classname == Item.classname )
	    {
	      if( ( ent.solid != SOLID_NOT ) || ( ( @ent.findTargetingEntity( null ) != null ) && ( ent.findTargetingEntity( null ).classname != "target_give" ) ) ) //ok, not connected to target_give
		{
		  // this one does some funky stuff!
		  ent.classname = "AS_" + Item.classname;
		  @itemStorage[itemCount] = @copyItem( @ent);
		  itemCount++;
		  
		  // free the old item!
		  ent.solid = SOLID_NOT;
		  // Item.classname? does this matter?
		  ent.classname = "ASmodel_" + ent.item.classname;
		  ent.freeEntity();
		}
	    }
	}
    }

  
}

// just a straight copy, this is called by both createItemsList() and getItemsCopy()
cEntity @copyItem( cEntity @oldItem)
{
  Vec3 min, max;
 cEntity @ent = @G_SpawnEntity( oldItem.classname );
      
      
 cItem @item = @G_GetItem( oldItem.item.tag );
 @ent.item = @item;

 ent.origin = oldItem.origin;
 oldItem.getSize( min, max );
 ent.setSize( min, max );
 ent.type = ET_ITEM;
 ent.solid = SOLID_TRIGGER;
 ent.moveType = MOVETYPE_NONE;
 ent.count = oldItem.count;
 ent.spawnFlags = oldItem.spawnFlags;
      
 /* no owner for this set!
 @ent.owner = @owner;
 ent.ownerNum = owner.get_entNum();
 */   
 ent.svflags = SVF_NOCLIENT;// | SVF_BROADCAST;

     
 ent.style = oldItem.style;
 ent.target = oldItem.target;
 ent.targetname = oldItem.targetname;
 ent.setupModel( oldItem.item.model, oldItem.item.model2 );
  
  
 /*
 ent.wait = oldItem.wait;
 if( ent.wait > 0 )
   {
     ent.nextThink = levelTime + ent.wait;
   }
 */
      
 ent.skinNum = oldItem.skinNum;

 /* TOUCH is assigned upon import to Hoard_Player
 @ent.think = replacementItem_think;
 @ent.touch = replacementItem_touch;
 @ent.use = replacementItem_use;
 */
      
 ent.linkEntity();
 return @ent;
}  


