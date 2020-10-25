/* LFS_Par    Simple parameter editor  - float and int  supported
      
   Ron Grant
   Oct 15,2020  
   
   See UserParEdit tab for example user code.
   Hopefully you will not need to dig into this code.
   
    
     * sets initial value of vars on first invocation 
     * defines min max range and delta  (saturate at min and max)
     * mouse wheel OR vert arrows OR left mouse button down on parameter and drag horz.
       all increment in defined delta increment (int variables used fixed delta of 1)
    
           
   User code presents list to parameter editor every frame (e.g. 60 fps)      
   
           
           
   ParEditor p = parEditor;     // p is shorthand reference to parameter editor within this method  
   p.beginList();               // beginList MUST be called before parameters (series of ParF / ParI calls).   
    
      // user adjustable parameters 
      // var = p.parF(var,"varName","VarDescription",default,min,max,delta)
      
 
    Kp = p.parF(Kp,"Kp","PD controller Proportional constant",10.0,0.0,100.0,0.1);
    Kd = p.parF(Kd,"Kd","PD controller Derivative constant",10.0,0.0,100.0,0.1);    
    maxSpeed = p.parF(maxSpeed,"maxSpeed","inches/sec ",2.0,0.0,24.0,1.0);
    
   p.endList();   
        
           
   P)arameter display command is used in LFS to toggle editor visibility.
   
   When visible dialog box is drawn displaying a given number of parameter variables, e.g. 5 in LFS
   
   Use PageUp/PageDn to scroll through list if more items than can be displayed at one time.
  
   Hover over item and it is selected (lights up). 
   Selected item can be adjusted by rolling mouse wheel, using +/- keys OR by pressing 
   and holding left mouse button then moving left or right. Note: the value won't jump to the location of the 
   mouse click on the item, reducing accidental changes in value.
   
   Note: As of, Oct 20, 2020. The motion of bar graph is not locked to mouse motion. Full scale adjustment
   of value from its minimum to maximum requires same mouse motion as would be used to move across
   the entire screen.
  
   A default value is specified which is assigned to the variable on the first invocation 
   of parEditorUpdate().
       
    1. define instance of parEditor (might be handled by LFS)
    1. parEditorUpdate() call must be added to userDrawPanel method.
    2. parEditor.processKey(key); // call added to UserKey keypressed method  decodes  E, +, - keys
    3. parEditorUpdate() included as below with parameter list 
  
  Oct 22,2020   Problem Reported by Chris N, parameters can be changed when editor not visible.
                This should be cured in this version.
                   * If item does not have focus can't be changed.
                   * If Param editor not visible mouse wheel delta count events not logged.
                   
                Also fixed problem with ParI bad format float vs int (causing error if ParI used)
  
   
*/

ParEditor parEditor = new ParEditor(); // single instance of ParEditor 

// Keep this event in user application 

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  
  parEditor.notifyMouseWheelDelta(e); // editor will apply to selected item then zero
                                     
}


class ParEditor {
 
                               // mouse state variables 
  boolean mouseDownL;          // true when left button presed 
  boolean mouseJustPressedL;   // flag set when left mouse button pressed 
  int   mouseXOnPressL;        // recorded mouseX on left press
  float mouseInitialValueL;    // current variable value on left press 
  
  int parIndex;       // increments for each parF call
  int parCurIndex;    // current parameter 0..n-1   set to -1 at init 
                      // informing ParF and ParI to load defaults for all 
  
  int parCount;       // total number of parameters
  char curKey;        // current keypress  used to inform parEditor of pending + or - keys
                      // to be applied to current parameter 

  boolean visible = false;  // dialog box visible or not
 
  VP parVP;                 // dialog box location and size  defined in constructor
  VP txtVP;                 // text box (Y location function of current parameter offset on page)
  
  int txtVPLineH = 35;      // Y spacing (pixels) for each parameter displayed within page of parameters
  int parTextSize = 20;      // text size 
  int parPageSize = 5;       // 5 items at a time 
  int parPageTopIndex = 0;   // index of top item   PgUp PgDn 
 
  float deltaMult = 1.0;      // multiple of delta applied with mouse wheel or +/-
                              // future could manipulate, e.g. set to 10.0 for course adjust
                              // Not really needed with mouse drag facility 
  
