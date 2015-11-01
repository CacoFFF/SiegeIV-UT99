// Shieldbelt subclass, for Siege.
// Made by Higor

class sg_XC_ShieldBelt2 extends UT_ShieldBelt;

var float aTimer;

function bool HandlePickupQuery( inventory Item )
{
	local Inventory I;

	if (item.class == class) //Increase charge by 50
	{
			Charge = 150;

			if (Level.Game.LocalLog != None)
				Level.Game.LocalLog.LogPickup(Item, Pawn(Owner));
			if (Level.Game.WorldLog != None)
				Level.Game.WorldLog.LogPickup(Item, Pawn(Owner));

			if ( Item.PickupMessageClass == None )
				Pawn(Owner).ClientMessage(item.PickupMessage, 'Pickup');
			else
				Pawn(Owner).ReceiveLocalizedMessage( item.PickupMessageClass, 0, None, None, item.Class );

			Item.PlaySound (item.PickupSound,,2.0);
			Item.SetReSpawn();
			return true;
	}
	else if (item.class == class'UT_ShieldBelt') //Absorb other shield belts into self
	{
		Charge = 150;

		if (Level.Game.LocalLog != None)
			Level.Game.LocalLog.LogPickup(Item, Pawn(Owner));
		if (Level.Game.WorldLog != None)
			Level.Game.WorldLog.LogPickup(Item, Pawn(Owner));
		if ( Item.PickupMessageClass == None )
			Pawn(Owner).ClientMessage(item.PickupMessage, 'Pickup');
		else
			Pawn(Owner).ReceiveLocalizedMessage( item.PickupMessageClass, 0, None, None, item.Class );
		Item.PlaySound (item.PickupSound,,2.0);
		Item.SetReSpawn();
		return true;
	}
	else if ( item.Class == class'WildcardsMetalSuit' || item.Class == class'WildcardsRubberSuit' )
	{
		if ( Inventory.HandlePickupQuery(Item) )
			return true;
		Destroy();
		return false;
	}

	if ( Inventory == None )
		return false;

	return Inventory.HandlePickupQuery(Item);
}

function PickupFunction(Pawn Other)
{
	local Inventory I;

	if ( Owner == none )
		SetOwner( Other);

	MyEffect = Spawn(class'UT_ShieldBeltEffect', Other,,Other.Location, Other.Rotation); 
	MyEffect.Mesh = Owner.Mesh;
	MyEffect.DrawScale = Owner.Drawscale;

	if ( Level.Game.bTeamGame && (Other.PlayerReplicationInfo != None) )
		TeamNum = Other.PlayerReplicationInfo.Team;
	else
		TeamNum = 3;
	SetEffectTexture();


	for ( I=Other.Inventory; I!=None; I=I.Inventory )
	{
		if ( I.class == class'UT_ShieldBelt' )
		{
			Charge = 150;
			I.Destroy();
		}
		else if ( ClassIsChildOf(I.Class, class'UT_Invisibility') )
			MyEffect.bHidden = true;
		else if ( I.Class == class'WildcardsMetalSuit' || I.Class == class'WildcardsRubberSuit' )
			I.Destroy();

	}
	SetTimer(0.5, true);
}

event Tick( float DeltaTime)
{
	local Inventory I;
	local bool bOldHidden;

	if ( Owner == none)
		return;

	aTimer += DeltaTime;
	if ( aTimer > 0.5 )
	{
		aTimer -= 0.5;
		MyEffect.DrawType = DT_Mesh;
//		MyEffect.bHidden = false;
		for ( I=Owner.Inventory; I!=None; I=I.Inventory )
			if ( ClassIsChildOf(I.Class, class'UT_Invisibility') )
			{
				MyEffect.DrawType = DT_None;
//				MyEffect.bHidden = true;
				break;
			}

	}
}