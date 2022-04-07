//
//  "00-Scr-ObjectCopier.mq4"  -- read/write objects to/from global variable
//
//    Ver. 1.00  2008/9/26(Fri)
//    Ver. 1.20  2022/1/22
//    Ver. 1.30  2022/4/7
//
#property  copyright  "00"
#property  link       "http://www.mql4.com/"
#include <WinUser32.mqh>
#import "kernel32.dll"
  int GlobalAlloc(int Flags, int Size);
  int GlobalLock(int hMem);
  int GlobalUnlock(int hMem);
  int GlobalFree(int hMem);
  int lstrcpyW(int ptrhMem, string Text);
  int lstrcpyA(int ptrhMem, string Text);
  string lstrcatW(int dst,string src);
  //void MoveMemoryA(int Destination, int Source, int Length);
#import


#import "user32.dll"
  int OpenClipboard(int hOwnerWindow);
  int EmptyClipboard();
  int CloseClipboard();
  int SetClipboardData(int Format, int hMem);
  bool IsClipboardFormatAvailable(int Format);
  int GetClipboardData(int Format);
  int   GetAncestor(long hWnd,int gaFlags);
  int   GetAncestor(int  hWnd,int gaFlags);
#import

#define GMEM_MOVEABLE   2
#define CF_UNICODETEXT  13

//#property  show_confirm
#property script_show_inputs


//---- defines
#define S_TREND      "trend"
#define S_RECTANGLE  "rect"
#define S_VLINE      "vline"
#define S_HLINE      "hline"
#define S_TEXT       "text"
#define S_LABEL       "label"
#define S_ARROW      "arrow"
#define S_FIBO       "fibo"
#define S_EXPANSION  "expansion"
#define S_FIBOCHANNEL  "fiboc"
#define S_FIBOFAN      "fibofan"
#define S_CHANNEL  "channel"

//---- script parameters
//extern bool   bMaster         = false;      // true: copy objs to global vars, false: vice versa  
extern string sMasterPrefix   = "CP";  // prefix for global vars
extern string sSlavePrefix   = "CP";  // prefix for global vars

extern double tUpdate         = 1.0;        // interval time in sec
extern bool   bCopyTrend      = true;       // copy OBJ_TREND or not
extern bool   bCopyRectangle  = true;       // copy OBJ_RECTANGLE or not
extern bool   bCopyVLine      = true;       // copy OBJ_VLINE or not
extern bool   bCopyHLine      = true;       // copy OBJ_HLINE or not
extern bool   bCopyText       = true;       // copy OBJ_TEXT or not
extern bool   bCopyLabel      = true;       // copy OBJ_LABEL or not
extern bool   bCopyArrow      = true;       // copy OBJ_ARROW or not
extern bool   bCopyFibo       = true;       // copy OBJ_FIBO or not
extern bool   bCopyExpansion  = true;       // copy OBJ_EXPANSION or not
extern bool   bCopyFiboChannel= true;       // copy OBJ_FIBOCHANNEL or not
extern bool   bCopyFiboFan    = true;       // copy OBJ_FIBOFAN or not
extern bool   bCopyChannel    = true;       // copy OBJ_CHANNEL or not
extern bool bClipBoardOnly=true;

//---- vars
string sScriptName      = "00-Scr-ObjectCopier";
string sScriptShortName = "00-OC";
string sMasterPrefixOld;
string sSlavePrefixOld;
extern bool   PasteMode = false;

