class FV_GUI_Panel expands FV_GUI_Master;

var FV_GUI_Panel SubElements[32]; //Visible elements
var int iElements;
//iFront is the index of the front panel, we use this to determine if there's a panel we should prioritize

var FV_GUI_Button Buttons[32];
var int iButtons;
var FV_GUI_Panel ChildPanel; //This is ahead, prioritize input

var bool bBoundaryPointer;		//Keep pointer within panel boundary (only for master panel)
var bool bRightClicked;			//Was clicked last frame? (master panel)
var bool bLeftClicked;			//Was clicked last frame? (master panel)
var bool bTrackFrame;			//Auto-notify self and children if frame changes during Render

var float TOrgX, TOrgY;			//Tracked Origin point
var float OrgX, OrgY;			//Origin point
var float TrackedX, TrackedY;	//Tracked Frame Size
var float CurX, CurY;			//Current Frame Size


//CurX, CurY, OrgX, OrgY must all be set by context object, before this is called
function MasterRender( Canvas C)
{
	if ( bTrackFrame )
		FrameCheck();
	PostRender( C);
}


function FrameCheck()
{
	if ( TrackedX != CurX || TrackedY != CurY || TOrgX != OrgX || TOrgY != OrgY )
		FrameResized( OrgX, OrgY, CurX, CurY);

	TrackedX = CurX;
	TrackedY = CurY;
	TOrgX = OrgX;
	TOrgY = OrgY;
}

function PropagatePostRender( Canvas C)
{
	local int i;
	LOOP_A:
	if ( !SubElements[i].bNoRender )
		SubElements[i].PostRender( C);
	if ( ++i < iElements )
		Goto LOOP_A;
}

//If the panel is rendering all buttons in a custom way, then do not call this
function DefaultRenderButtons( Canvas C)
{
	local int i;
	LOOP_B:
	if ( !Buttons[i].bNoRender )
		Buttons[i].PostRender( C);
	if ( ++i < iButtons )
		Goto LOOP_B;
}

function PropagateTick( float DeltaTime)
{
	local int i;
	LOOP_C:
	if ( !SubElements[i].bNoTick )
		SubElements[i].Tick( DeltaTime);
	if ( ++i < iElements )
		Goto LOOP_C;
}

//Redundant here, important in subclasses -> call Super.FrameResized in non-master subs
function FrameResized( float oX, float oY, float cX, float cY)
{
	OrgX = oX;
	OrgY = oY;
	CurX = cX;
	CurY = cY;
}

function RegisterElement( FV_GUI_Panel NewElement)
{
	NewElement.InheritFrom( self);
	SubElements[iElements++] = NewElement;
}

function RegisterButton( FV_GUI_Button NewButton)
{
	NewButton.InheritFrom( self);
	Buttons[iButtons++] = NewButton;
}

function SetCanvasFrame( Canvas C)
{
	C.SetOrigin( OrgX, OrgY);
	C.SetClip( CurX, CurY);
}

//Pop and Push the canvas
function AddCanvasFrame( Canvas C)
{
	C.SetOrigin( C.OrgX + OrgX, C.OrgY + OrgY);
	C.SetClip( CurX, CurY);
}

function RemCanvasFrame( Canvas C)
{
	C.SetOrigin( C.OrgX - OrgX, C.OrgY - OrgY);
	C.SetClip( Parent.CurX, Parent.CurY);
}