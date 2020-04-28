//---------------------------------------------------------------------------------------
//  AUTHOR:		MonJamp
//  FILE:		UIEnemyCounter_Listener.uc
//           
//	Listens for UITacticalHUD then loads UIEnemyCounter_Panel
//  
//---------------------------------------------------------------------------------------

class UIEnemyCounter_Listener extends UIScreenListener;

event OnInit(UIScreen Screen)
{
    GetUI();
}

// Separating the UIPanel child from the UIScreenListener child fixes the issue
// where loading saves would cause hang
function UIPanel GetUI()
{
    local UIScreen hud;
    local UIEnemyCounter_Panel ui;
    
    hud = `PRES.GetTacticalHUD();
	if (hud == none)
	{
		return none;
	}

	ui = UIEnemyCounter_Panel(hud.GetChild('UIEnemyCounter_Panel'));
	if(ui == none)
	{
		ui = hud.Spawn(class'UIEnemyCounter_Panel', hud);
		ui.InitPanel('UIEnemyCounter_Panel');
	}

    return ui;
}

event OnRemoved(UIScreen Screen)
{
    GetUI().Remove();
}

defaultproperties
{
    ScreenClass = class'UITacticalHUD';
}