//=============================================================================
// sgVisor
// by SK
//=============================================================================

class sgVisor extends Inventory;

function GiveTo(Pawn other)
{
    Super.GiveTo(other);
    Pawn(Owner).ClientMessage("Use the ToggleVisor console command to toggle on and off.");
}

defaultproperties
{
ActivateSound=Sound'UnrealShare.Menu.side1b'
DeActivateSound=Sound'UnrealShare.Menu.side1b'
PickupSound=Sound'UnrealShare.Menu.side1b'
bActivatable=True
PickupMessage="You got the Thermal Visor."
ItemArticle=the
ItemName="Thermal Visor"
PickupViewMesh=LodMesh'UnrealShare.ShieldBeltMesh'
M_Activated= activated.
M_Deactivated= deactivated.
M_Selected= selected.
}