  boolean mouseInCloseBox;    // kind of a hack, set when box drawn allowing [x] close 
  boolean requestDefault;     // D pressed - current var will be set to default 
  boolean requestSave;        // S pressed - append to param.txt in /data folder
  boolean saveActive;         // set at beginning of list and cleared at end  
  float mouseWheelDelta;      // set on mouse wheel event, cleared when consumed (delta applied to var)
                              // OR not.
   
  PrintWriter paramFile;      // output parameter file
  String[] paramLines;        // loaded parameter file lines 
  
  String statusMsg; 
  int statusMsgStartTime;       // set to millis() when active 0, when not
  boolean requestLoad;
  boolean loadActive;
  
  int notAvailNoticeTime;    
  
  void statusMessage(String s)
  {
     statusMsg = s;
     statusMsgStartTime = millis(); 
  }
 
  void notifyMouseWheelDelta(float delta)   // mouseWheel Event should call this method 
  {
     // if (parCurIndex > -1)  Oct 22,2020 remove !!!
    if (visible)              // added Oct 22 !!!
    mouseWheelDelta = delta;  // must have current selected variable to apply delta to
  }
 
  boolean mouseInView()  // true, if parameter box is visible and mouse in it 
  {
   return  (visible &&
           (mouseX>parVP.x)&&(mouseX<parVP.x+parVP.w)&&
           (mouseY>parVP.y)&&(mouseY<parVP.y+parVP.h)); 
  }
 
  void show() {visible = true;}   // make parameter editor visible
  void hide() {visible = false;}  // hide the bugger 
 
 
  ParEditor()   // constructor  
  {
    parCurIndex = -1;   // first pass through param list will set var defaults
    
    parVP = new VP(40,650,700,240);       // define location x,y and width,height of parameter dialog box
    txtVP = new VP(60,parVP.y+4,660,26); // define topmost parameter box, others offset in Y direction
  
  }
  
  
  void beginList () {
 
    pushStyle();
    pushMatrix();
    resetMatrix();
    camera();
   
    if (requestSave) 
    {  saveActive = true;  //  make sure synchronized with start of list
       paramFile = createWriter(dataPath("param.cdf"));
       statusMessage("Saving Parameters to sketch sub folder  data/param.cdf");
       requestSave = false;
    }
    
    if (requestLoad)
    { loadActive = true;
      requestLoad = false;
    }
      
    if (parCurIndex == -1)
    {
     // parVPY = panelPosY;  // se UserDrawPanel, made panelPosY public 
    }
    
    parIndex = 0;
    
    if (visible) 
    {
   
      rectMode (CORNER);
      stroke (100,100,200);
      fill (0,0,20);
      rect (parVP.x,parVP.y,parVP.w,parVP.h);
      
      if (notAvailNoticeTime != 0)
      {
        if (millis() - notAvailNoticeTime > 2500)
        {
          notAvailNoticeTime = 0;
          visible = false;
        }
        push();  // style and matrix 
        fill (240);
        translate (parVP.x+20,parVP.y+30);
        text ("Parameter dialog not available during",0,20);
        text ("contest Run, use G)o command instead",0,45);
        pop();
        
        return; 
      }
      
      
      rect (parVP.x+parVP.w-30,parVP.y+8,22,22);    // close box
      mouseInCloseBox = (mouseX>parVP.x+parVP.w-30) && (mouseX<parVP.x+parVP.w-30+22) &&
                        (mouseY>parVP.y+8)          && (mouseY<parVP.y+8+22);
      fill (240);
      text ("x",parVP.x+parVP.w-29,parVP.y+28);
    
      
      fill (240);
      textAlign(CENTER);
      textSize(parTextSize-2);
   
       
      
      text ("Parameters - left mouse button drag , mouse wheel or +/- to change ",
        parVP.x+parVP.w/2,parVP.y+parTextSize+4);
       
    
      
      String stat = "ctrl-D)efault value   ctrl-A)ll default     ctrl-S)ave  ctrl-L)oad    PgUp/PgDn";    
      if ((statusMsgStartTime != 0) && (millis()-statusMsgStartTime < 3000))
        stat = statusMsg; 
      text (stat,parVP.x+parVP.w/2,parVP.y+parVP.h-3);
      
      textAlign(LEFT);
      textSize(parTextSize);
    }  

    handleMouse();
 
  }
    