//----------------------------------------------------------------------
string CopyTextFromClipboard()
{
  int    hMain;
  string clip="";
  //---
  if(_IsX64)
    hMain=GetAncestor(ChartGetInteger(ChartID(),CHART_WINDOW_HANDLE),2);
  else
    hMain=GetAncestor((int)ChartGetInteger(ChartID(),CHART_WINDOW_HANDLE),2);
  //---
  if(OpenClipboard(hMain)){
    int hglb=GetClipboardData(1/*CF_TEXT*/);
    if(hglb!=0)      {
      int lptstr=GlobalLock(hglb);
      if(lptstr!=0) { clip=lstrcatW(lptstr,""); GlobalUnlock(hglb); }
    }
    CloseClipboard();
  }

  // translate ANSI to UNICODE
  ushort chW; uchar chA; string rez;
  for(int i=0; i<StringLen(clip); i++)    {
    chW=StringGetCharacter(clip, i);
    chA=uchar(chW&255); rez=rez+CharToString(chA);
    chA=uchar(chW>>8&255); rez=rez+CharToString(chA);
  }

  // MessageBox("Clipboard: \n"+rez,"Clipboard");
  return( rez);
}
//----------------------------------------------------------------------
// Copies the specified text to the clipboard, returning true if successful
string CopyTextFromClipboardBad()
{
  bool bReturnvalue = false;
  string strBuf=""; 

  if(IsClipboardFormatAvailable(CF_UNICODETEXT)) {
    //Print ("000");
    // Try grabbing ownership of the clipboard 
    if(OpenClipboard(0) != 0) {
      //Print ("010");
      // Try emptying the clipboard
      int hMem = GetClipboardData(CF_UNICODETEXT);
      if(hMem != NULL){
        int pMem = GlobalLock(hMem);
        if(pMem != NULL){
          //Print ("pMem="+pMem);
          //lstrcpy(strBuf, pMem);
          //MoveMemoryA(strBuf, pMem, 10);         
          lstrcatW(strBuf, pMem);            
          //StringConcatenate(strBuf, pMem);            
          //Print ("strBuf0="+strBuf);
        }
        GlobalUnlock(hMem); 
      }
      CloseClipboard();
    }
  }
  //Print ("strBuf1="+strBuf);
  return(strBuf);
}
//----------------------------------------------------------------------
//----------------------------------------------------------------------
void init()
{
    sMasterPrefixOld = StringConcatenate(sScriptName, "-", sMasterPrefix);
    sMasterPrefix = StringConcatenate(sScriptShortName, "-", sMasterPrefix);
    sSlavePrefixOld = StringConcatenate(sScriptName, "-", sSlavePrefix);
    sSlavePrefix = StringConcatenate(sScriptShortName, "-", sSlavePrefix);
}
//----------------------------------------------------------------------
void deinit()
{
  if(PasteMode){
    //GlobalVariablesDeleteAll(sMasterPrefixOld);
    //GlobalVariablesDeleteAll(sMasterPrefix);
  }
}
//----------------------------------------------------------------------
int getObjType(string sParam[])
{
    int type = -1;
    string sType = sParam[1];
    
    if (sType == S_TREND) {
	type = OBJ_TREND;
    } else if (sType == S_RECTANGLE) {
	type = OBJ_RECTANGLE;
    } else if (sType == S_VLINE) {
	type = OBJ_VLINE;
    } else if (sType == S_HLINE) {
	type = OBJ_HLINE;
    } else if (sType == S_TEXT) {
	type = OBJ_TEXT;
    } else if (sType == S_LABEL) {
	type = OBJ_LABEL;
    } else if (sType == S_ARROW) {
	type = OBJ_ARROW;
    } else if (sType == S_FIBO) {
	type = OBJ_FIBO;
    } else if (sType == S_EXPANSION) {
	type = OBJ_EXPANSION;
    } else if (sType == S_FIBOCHANNEL) {
	type = OBJ_FIBOCHANNEL;
    } else if (sType == S_FIBOFAN) {
	type = OBJ_FIBOFAN;
    } else if (sType == S_CHANNEL) {
	type = OBJ_CHANNEL;
    } else {
	// not supported
    }
    
    return(type);
}
//----------------------------------------------------------------------
string getPrefix(string type, string sObjStr)
{
   static int num = 1;
   if(StringLen(sObjStr)>40){
      for(int i=0;i<128;i++){
          int ch = StringGetChar(sObjStr,StringLen(sObjStr)-1);
         if(ch>=48 && ch<=57){
         sObjStr = StringSubstr(sObjStr,0,StringLen(sObjStr)-2);
         }else{ break;}
      }
      sObjStr = sObjStr+num;
      num++;
   }
    return(StringConcatenate(sMasterPrefix, " ", type, " ", sObjStr));
}
//----------------------------------------------------------------------
string getSlavePrefix(string type, string sObjStr)
{
  int i=0;
  sObjStr = strSPACEdecode(sObjStr);
  //return(StringConcatenate(sSlavePrefix, " ", type, " ", sObjStr));
  if(ObjectFind(sObjStr) ==-1) return(sObjStr);
  //for(int i=0;i<128;i++){
  //  int ch = StringGetChar(sObjStr,StringLen(sObjStr)-1);
  //  if(ch>=48 && ch<=57){ // 0x30 to 0x39 '0' to '9'
  //     sObjStr = StringSubstr(sObjStr,0,StringLen(sObjStr)-2);
  //  }else{break;}
  //}
  i = 0;
  while(ObjectFind(sObjStr+"_"+i) !=-1 && i < 128){
    i++;
  }
  return(sObjStr+"_"+i);
}
//----------------------------------------------------------------------
string varSet(string sVarName, double v = 0.0)
{
    GlobalVariableSet(sVarName, v);
    
    return(sVarName);
}

