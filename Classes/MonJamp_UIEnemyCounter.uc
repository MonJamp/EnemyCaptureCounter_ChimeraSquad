//---------------------------------------------------------------------------------------
//  FILE:   MonJamp_UIEnemyCounter.uc
//           
//	The X2DownloadableContentInfo class provides basic hooks into XCOM gameplay events. 
//  Ex. behavior when the player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------

class MonJamp_UIEnemyCounter extends UIScreenListener;

var UIText CapturedText;
var UIText UnconsciousText;
var UIText KilledText;
var int NumCaptured;
var int NumUnconscious;
var int NumKilled;

// This event is triggered after a screen is initialized. This is called after
// the visuals (if any) are loaded in Flash.
event OnInit(UIScreen Screen)
{
    local UITacticalHUD TacticalScreen;
    local float PosX;
    local float PosY;

    RegisterForEvents();
    UpdateCounters();
    
    // Setup UI
    PosX = 400;
    PosY = 10;

    TacticalScreen = UITacticalHUD(Screen);

    CapturedText = Screen.Spawn(class'UIText', TacticalScreen);
    CapturedText.InitText();
    CapturedText.SetText("Captured: 0");
    // TODO: Is there a way to anchor off other UI elements?
    CapturedText.AnchorTopCenter();
    CapturedText.SetPosition(PosX, PosY);
    CapturedText.SetColor("0x00C853");

    UnconsciousText = Screen.Spawn(class'UIText', TacticalScreen);
    UnconsciousText.InitText();
    UnconsciousText.SetText("Unconscious: 0");
    UnconsciousText.AnchorTopCenter();
    UnconsciousText.SetPosition(PosX, PosY + CapturedText.Height);
    UnconsciousText.SetColor("0xFFC300");
    
    KilledText = Screen.Spawn(class'UIText', TacticalScreen);
    KilledText.InitText();
    KilledText.SetText("Killed: 0");
    KilledText.AnchorTopCenter();
    KilledText.SetPosition(PosX, UnconsciousText.Y + UnconsciousText.Height);
    KilledText.SetColor("0xC70039");

    RefreshDisplayText();
}
// This event is triggered after a screen receives focus.
// This happens when another screen is on top of this screen, and that top screen
// is removed, the focus will call back down to this screen and trigger OnReceiveFocus.
event OnReceiveFocus(UIScreen Screen)
{
    ShowCounters();
    RefreshDisplayText();
}
// This event is triggered after a screen loses focus.
// This happens when another screen is added to the stack on top of this screen,
// which triggers the current screen to lose focus and receive the OnLoseFocus event.
event OnLoseFocus(UIScreen Screen)
{
    HideCounters();
}
// This event is triggered when a screen is removed.
event OnRemoved(UIScreen Screen)
{
    HideCounters();
}

function RegisterForEvents()
{
    local Object SelfObject;

    // Call UpdateCounter every time a unit is unconscious, dies, or is captured
    SelfObject = self;
    `XEVENTMGR.RegisterForEvent(SelfObject, 'UnitUnconscious',	UpdateUI, ELD_OnVisualizationBlockCompleted);
    `XEVENTMGR.RegisterForEvent(SelfObject, 'UnitDied',	UpdateUI, ELD_OnVisualizationBlockCompleted);
    `XEVENTMGR.RegisterForEvent(SelfObject, 'UnitCaptured',	UpdateUI, ELD_OnVisualizationBlockCompleted);
    
    `XEVENTMGR.RegisterForEvent(SelfObject, 'BreachPhaseBegin', BeginBreachMode, ELD_OnVisualizationBlockCompleted);
    `XEVENTMGR.RegisterForEvent(SelfObject, 'BreachConfirmed', EndBreachMode, ELD_OnVisualizationBlockCompleted);
}

function EventListenerReturn UpdateUI(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    UpdateCounters();
    RefreshDisplayText();

    return ELR_NoInterrupt;
}

function EventListenerReturn BeginBreachMode(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    // Update counters before hiding
    UpdateCounters();
    RefreshDisplayText();
    HideCounters();

    return ELR_NoInterrupt;
}

function EventListenerReturn EndBreachMode(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    UpdateCounters();
    RefreshDisplayText();
    ShowCounters();

    return ELR_NoInterrupt;
}

function UpdateCounters()
{
    local XComGameStateHistory History;
    local XComGameState_BattleData BattleData;
    local XComGameState_Unit Unit;

    History = `XCOMHISTORY;
    BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

    NumCaptured = BattleData.CapturedUnconsciousUnits.Length;

    NumKilled = 0;
    NumUnconscious = 0;

    foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
    {
        if(Unit.ControllingPlayerIsAI())
        {
            if(Unit.IsUnconscious())
            {
                NumUnconscious++;
            }
            else if(!Unit.IsAlive())
            {
                NumKilled++;
            }
        }
    }
}

function HideCounters()
{
    CapturedText.Hide();
    UnconsciousText.Hide();
    KilledText.Hide();
}

function ShowCounters()
{
    CapturedText.Show();
    UnconsciousText.Show();
    KilledText.Show();
}

function RefreshDisplayText()
{
    local string str;

    str = "Captured: ";
    str $= string(NumCaptured); // String concatenation in unreal engine
    CapturedText.SetText(str);

    str = "Unconscious: ";
    str $= string(NumUnconscious);
    UnconsciousText.SetText(str);

    str = "Killed: ";
    str $= string(NumKilled);
    KilledText.SetText(str);
}

defaultproperties
{
    // specify the class you want to notify your new object.
    ScreenClass = class'UITacticalHUD';
    // Leaving ScreenClass assigned to none will cause *every* screen to trigger
    // its event signals on this listener.
}