  void endList() {   // call at end defined list of params  -- allows for completion of Init
    parCount = parIndex;
    if (parCurIndex== -1) parCurIndex = 0;  // done with init 
    
    if (saveActive)
    {
      paramFile.close();
      saveActive = false; 
    }  
    
    popStyle();
    popMatrix();
  } 

   
  float parF(float v, String vname, String id, float defaultV, float minV, float maxV, float deltaV)
  {
    if (notAvailNoticeTime != 0) return v;  // contest running, param dialog not available
    
    
    if (loadActive)
    {
       // search load lines for variable then set variable value, 
       // ignore other items if present     
       
       for (String s: paramLines)
       { String[] t = s.split(",");
         if (t[0].equals(vname)) v = Float.valueOf(t[1]);
       }
       
    }
    
    if (saveActive)
    {
      //paramFile.println(String.format("%s,%s,%1.4f,%1.4f,%1.4f,%1.4f,%1.4f",vname,id,v,defaultV,minV,maxV,deltaV));
      // writing simple variable name,value 
      paramFile.println(String.format("%s,%1.4f",vname,v));
    }
    
    
    
    float dv = maxV-minV;       
    float posN = (v-minV)/dv;  // normalized position 
 
   // limit visible to parPageSize with TopIndex controlled by PgUp PgDn
    
   if (visible && (parIndex>=parPageTopIndex) && (parIndex<parPageTopIndex+parPageSize))
   {
     String txt =  String.format("%s  %s  = %1.2f",vname,id,v);
     if (textBox(txt,posN,txtVP.x,txtVP.y+(parIndex+1-parPageTopIndex)*txtVPLineH,txtVP.w,txtVP.h))      // return true if mouse clicked in box
     {
       parCurIndex = parIndex;
     }
     else parCurIndex = -99;  // New Oct 22, 2020  
    
   }
   
   if (parCurIndex == -1) { return defaultV; }  // special case before first parEnd() call -- set defaults 
   else if (parCurIndex == parIndex)            // this is the parameter we want to edit
   {
     if (curKey == '+') v+=deltaV*deltaMult;
     if (curKey == '-') v-=deltaV*deltaMult;
     curKey = 'x';
     
     v += mouseWheelDelta*deltaV*deltaMult;
     mouseWheelDelta = 0;
     
      
  
     
     if (mouseJustPressedL)               // log current value when mouse pressed 
     {
       mouseXOnPressL = mouseX;
       mouseInitialValueL = v;            // remember this value until next time 
       mouseJustPressedL = false;
       //println ("mouseJustPressed  ParF    mouseX ",mouseX,"  initial value ",v,"index ",parIndex);
       mouseDownL = true;
     }
        
     // adjust variable using mouse delta scaled so that 1/2 width of screen worth of mouse delta
     // results in full scale change of v
     
     // need to make deltaV increments 
     
     if (mouseDownL)
     {
      float d = ((mouseX-mouseXOnPressL)*dv/(width*0.5));  // change 
      v = mouseInitialValueL + floor(d/deltaV) *deltaV;
     }
    
      //  1 to 10 delta v = 0.1          +  0.08          
        
     //curCmd = 0;
     
     if (v>maxV) v=maxV;
     if (v<minV) v=minV;
     
     if (requestDefault)
     { v = defaultV;
       statusMessage("Set parameter to default value");
       requestDefault = false;
     }  
   }
   parIndex++;
   
 
   return v;
 }
   