//----------------------------------------------------------------------
string varSetTime1(string sVarName, double t1)
{
    string s = StringConcatenate(sVarName, " t1");
    GlobalVariableSet(s, t1);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetPrice1(string sVarName, double p1)
{
    string s = StringConcatenate(sVarName, " p1");
    GlobalVariableSet(s, p1);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetColor(string sVarName, color col)
{
    string s = StringConcatenate(sVarName, " color");
    GlobalVariableSet(s, col);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetPos1(string sVarName, double t, double p)
{
    string s = "";
    
    s = StringConcatenate(s, varSetTime1(sVarName, t));
    s = StringConcatenate(s, varSetPrice1(sVarName, p));
    
    return(s);
}

//----------------------------------------------------------------------
string varSetPos2(string sVarName, double t, double p)
{
    string s1 = StringConcatenate(sVarName, " t2");
    string s2 = StringConcatenate(sVarName, " p2");
    
    GlobalVariableSet(s1, t);
    GlobalVariableSet(s2, p);
    
    return(s1 + s2);
}

//----------------------------------------------------------------------
string varSetPos3(string sVarName, double t, double p)
{
    string s1 = StringConcatenate(sVarName, " t3");
    string s2 = StringConcatenate(sVarName, " p3");
    
    GlobalVariableSet(s1, t);
    GlobalVariableSet(s2, p);
    
    return(s1 + s2);
}

//----------------------------------------------------------------------
string varSetStyle(string sVarName, int width, int style, color col)
{
    string s1 = StringConcatenate(sVarName, " width");
    string s2 = StringConcatenate(sVarName, " style");
    
    GlobalVariableSet(s1, width);
    GlobalVariableSet(s2, style);
    string s = s1 + s2;
    s = s + varSetColor(sVarName, col);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetLevelColor(string sVarName, color levelCol)
{
    string s = StringConcatenate(sVarName, " levelColor");
    GlobalVariableSet(s, levelCol);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetLevelStyle(string sVarName, int levelWidth, int levelStyle, color levelCol)
{
    string s1 = StringConcatenate(sVarName, " levelWidth");
    string s2 = StringConcatenate(sVarName, " levelStyle");
    
    GlobalVariableSet(s1, levelWidth);
    GlobalVariableSet(s2, levelStyle);
    string s = s1 + s2;
    s = s + varSetLevelColor(sVarName, levelCol);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetRay(string sVarName, int ray)
{
    string s = StringConcatenate(sVarName, " ray");
    GlobalVariableSet(s, ray);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetBack(string sVarName, int back)
{
    string s = StringConcatenate(sVarName, " back");
    GlobalVariableSet(s, back);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetAngle(string sVarName, double angle)
{
    string s = StringConcatenate(sVarName, " angle");
    GlobalVariableSet(s, angle);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetScale(string sVarName, double scale)
{
    string s = StringConcatenate(sVarName, " scale");
    GlobalVariableSet(s, scale);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetArrowCode(string sVarName, int arrowCode)
{
    string s = StringConcatenate(sVarName, " arrowCode");
    GlobalVariableSet(s, arrowCode);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetText(string sVarName, string text, int fontSize, color col)
{
    string s1 = StringConcatenate(sVarName, " text ", text);
    string s2 = StringConcatenate(sVarName, " fontSize");
    GlobalVariableSet(s1, 0);
    GlobalVariableSet(s2, fontSize);
    string s = StringConcatenate(s1, s2);
    s = StringConcatenate(s, varSetColor(sVarName, col));
    
    return(s);
}
string varSetTF(string sVarName, int tf)
{
    string s = StringConcatenate(sVarName, " tf");
    GlobalVariableSet(s, tf);
    
    return(s);
}
string varSetFibo(string sVarName, int FIBOLEVELS,double &FiboLines[])
{
    //if(FIBOLEVELS==0) return("");
    string s = StringConcatenate(sVarName, " fl");
    GlobalVariableSet(s, FIBOLEVELS);   
    for(int i=0;i<FIBOLEVELS;i++)
    {
    string t = StringConcatenate(sVarName, " f",i);
    GlobalVariableSet(t, FiboLines[i]);
    s = StringConcatenate(s, t);
    }
    return(s);
}


//----------------------------------------------------------------------
string varGetText(string sVarPrefix, int length)
{
  //int nVar = GlobalVariablesTotal();
  int iChar=0;
  string text_local="";

  //Print ("text_len="+length);

  for(int str_idx = 0 ; str_idx < length ; str_idx++){
  	iChar = GlobalVariableGet(StringConcatenate(sVarPrefix, " text"+str_idx));
    text_local=text_local+ShortToString(iChar);
    //Print (iChar);
  }
  //Print(text_local);
  return(text_local);
}
//----------------------------------------------------------------------
string varGetFontName(string sVarPrefix, int length)
{
  //int nVar = GlobalVariablesTotal();
  int iChar=0;
  string text_local="";

  //Print ("fn_len="+length);
  for(int str_idx = 0 ; str_idx < length ; str_idx++){
  	iChar = GlobalVariableGet(StringConcatenate(sVarPrefix, " fn"+str_idx));
    text_local=text_local+ShortToString(iChar);
  }
  return(text_local);
}
//----------------------------------------------------------------------
void objSetTime1(string sObjName, datetime t)
{
    ObjectSet(sObjName, OBJPROP_TIME1,  t);
}

//----------------------------------------------------------------------
void objSetPrice1(string sObjName, double p)
{
    ObjectSet(sObjName, OBJPROP_PRICE1, p);
}

//----------------------------------------------------------------------
void objSetXY(string sObjName, int x, int y)
{
    ObjectSetInteger(0, sObjName, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, sObjName, OBJPROP_YDISTANCE, y);
}
//----------------------------------------------------------------------
void objSetPos1(string sObjName, datetime t, double p)
{
    objSetTime1(sObjName, t);
    objSetPrice1(sObjName, p);
}

//----------------------------------------------------------------------
void objSetPos2(string sObjName, datetime t, double p)
{
    ObjectSet(sObjName, OBJPROP_TIME2,  t);
    ObjectSet(sObjName, OBJPROP_PRICE2, p);
}

//----------------------------------------------------------------------
void objSetPos3(string sObjName, datetime t, double p)
{
    ObjectSet(sObjName, OBJPROP_TIME3,  t);
    ObjectSet(sObjName, OBJPROP_PRICE3, p);
}

//----------------------------------------------------------------------
void objSetStyle(string sObjName, int width, int style, color col)
{
    ObjectSet(sObjName, OBJPROP_WIDTH, width);
    ObjectSet(sObjName, OBJPROP_STYLE, style);
    ObjectSet(sObjName, OBJPROP_COLOR, col);
}

//----------------------------------------------------------------------
void objSetLevelStyle(string sObjName, int levelWidth, int levelStyle, color levelCol)
{
    ObjectSet(sObjName, OBJPROP_LEVELWIDTH, levelWidth);
    ObjectSet(sObjName, OBJPROP_LEVELSTYLE, levelStyle);
    ObjectSet(sObjName, OBJPROP_LEVELCOLOR, levelCol);
}

//----------------------------------------------------------------------
void objSetRay(string sObjName, int ray)
{
    ObjectSet(sObjName, OBJPROP_RAY, ray);
}

//----------------------------------------------------------------------
void objSetBack(string sObjName, int back)
{
    ObjectSet(sObjName, OBJPROP_BACK, back);
}

//----------------------------------------------------------------------
void objSetAngle(string sObjName, double angle)
{
    ObjectSet(sObjName, OBJPROP_ANGLE, angle);
}

//----------------------------------------------------------------------
void objSetScale(string sObjName, double scale)
{
    ObjectSet(sObjName, OBJPROP_SCALE, scale);
}

//----------------------------------------------------------------------
void objSetArrowCode(string sObjName, int arrowCode)
{
    ObjectSet(sObjName, OBJPROP_ARROWCODE, arrowCode);
}

//----------------------------------------------------------------------
void objSetText(string sObjName, string text, int fontSize, color col)
{
    ObjectSetText(sObjName, text, fontSize, "", col);
}
//----------------------------------------------------------------------
//----------------------------------------------------------------------
void objSetTF(string sObjName, int tf)
{
    ObjectSet(sObjName, OBJPROP_TIMEFRAMES, tf);
}
void objSetFibo(string sObjName, int FIBOLEVELS,double &FiboLines[])
{
    ObjectSet(sObjName, OBJPROP_FIBOLEVELS, FIBOLEVELS);   
    if(FIBOLEVELS>0){
      for(int i=0;i<FIBOLEVELS;i++){
         ObjectSet(sObjName,OBJPROP_FIRSTLEVEL+i,FiboLines[i]);
         ObjectSetFiboDescription(sObjName,i,DoubleToStr(FiboLines[i]*100,1));//%$
      }
    }
}
//----------------------------------------------------------------------
string strChConv(string s, int ch = '_')
{
    int len = StringLen(s);
    
    for (int i = 0; i < len; i++) {
	if (StringGetChar(s, i) == ' ') {
	    s = StringSetChar(s, i, ch);
	}
    }
    
    return(s);
}
string strSPACEdecode(string s)
{
   int len = StringLen(s);
   for (int j = 0; j < len; j++) {
      int i=StringFind(s,"_%_");
      if(i==-1) break;
      if(i>0){
        s=StringSubstr(s,0,i)+" "+StringSubstr(s,i+3,StringLen(s));
      }else{
        s=" "+StringSubstr(s,i+3,StringLen(s));
      }
   }
   return(s);
}
string strSPACEencode(string s)
{
   int len = StringLen(s);
   for (int j = 0; j < len; j++) {
      int i=StringFind(s," ");
      if(i==-1) break;
      if(i>0){
        s=StringSubstr(s,0,i)+"_%_"+StringSubstr(s,i+1,StringLen(s));
      }else{
        s="_%_"+StringSubstr(s,i+1,StringLen(s));
      }
   }
   return(s);
}

//----------------------------------------------------------------------
int strSplit(string str, string &sParam[])
{
    int nParam = 0;
    
    for (int loop = 0; loop < 2; loop++) {
	string s = str;
	for (; ;) {
	    s = StringTrimLeft(s);
	    int len = StringLen(s);
	    if (len <= 0) {
		break;
	    }
	    int x = StringFind(s, " ");
	    string w;
	    if (x > 0) {
		w = StringSubstr(s, 0, x);
		s = StringSubstr(s, x + 1);
	    } else {
		w = s;
		s = "";
	    }
	    if (loop == 1) {
		sParam[nParam] = w;
	    }
	    nParam++;
	}
	
	if (loop == 0) {
	    ArrayResize(sParam, nParam);
	    nParam = 0;
	}
    }
    
    return(nParam);
}

//----------------------------------------------------------------------
bool isValidTime(datetime t)
{
    return(t > 0);
}

//----------------------------------------------------------------------
bool isValidPrice(double p)
{
    return(p > 0);
}

//----------------------------------------------------------------------
bool isValidPos1(datetime t1, double p1)
{
    return(isValidTime(t1) && isValidPrice(p1));
}

//----------------------------------------------------------------------
bool isValidPos12(datetime t1, double p1, datetime t2, double p2)
{
    return(isValidPos1(t1, p1) && isValidPos1(t2, p2));
}

//----------------------------------------------------------------------
bool isValidPos123(datetime t1, double p1, datetime t2, double p2, datetime t3, double p3)
{
    return(isValidPos1(t1, p1) && isValidPos1(t2, p2) && isValidPos1(t3, p3));
}

//----------------------------------------------------------------------
string writeGlobalVar(string sObjName)
{
    string sAll = "";
    int type = ObjectType(sObjName);
    string sObjStr = strSPACEencode(sObjName);
    string sVarName;
    
    datetime t1         = ObjectGet(sObjName, OBJPROP_TIME1);
    double   p1         = ObjectGet(sObjName, OBJPROP_PRICE1);
    datetime t2         = ObjectGet(sObjName, OBJPROP_TIME2);
    double   p2         = ObjectGet(sObjName, OBJPROP_PRICE2);
    datetime t3         = ObjectGet(sObjName, OBJPROP_TIME3);
    double   p3         = ObjectGet(sObjName, OBJPROP_PRICE3);
    int      width      = ObjectGet(sObjName, OBJPROP_WIDTH);
    int      style      = ObjectGet(sObjName, OBJPROP_STYLE);
    int      ray        = ObjectGet(sObjName, OBJPROP_RAY);
    int      back       = ObjectGet(sObjName, OBJPROP_BACK);
    color    col        = ObjectGet(sObjName, OBJPROP_COLOR);
    int      fontSize   = ObjectGet(sObjName, OBJPROP_FONTSIZE);
    double   angle      = ObjectGet(sObjName, OBJPROP_ANGLE);
    double   scale      = ObjectGet(sObjName, OBJPROP_SCALE);
    int      levelWidth = ObjectGet(sObjName, OBJPROP_LEVELWIDTH);
    int      levelStyle = ObjectGet(sObjName, OBJPROP_LEVELSTYLE);
    color    levelCol   = ObjectGet(sObjName, OBJPROP_LEVELCOLOR);
    int      arrowCode  = ObjectGet(sObjName, OBJPROP_ARROWCODE);
    int      TIMEFRAMES = ObjectGet(sObjName, OBJPROP_TIMEFRAMES);
    int      FIBOLEVELS = ObjectGet(sObjName, OBJPROP_FIBOLEVELS);
    double FiboLines[32];
    //Print("FIBOLEVELS=",FIBOLEVELS);
    if(FIBOLEVELS>0){
      for(int i=0;i<FIBOLEVELS;i++){
        FiboLines[i] = ObjectGet(sObjName,OBJPROP_FIRSTLEVEL+i);
        //Print("FiboLines[",i,"]",FiboLines[i]);
      }
    }
    
    switch (type) {
	
    case OBJ_TREND:
	if (bCopyTrend) {
	    if (isValidPos12(t1, p1, t2, p2)) {
		sVarName = getPrefix(S_TREND, sObjStr);
		sAll = StringConcatenate(sAll, varSet(sVarName));
		sAll = StringConcatenate(sAll, varSetPos1(sVarName, t1, p1));
		sAll = StringConcatenate(sAll, varSetPos2(sVarName, t2, p2));
		sAll = StringConcatenate(sAll, varSetStyle(sVarName, width, style, col));
		sAll = StringConcatenate(sAll, varSetRay(sVarName, ray));
		sAll = StringConcatenate(sAll, varSetBack(sVarName, back));
		sAll = StringConcatenate(sAll, varSetTF(sVarName, TIMEFRAMES));
	    }
	}
	break;
	
    case OBJ_RECTANGLE:
	if (bCopyTrend) {
	    if (isValidPos12(t1, p1, t2, p2)) {
		sVarName = getPrefix(S_RECTANGLE, sObjStr);
		sAll = StringConcatenate(sAll, varSet(sVarName));
		sAll = StringConcatenate(sAll, varSetPos1(sVarName, t1, p1));
		sAll = StringConcatenate(sAll, varSetPos2(sVarName, t2, p2));
		sAll = StringConcatenate(sAll, varSetStyle(sVarName, width, style, col));
		sAll = StringConcatenate(sAll, varSetBack(sVarName, back));
		sAll = StringConcatenate(sAll, varSetTF(sVarName, TIMEFRAMES));
	    }
	}
	break;
	
    case OBJ_VLINE:
	if (bCopyVLine) {
	    if (isValidTime(t1)) {
		sVarName = getPrefix(S_VLINE, sObjStr);
		sAll = StringConcatenate(sAll, varSet(sVarName));
		sAll = StringConcatenate(sAll, varSetTime1(sVarName, t1));
		sAll = StringConcatenate(sAll, varSetStyle(sVarName, width, style, col));
		sAll = StringConcatenate(sAll, varSetBack(sVarName, back));
		sAll = StringConcatenate(sAll, varSetTF(sVarName, TIMEFRAMES));
	    }
	}
	break;
	
    case OBJ_HLINE:
	if (bCopyHLine) {
	    if (isValidPrice(p1)) {
		sVarName = getPrefix(S_HLINE, sObjStr);
		sAll = StringConcatenate(sAll, varSet(sVarName));
		sAll = StringConcatenate(sAll, varSetPrice1(sVarName, p1));
		sAll = StringConcatenate(sAll, varSetStyle(sVarName, width, style, col));
		sAll = StringConcatenate(sAll, varSetBack(sVarName, back));
		sAll = StringConcatenate(sAll, varSetTF(sVarName, TIMEFRAMES));
	    }
	}
	break;
	
    case OBJ_TEXT:
	if (bCopyText) {
	    if (isValidPos1(t1, p1)) {
		sVarName = getPrefix(S_TEXT, sObjStr);
		sAll = StringConcatenate(sAll, varSet(sVarName));
		sAll = StringConcatenate(sAll, varSetPos1(sVarName, t1, p1));
		string text = ObjectDescription(sObjName);
		sAll = StringConcatenate(sAll, varSetText(sVarName, text, fontSize, col));
		sAll = StringConcatenate(sAll, varSetBack(sVarName, back));
		sAll = StringConcatenate(sAll, varSetAngle(sVarName, angle));
		sAll = StringConcatenate(sAll, varSetTF(sVarName, TIMEFRAMES));
	    }
	}
	break;
	
    case OBJ_ARROW:
	if (bCopyArrow) {
	    if (isValidPos1(t1, p1)) {
		sVarName = getPrefix(S_ARROW, sObjStr);
		sAll = StringConcatenate(sAll, varSet(sVarName));
		sAll = StringConcatenate(sAll, varSetPos1(sVarName, t1, p1));
		sAll = StringConcatenate(sAll, varSetStyle(sVarName, width, style, col));
		sAll = StringConcatenate(sAll, varSetBack(sVarName, back));
		sAll = StringConcatenate(sAll, varSetArrowCode(sVarName, arrowCode));
		sAll = StringConcatenate(sAll, varSetTF(sVarName, TIMEFRAMES));
	    }
	}
	break;
	
    case OBJ_FIBO:
	if (bCopyFibo) {
	    if (isValidPos12(t1, p1, t2, p2)) {
		sVarName = getPrefix(S_FIBO, sObjStr);
		sAll = StringConcatenate(sAll, varSet(sVarName));
		sAll = StringConcatenate(sAll, varSetPos1(sVarName, t1, p1));
		sAll = StringConcatenate(sAll, varSetPos2(sVarName, t2, p2));
		sAll = StringConcatenate(sAll, varSetStyle(sVarName, width, style, col));
		sAll = StringConcatenate(sAll, varSetRay(sVarName, ray));
		sAll = StringConcatenate(sAll, varSetBack(sVarName, back));
		sAll = StringConcatenate(sAll, varSetLevelStyle(sVarName, levelWidth, levelStyle, levelCol));
		sAll = StringConcatenate(sAll, varSetTF(sVarName, TIMEFRAMES));
		sAll = StringConcatenate(sAll, varSetFibo(sVarName,FIBOLEVELS,FiboLines));
	    }
	}
	break;
	
    case OBJ_EXPANSION:
	if (bCopyExpansion) {
	    if (isValidPos123(t1, p1, t2, p2, t3, p3)) {
		sVarName = getPrefix(S_EXPANSION, sObjStr);
		sAll = StringConcatenate(sAll, varSet(sVarName));
		sAll = StringConcatenate(sAll, varSetPos1(sVarName, t1, p1));
		sAll = StringConcatenate(sAll, varSetPos2(sVarName, t2, p2));
		sAll = StringConcatenate(sAll, varSetPos3(sVarName, t3, p3));
		sAll = StringConcatenate(sAll, varSetStyle(sVarName, width, style, col));
		sAll = StringConcatenate(sAll, varSetBack(sVarName, back));
		sAll = StringConcatenate(sAll, varSetRay(sVarName, ray));
		sAll = StringConcatenate(sAll, varSetLevelStyle(sVarName, levelWidth, levelStyle, levelCol));
		sAll = StringConcatenate(sAll, varSetTF(sVarName, TIMEFRAMES));
		sAll = StringConcatenate(sAll, varSetFibo(sVarName,FIBOLEVELS,FiboLines));
	    }
	}
	break;
    case OBJ_FIBOCHANNEL:
	if (bCopyFiboChannel) {
	    if (isValidPos123(t1, p1, t2, p2, t3, p3)) {
		sVarName = getPrefix(S_FIBOCHANNEL, sObjStr);
		sAll = StringConcatenate(sAll, varSet(sVarName));
		sAll = StringConcatenate(sAll, varSetPos1(sVarName, t1, p1));
		sAll = StringConcatenate(sAll, varSetPos2(sVarName, t2, p2));
		sAll = StringConcatenate(sAll, varSetPos3(sVarName, t3, p3));
		sAll = StringConcatenate(sAll, varSetStyle(sVarName, width, style, col));
		sAll = StringConcatenate(sAll, varSetBack(sVarName, back));
		sAll = StringConcatenate(sAll, varSetRay(sVarName, ray));
		sAll = StringConcatenate(sAll, varSetLevelStyle(sVarName, levelWidth, levelStyle, levelCol));
		sAll = StringConcatenate(sAll, varSetTF(sVarName, TIMEFRAMES));
		sAll = StringConcatenate(sAll, varSetFibo(sVarName,FIBOLEVELS,FiboLines));
		
	    }
	}
	break;	
    case OBJ_FIBOFAN:
	if (bCopyFiboFan) {
	    if (isValidPos12(t1, p1, t2, p2)) {
		sVarName = getPrefix(S_FIBOFAN, sObjStr);
		sAll = StringConcatenate(sAll, varSet(sVarName));
		sAll = StringConcatenate(sAll, varSetPos1(sVarName, t1, p1));
		sAll = StringConcatenate(sAll, varSetPos2(sVarName, t2, p2));
		sAll = StringConcatenate(sAll, varSetStyle(sVarName, width, style, col));
		sAll = StringConcatenate(sAll, varSetBack(sVarName, back));
		sAll = StringConcatenate(sAll, varSetLevelStyle(sVarName, levelWidth, levelStyle, levelCol));
		sAll = StringConcatenate(sAll, varSetTF(sVarName, TIMEFRAMES));
		sAll = StringConcatenate(sAll, varSetFibo(sVarName,FIBOLEVELS,FiboLines));
	    }
	}
	break;
    case OBJ_CHANNEL:
	if (bCopyChannel) {
	    if (isValidPos123(t1, p1, t2, p2, t3, p3)) {
		sVarName = getPrefix(S_CHANNEL, sObjStr);
		sAll = StringConcatenate(sAll, varSet(sVarName));
		sAll = StringConcatenate(sAll, varSetPos1(sVarName, t1, p1));
		sAll = StringConcatenate(sAll, varSetPos2(sVarName, t2, p2));
		sAll = StringConcatenate(sAll, varSetPos3(sVarName, t3, p3));
		sAll = StringConcatenate(sAll, varSetStyle(sVarName, width, style, col));
		sAll = StringConcatenate(sAll, varSetBack(sVarName, back));
		sAll = StringConcatenate(sAll, varSetLevelStyle(sVarName, levelWidth, levelStyle, levelCol));
		sAll = StringConcatenate(sAll, varSetTF(sVarName, TIMEFRAMES));

	    }
	}
	break;	
    default:
	//Print(sObjName + " is not supported");
	break;
    }
    
    return(sAll);
}

//----------------------------------------------------------------------
void updateVars()
{
    int i;
    string sAll = "";
    
    int nObj = ObjectsTotal();
    for (i = 0; i < nObj; i++) {
	string sObjName = ObjectName(i);
	if (StringFind(sObjName, sSlavePrefix) >= 0) {
	    continue;
	}	
	if (ObjectFind(sObjName) == 0 ) {
	    // only copy objs in main chart (window 0)
	    sAll = StringConcatenate(sAll, writeGlobalVar(sObjName));
	}
    }
    
    // delete unused global vars
    int nVar = GlobalVariablesTotal();
    for (i = 0; i < nVar; i++) {
	string sVar = GlobalVariableName(i);
	if (StringFind(sVar, sMasterPrefix) < 0) {
	    continue;
	}	
	if (StringFind(sAll, sVar) < 0) {
	    GlobalVariableDel(sVar);
	}
    }
}

//----------------------------------------------------------------------
void updateObjects()
{
  int nObj = ObjectsTotal();
  int nVar = GlobalVariablesTotal();
  int jObj, jVar;
  string sObjName, sObjParam[];
  string sVarName, sVarParam[];
  int nDel = 0;
  
  /*for (jObj = 0; jObj < nObj; jObj++) {
	sObjName = ObjectName(jObj);
	
	if (StringFind(sObjName, sSlavePrefix) < 0) {
	    continue;
	}
	strSplit(sObjName, sObjParam);
	bool bFound = false;
	for (jVar = 0; jVar < nVar; jVar++) {
	    sVarName = GlobalVariableName(jVar);
	    if (StringFind(sVarName, sSlavePrefix) < 0) {
		continue;
	    }
	    strSplit(sVarName, sVarParam);
	    if (sObjParam[2] == sVarParam[2]) {
		bFound = true;
		break;
	    }
	}
	
	if (!bFound) {
	    ObjectDelete(sObjName);
	    nDel++;
	}
    }*/
    
  for (jVar = 0; jVar < nVar; jVar++) {
  	sVarName = GlobalVariableName(jVar);
  	if (StringFind(sVarName, sSlavePrefix) < 0) {
 	    continue;
  	}
  	int n = strSplit(sVarName, sVarParam);
  	if (n != 3) {
 	    continue;
  	}
  	int type = getObjType(sVarParam);
  	//Print ("debug objtype="+type);
	
  	int pos_x         = GlobalVariableGet(StringConcatenate(sVarName, " x"));
  	int pos_y         = GlobalVariableGet(StringConcatenate(sVarName, " y"));
  	datetime t1         = GlobalVariableGet(StringConcatenate(sVarName, " t1"));
  	double   p1         = GlobalVariableGet(StringConcatenate(sVarName, " p1"));
  	datetime t2         = GlobalVariableGet(StringConcatenate(sVarName, " t2"));
  	double   p2         = GlobalVariableGet(StringConcatenate(sVarName, " p2"));
  	datetime t3         = GlobalVariableGet(StringConcatenate(sVarName, " t3"));
  	double   p3         = GlobalVariableGet(StringConcatenate(sVarName, " p3"));
  	int      width      = GlobalVariableGet(StringConcatenate(sVarName, " width"));
  	int      style      = GlobalVariableGet(StringConcatenate(sVarName, " style"));
  	int      ray        = GlobalVariableGet(StringConcatenate(sVarName, " ray"));
  	int      back       = GlobalVariableGet(StringConcatenate(sVarName, " back"));
  	color    col        = GlobalVariableGet(StringConcatenate(sVarName, " color"));
  	int      fontSize   = GlobalVariableGet(StringConcatenate(sVarName, " fontSize"));
  	double   angle      = GlobalVariableGet(StringConcatenate(sVarName, " angle"));
  	double   scale      = GlobalVariableGet(StringConcatenate(sVarName, " scale"));
  	int      levelWidth = GlobalVariableGet(StringConcatenate(sVarName, " levelWidth"));
  	int      levelStyle = GlobalVariableGet(StringConcatenate(sVarName, " levelStyle"));
  	color    levelCol   = GlobalVariableGet(StringConcatenate(sVarName, " levelColor"));
  	int      arrowCode  = GlobalVariableGet(StringConcatenate(sVarName, " arrowCode"));
  	int      tf         = GlobalVariableGet(StringConcatenate(sVarName, " tf"));
  	int      FIBOLEVELS = GlobalVariableGet(StringConcatenate(sVarName, " fl"));
  	int      text_len   = GlobalVariableGet(StringConcatenate(sVarName, " textlen"));
  	int      fontname_len   = GlobalVariableGet(StringConcatenate(sVarName, " fnlen"));

    //Print("text_len000="+text_len);
    //Print("fontname_len000="+fontname_len);
    //Print("fontSize000="+fontSize);
    //Print("p1 000="+p1);
	
    double FiboLines[32];
  	if(FIBOLEVELS>0){
      for(int i=0;i<FIBOLEVELS;i++){
        FiboLines[i] = GlobalVariableGet(StringConcatenate(sVarName, " f",i));
      }
  	}

  	string   text="";
  	string fontName="";
  	switch (type) {
  
  	case OBJ_TREND:
  	    sObjName = getSlavePrefix(S_TREND, sVarParam[2]);
        if(ObjectFind(0, sObjName)<0){
    	    ObjectCreate(sObjName, OBJ_TREND, 0, 0, 0);
        }
  	    objSetPos1(sObjName, t1, p1);
  	    objSetPos2(sObjName, t2, p2);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetRay(sObjName, ray);
  	    objSetBack(sObjName, back);
  	    objSetTF(sObjName, tf);
  	    break;
  	    
  	case OBJ_RECTANGLE:
  	    sObjName = getSlavePrefix(S_RECTANGLE, sVarParam[2]);
        if(ObjectFind(0, sObjName)<0){
    	    ObjectCreate(sObjName, OBJ_RECTANGLE, 0, 0, 0);
        }
  	    objSetPos1(sObjName, t1, p1);
  	    objSetPos2(sObjName, t2, p2);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetTF(sObjName, tf);
  	    break;
  	    
  	case OBJ_VLINE:
  	    sObjName = getSlavePrefix(S_VLINE, sVarParam[2]);
  	    //ObjectCreate(sObjName, OBJ_VLINE, 0, 0, 0);
        if(ObjectFind(0, sObjName)<0){
    	    ObjectCreate(sObjName, OBJ_VLINE, 0, 0, 0);
        }
  	    objSetPos1(sObjName, t1, p1);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetTF(sObjName, tf);
  	    break;
  	    
  	case OBJ_HLINE:
  	    sObjName = getSlavePrefix(S_HLINE, sVarParam[2]);
  	    //ObjectCreate(sObjName, OBJ_HLINE, 0, 0, 0);
        if(ObjectFind(0, sObjName)<0){
          //Print ("sObjName:"+sObjName);
    	    if(!ObjectCreate(sObjName, OBJ_HLINE, 0, 0, 0)){
    	      //Print ("ERR: ObjectCreate HLINE : "+GetLastError()); 
    	    }
          //Print ("HLINE not found");
        }else{
          //Print ("HLINE found");
        }
  	    objSetPos1(sObjName, t1, p1);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetTF(sObjName, tf);
  	    break;
  	    
  	case OBJ_TEXT:
  	  //Print("debug here text");
	    //text     = varGetText(StringConcatenate(sVarName, " text"));
	    text     = varGetText(sVarName, text_len);
      //Print (text);
	    fontName = varGetFontName(sVarName, fontname_len);
      //Print (fontName);
	    sObjName = getSlavePrefix(S_TEXT, sVarParam[2]);
	    //ObjectCreate(sObjName, OBJ_TEXT, 0, 0, 0);
      if(ObjectFind(0, sObjName)<0){
  	    ObjectCreate(sObjName, OBJ_TEXT, 0, 0, 0);
      }
	    objSetPos1(sObjName, t1, p1);
	    objSetText(sObjName, text, fontSize, col);
      ObjectSetString(0, sObjName, OBJPROP_FONT, fontName); 
	    objSetBack(sObjName, back);
	    objSetAngle(sObjName, angle);
	    objSetTF(sObjName, tf);
	    break;
  	case OBJ_LABEL:
  	  //Print("debug here text");
	    //text     = varGetText(StringConcatenate(sVarName, " text"));
	    text     = varGetText(sVarName, text_len);
      //Print (text);
	    fontName = varGetFontName(sVarName, fontname_len);
      //Print (fontName);
	    sObjName = getSlavePrefix(S_LABEL, sVarParam[2]);
	    //ObjectCreate(sObjName, OBJ_TEXT, 0, 0, 0);
      if(ObjectFind(0, sObjName)<0){
  	    ObjectCreate(sObjName, OBJ_LABEL, 0, 0, 0);
      }
	    objSetXY(sObjName, pos_x, pos_y);
	    objSetText(sObjName, text, fontSize, col);
      ObjectSetString(0, sObjName, OBJPROP_FONT, fontName); 
	    objSetBack(sObjName, back);
	    objSetAngle(sObjName, angle);
	    objSetTF(sObjName, tf);
	    break;
  	case OBJ_ARROW:
  	    sObjName = getSlavePrefix(S_ARROW, sVarParam[2]);
  	    //ObjectCreate(sObjName, OBJ_ARROW, 0, 0, 0);
        if(ObjectFind(0, sObjName)<0){
    	    ObjectCreate(sObjName, OBJ_ARROW, 0, 0, 0);
        }
  	    objSetPos1(sObjName, t1, p1);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetArrowCode(sObjName, arrowCode);
  	    objSetTF(sObjName, tf);
  	    break;
  	    
  	case OBJ_FIBO:
  	    sObjName = getSlavePrefix(S_FIBO, sVarParam[2]);
  	    //ObjectCreate(sObjName, OBJ_FIBO, 0, 0, 0);
        if(ObjectFind(0, sObjName)<0){
    	    ObjectCreate(sObjName, OBJ_FIBO, 0, 0, 0);
        }
  	    objSetPos1(sObjName, t1, p1);
  	    objSetPos2(sObjName, t2, p2);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetRay(sObjName, ray);
  	    objSetLevelStyle(sObjName, levelWidth, levelStyle, levelCol);
  	    objSetTF(sObjName, tf);
  	    objSetFibo(sObjName, FIBOLEVELS,FiboLines);
  	    break;
  	    
  	case OBJ_EXPANSION:
  	    sObjName = getSlavePrefix(S_EXPANSION, sVarParam[2]);
  	    //ObjectCreate(sObjName, OBJ_EXPANSION, 0, 0, 0);
        if(ObjectFind(0, sObjName)<0){
    	    ObjectCreate(sObjName, OBJ_EXPANSION, 0, 0, 0);
        }
  	    objSetPos1(sObjName, t1, p1);
  	    objSetPos2(sObjName, t2, p2);
  	    objSetPos3(sObjName, t3, p3);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetRay(sObjName, ray);
  	    objSetLevelStyle(sObjName, levelWidth, levelStyle, levelCol);
  	    objSetTF(sObjName, tf);
  	    objSetFibo(sObjName, FIBOLEVELS,FiboLines);
  	    break;
  	case OBJ_FIBOCHANNEL:
  	    sObjName = getPrefix(S_FIBOCHANNEL, sVarParam[2]);
  	    //ObjectCreate(sObjName, OBJ_FIBOCHANNEL, 0, 0, 0);
        if(ObjectFind(0, sObjName)<0){
    	    ObjectCreate(sObjName, OBJ_FIBOCHANNEL, 0, 0, 0);
        }
  	    objSetPos1(sObjName, t1, p1);
  	    objSetPos2(sObjName, t2, p2);
  	    objSetPos3(sObjName, t3, p3);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetRay(sObjName, ray);
  	    objSetLevelStyle(sObjName, width/*levelWidth*/, style/*levelStyle*/, col /*levelCol*/);
  	    objSetTF(sObjName, tf);
  	    objSetFibo(sObjName, FIBOLEVELS,FiboLines);
  	    break;
  	case OBJ_FIBOFAN:
  	    sObjName = getPrefix(S_FIBOFAN, sVarParam[2]);
  	    //ObjectCreate(sObjName, OBJ_FIBOFAN, 0, 0, 0);
        if(ObjectFind(0, sObjName)<0){
    	    ObjectCreate(sObjName, OBJ_FIBOFAN, 0, 0, 0);
        }
  	    objSetPos1(sObjName, t1, p1);
  	    objSetPos2(sObjName, t2, p2);
  	    //objSetPos3(sObjName, t3, p3);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetLevelStyle(sObjName, levelWidth, levelStyle, levelCol);
  	    objSetTF(sObjName, tf);
  	    objSetFibo(sObjName, FIBOLEVELS,FiboLines);
  	    break;
  	case OBJ_CHANNEL:
  	    sObjName = getPrefix(S_CHANNEL, sVarParam[2]);
  	    //ObjectCreate(sObjName, OBJ_CHANNEL, 0, 0, 0);
        if(ObjectFind(0, sObjName)<0){
    	    ObjectCreate(sObjName, OBJ_CHANNEL, 0, 0, 0);
        }
  	    objSetPos1(sObjName, t1, p1);
  	    objSetPos2(sObjName, t2, p2);
  	    objSetPos3(sObjName, t3, p3);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetLevelStyle(sObjName, width/*levelWidth*/, style/*levelStyle*/, col /*levelCol*/);
  	    objSetTF(sObjName, tf);
  	    break;	  	    	    
  	default:
  	    break;
  	}
  }
    
  WindowRedraw();
}
//----------------------------------------------------------------------
void  ConvertStringToGlobalVariables(string string_clipboard)
{
  int loop = 0 ;
  int str_len=StringLen(string_clipboard);
  string string_tmp = string_clipboard;
  bool bDone=false;
  int position_name_found=0;
  int position_value_found=0;

  int position=0;
  while(position < str_len && !bDone){
    position_name_found = StringFind(string_clipboard, "__%%__", position);
    if(position_name_found < 0){
      bDone=true;
    }else{
      string variable_name = StringSubstr(string_clipboard, position, position_name_found - position);
      position = position_name_found + StringLen("__%%__");
      position_value_found = StringFind(string_clipboard, "\n", position);
      //if(loop < 10){
      //  MessageBox("variable_name: \n"+variable_name,"Clipboard");
      //  loop++;
      //}
      if(position_value_found < 0){
        bDone=true;
      }else{
        string variable_value = StringSubstr(string_clipboard, position, position_value_found - position);
        GlobalVariableSet(variable_name, variable_value);
        position = position_value_found + StringLen("\n");
        //if(loop < 10){
        //  MessageBox("variable_value: \n"+variable_value,"Clipboard");
        //  loop++;
        //}
      }
    }
  }
}
//----------------------------------------------------------------------

void start()
{
  //int ret = MessageBox("Object Copy?","Question",MB_YESNO|MB_ICONQUESTION);
  //if(ret==IDNO) PasteMode = true;
  if(StringFind(WindowExpertName(),"COPY")==-1) PasteMode = true;
    if(PasteMode){
    Print("Pasete");
      if(bClipBoardOnly){
        GlobalVariablesDeleteAll(sMasterPrefixOld);
        GlobalVariablesDeleteAll(sMasterPrefix);
      }

      string string_clipboard;
      string_clipboard = CopyTextFromClipboard();
      ConvertStringToGlobalVariables(string_clipboard);
      updateObjects();
      PlaySound("ok");
    }else{
      updateVars();
      PlaySound("tick");
  }
}