 int parI(int v, String vname, String id, int defaultV, int minV, int maxV)  // integer parameter  val = parI (val,default,min,max)
 {
    if (notAvailNoticeTime != 0) return v;  // contest running, param dialog not available
    if (loadActive)
    {
       // search load lines for variable then set variable value, 
       // ignore other items if present     
       
       for (String s: paramLines)
       { String[] t = s.split(",");
         if (t[0].equals(vname)) v = Integer.valueOf(t[1]);
       }
       
    }
   
    if (saveActive)
      paramFile.println(String.format("%s,%d",vname,v));  // writing simple variable name,value 
     
    int dv = maxV-minV;       
    float posN = 1.0*(v-minV)/dv;  // normalized position 
   
   if (visible) 
   {
     String txt =  String.format("%s  %s  = %d",vname,id,v);   // Oct 22, 2020  changed to int %d
     if (textBox(txt,posN,txtVP.x,txtVP.y+(parIndex+1-parPageTopIndex)*txtVPLineH,txtVP.w,txtVP.h))      // return true if mouse clicked in box
     {
       parCurIndex = parIndex;
   
     }
     else parCurIndex = -99;  // New Oct 22,2020   
   }
   
   if (parCurIndex == -1) { return defaultV; }  // special case before first parEnd() call -- set defaults 
   else if (parCurIndex == parIndex)
   {
     
     if (curKey == '+') v+=deltaMult;
     if (curKey == '-') v-=deltaMult;
     curKey = ' ';
     
     
     v += mouseWheelDelta*deltaMult;
     mouseWheelDelta = 0;
     
      
     if (mouseJustPressedL)               // log current value when mouse pressed 
     {
       mouseXOnPressL = mouseX;
       mouseInitialValueL = v;
       //println ("mouseInitialValue on ParI vale  ",v);
       mouseJustPressedL = false;
       mouseDownL = true;
     }
       
         
     // adjust variable using mouse delta scaled so that 1/2 width of screen worth of mouse delta
     // results in full scale change of v
     
     if (mouseDownL)
      v = (int) mouseInitialValueL + ((mouseX-mouseXOnPressL)*dv/(width/2));  
       
           
    // curCmd = 0;
     
     if (v>maxV) v=maxV;
     if (v<minV) v=minV;
     
     if (requestDefault)
     { v = defaultV;
       statusMessage("Set parameter to default value");
       requestDefault = false;
     }  
         
   }
   
 
   parIndex++;
   return v;
 }
 
  
  void processKey(char k, int kcode)
  { 
    if (lfs.contestIsRunning())
    {
      if (k=='P') { notAvailNoticeTime = millis(); visible = true; }     
      return;
    }  
    
    if (k == 'P') parEditor.visible = !parEditor.visible;
    
    if (!visible) return;  // skip decode if panel not visible
    
    curKey = k; // used for decode within parF parI methods for current parameter.
      
   if (kcode == 16) parPageTopIndex -= parPageSize;   // KeyEvent.VK_PAGE_UP   - not accessible
   if (kcode == 11) parPageTopIndex += parPageSize;   // KeyEvent.VK_PAGE_DOWN
 
   // keep in limits based on number of items 
   if (parPageTopIndex < 0) parPageTopIndex = 0;
   if (parPageTopIndex >= parCount) parPageTopIndex -= parPageSize; 
   
   if (k == 'A'-64)
   { parCurIndex = -1;    // ctrl-A default ALL
     statusMessage("Set ALL parameters to default values");
   }
   
   if (k == 'D'-64) requestDefault = true;  // set default on current variable, next time   
  
   if (k == 'S'-64) requestSave = true;
   if (k == 'L'-64) 
   {
     paramLines = loadStrings(dataPath("param.cdf"));
     if (paramLines.length == 0)
       statusMessage("Load parameters failed - file not found or empty file");
     else
     {
      statusMessage("Load parameters from sketch sub-folder  data/param.cdf");
      requestLoad = true; 
     } 
      
   }
   
   
      
  }

  boolean handleMouseClick() // called from mouseClicked() method, in LFS defined in UserKey
  {
    if (visible && mouseInCloseBox) visible = false;
    
    return (mouseInView()); // tell mouseClicked, we got it  
       // going to let handleMouse take care of it during  update 
  }
 
  void handleMouse()  
  {
   if (mousePressed && (mouseButton == LEFT) && mouseInView())   // Oct 22 added mouseInView()
   {
     if (!mouseDownL) 
     {  mouseJustPressedL = true;  // param editor will handle 
        // println ("parEditor just pressed LEFT ");
     }
    
   }
   else {
     //if (mouseDownL) println ("releasing mouseDownL  set false");
    
     mouseDownL=false;              //  but we can clear 
     mouseJustPressedL = false;     //  make sure cleared
     
    // parCurIndex = -99;           //  deselect parameter - prevent further modification 
                                    //  OK for mouse drag, but not for hover and +/-   
   
   
   }
  
 
  } // end parHandleMouse()
  
  
  boolean textBox (String s, float posN, float x, float y, float w, float h)  // temp text box
  {
     boolean mouseInBox = ((mouseX>x)&&(mouseX<x+w)&&(mouseY>y)&&(mouseY<y+h));
     pushStyle();  
     
     rectMode(CORNER);
     stroke (50,50,200);
     fill (20);
     rect (x,y,w,h);
         
     noStroke(); 
     fill (60);
     rect (x,y,posN*w,h);
  
     if (mouseInBox) fill (100,255,100);
     else fill (130);
     
     textSize(parTextSize);
     
     strokeWeight(1.0);
     text(s,x+20,y+ 20);
     
     popStyle();
     return mouseInBox; 
   }
 
} // end ParEditor class
