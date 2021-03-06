//+------------------------------------------------------------------+
//|                            00-Scr-ObjectCopier_COPY_Selected.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.1"  //2022/4/8

#include <WinAPI\winuser.mqh>
#include <WinAPI\winbase.mqh>

//#import "kernel32.dll"
//   int GlobalAlloc(int Flags, int Size);
//   int GlobalLock(int hMem);
//   int GlobalUnlock(int hMem);
//   int GlobalFree(int hMem);
//   int lstrcpyW(int ptrhMem, string Text);
//#import
#import "kernel32.dll"
string                 lstrcpyW(PVOID string1,const string string2);
string                 lstrcatW(PVOID string1,const string string2);
#import


//#import "user32.dll"
//   int OpenClipboard(int hOwnerWindow);
//   int EmptyClipboard();
//   int CloseClipboard();
//   int SetClipboardData(int Format, int hMem);
//#import

#define GMEM_MOVEABLE   2
#define CF_UNICODETEXT  13
//+------------------------------------------------------------------+
//|                                                                  |
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
    //Print("OpenClipboard:");
    //int hglb=GetClipboardData(CF_UNICODETEXT);
    HANDLE hglb=GetClipboardData(CF_UNICODETEXT);
    //HANDLE hglb=GetClipboardData(1 /*CF_TEXT*/);
      if(hglb!=0)      {
      //Print("hglb:"+hglb);
      //HANDLE hMem=GlobalAlloc(GMEM_MOVEABLE,lnString*2+2);
      PVOID lptstr=GlobalLock(hglb);
      //PVOID lptstr=GlobalLock(hglb);
      //if(lptstr!=0) { clip=lstrcatW(lptstr,""); GlobalUnlock(hglb); }
      if(lptstr!=0) {
        //lstrcpyW(clip, lptstr);
        clip=lstrcatW(lptstr,"");
        GlobalUnlock(hglb);
        //Print("clip:"+clip);
      }
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
//+------------------------------------------------------------------+
bool CopyTextToClipboard(string Text)
{
  bool bReturnvalue=false;
  
  // Try grabbing ownership of the clipboard 
  if(OpenClipboard(0)!=0)   {
    // Try emptying the clipboard
    if(EmptyClipboard()!=0)      {
      // Try allocating a block of global memory to hold the text 
      int lnString=StringLen(Text);
      
      HANDLE hMem=GlobalAlloc(GMEM_MOVEABLE,lnString*2+2);
      if(hMem!=0)       {
        // Try locking the memory, so that we can copy into it
        PVOID ptrMem=GlobalLock(hMem);
        if(ptrMem!=0)          {
          // Copy the string into the global memory
          lstrcpyW(ptrMem,Text);
          // Release ownership of the global memory (but don't discard it)
          GlobalUnlock(hMem);
  
          // Try setting the clipboard contents using the global memory
          if(SetClipboardData(CF_UNICODETEXT,hMem)!=0)           {
            // Okay
            bReturnvalue=true;
          }          else           {
          // Failed to set the clipboard using the global memory
            GlobalFree(hMem);
          }
        }        else           {
          // Meemory allocated but not locked
          GlobalFree(hMem);
        }
      }     else        {
        // Failed to allocate memory to hold string 
      }
    }  else    {
      // Failed to empty clipboard
    }
    // Always release the clipboard, even if the copy failed
    CloseClipboard();
  }  else  {
    // Failed to open clipboard
  }
  
  return (bReturnvalue);
}
//+------------------------------------------------------------------+
//----------------------------------------------------------------------
// Copies the specified text to the clipboard, returning true if successful
//----------------------------------------------------------------------
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
  //---
  init();
  startMQL4();
}
//+------------------------------------------------------------------+
//
//  "00-Scr-ObjectCopier_COPY_Selected.mq4"  -- read/write objects to/from global variable
//
//    Ver. 1.00  2008/9/26(Fri)
//
#property  copyright  "00"
#property  link       "http://www.mql4.com/"
//#include <WinUser32.mqh>
//#include <WinAPI/winuser.mqh>

#property script_show_inputs
//#property  show_confirm

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
//extern string sMasterPrefix   = "CP";  // prefix for global vars
//extern string sSlavePrefix   = "CP";  // prefix for global vars
string sMasterPrefix   = "CP";  // prefix for global vars
string sSlavePrefix   = "CP";  // prefix for global vars

extern double tUpdate         = 1.0;        // interval time in sec
input bool   bCopyTrend      = true;       // copy OBJ_TREND or not
input bool   bCopyRectangle  = true;       // copy OBJ_RECTANGLE or not
input bool   bCopyVLine      = true;       // copy OBJ_VLINE or not
input bool   bCopyHLine      = true;       // copy OBJ_HLINE or not
input bool   bCopyText       = false;       // copy OBJ_TEXT or not
input bool   bCopyArrow      = true;       // copy OBJ_ARROW or not
input bool   bCopyFibo       = true;       // copy OBJ_FIBO or not
input bool   bCopyExpansion  = true;       // copy OBJ_EXPANSION or not
input bool   bCopyFiboChannel= true;       // copy OBJ_FIBOCHANNEL or not
input bool   bCopyFiboFan    = true;       // copy OBJ_FIBOFAN or not
input bool   bCopyChannel    = true;       // copy OBJ_CHANNEL or not


//---- vars
string sScriptName      = "00-Scr-ObjectCopier";
string sScriptShortName = "00-OC";
string sMasterPrefixOld;
string sSlavePrefixOld;
extern bool   PasteMode = false;

//----------------------------------------------------------------------
//    ObjectSetText(sObjName, text, fontSize, "", col);
void ObjectSetText(string sObjName, string text, int fontSize, string text2, int col)
{
  ObjectSetInteger(0,sObjName, OBJPROP_FONTSIZE, fontSize);
  ObjectSetInteger(0,sObjName, OBJPROP_COLOR, col);
  ObjectSetString(0,sObjName, OBJPROP_FONT, text2);
  ObjectSetString(0,sObjName, OBJPROP_TEXT, text);
}

//----------------------------------------------------------------------
//StringGetChar(sObjStr,StringLen(sObjStr)-1);
ushort StringGetChar(string sObjStr, int pos)
{
  return StringGetCharacter(sObjStr, pos);
}
//----------------------------------------------------------------------
void init()
//void OnInit()
{
  //sMasterPrefixOld = StringConcatenate(sScriptName, "-", sMasterPrefix);
  //sMasterPrefix = StringConcatenate(sScriptShortName, "-", sMasterPrefix);
  //sSlavePrefixOld = StringConcatenate(sScriptName, "-", sSlavePrefix);
  //sSlavePrefix = StringConcatenate(sScriptShortName, "-", sSlavePrefix);

  GlobalVariablesDeleteAll(sMasterPrefixOld);
  GlobalVariablesDeleteAll(sMasterPrefix);

  StringConcatenate(sMasterPrefixOld, sScriptName, "-", sMasterPrefix);
  StringConcatenate(sMasterPrefix, sScriptShortName, "-", sMasterPrefix);
  StringConcatenate(sSlavePrefixOld, sScriptName, "-", sSlavePrefix);
  StringConcatenate(sSlavePrefix, sScriptShortName, "-", sSlavePrefix);
  //Print ("init sMasterPrefix"+sMasterPrefix );

  //StringAdd(sMasterPrefixOld, sScriptName, "-", sMasterPrefix);
  //StringAdd(sMasterPrefix, sScriptShortName, "-", sMasterPrefix);
  //StringAdd(sSlavePrefixOld, sScriptName, "-", sSlavePrefix);
  //StringAdd(sSlavePrefix, sScriptShortName, "-", sSlavePrefix);
}
//----------------------------------------------------------------------
//void deinit()
void OnDeinit(const int reason)
{
  if(PasteMode){
    GlobalVariablesDeleteAll(sMasterPrefixOld);
    GlobalVariablesDeleteAll(sMasterPrefix);
  }
}

//----------------------------------------------------------------------
//int getObjType(string sParam[])
int getObjType(string &sParam[])
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
    //Print ("found hline");
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
  //Print("master="+sMasterPrefix);

  string str_tmp="";
  StringConcatenate(str_tmp, sMasterPrefix, " ", type, " ", sObjStr);
  return(str_tmp);
}
//----------------------------------------------------------------------
string getSlavePrefix(string type, string sObjStr)
{
  int i=0;
  sObjStr = strSPACEdecode(sObjStr);
  //return(StringConcatenate(sSlavePrefix, " ", type, " ", sObjStr));
  if(ObjectFind(0, sObjStr) ==-1) return(sObjStr);

  //for(i=0;i<128;i++){
  //  int ch = StringGetChar(sObjStr,StringLen(sObjStr)-1);
  //  if(ch>=48 && ch<=57){
  //     sObjStr = StringSubstr(sObjStr,0,StringLen(sObjStr)-2);
  //  }else{break;}
  //}
  //i = 0;
  //while(ObjectFind(0, sObjStr+i) !=-1){
  //  i++;
  //}
  //return(sObjStr+i);

  i = 0;
  while(ObjectFind(0,sObjStr+"_"+i) !=-1 && i < 128){
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
    string s;
    StringConcatenate(s, sVarName, " t1");
    GlobalVariableSet(s, t1);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetPrice1(string sVarName, double p1)
{
    string s;
    StringConcatenate(s, sVarName, " p1");
    GlobalVariableSet(s, p1);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetColor(string sVarName, color col)
{
    string s;
    StringConcatenate(s, sVarName, " color");
    GlobalVariableSet(s, col);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetPos1(string sVarName, double t, double p)
{
    string s = "";
    
    StringConcatenate(s,s, varSetTime1(sVarName, t));
    StringConcatenate(s,s, varSetPrice1(sVarName, p));
    
    return(s);
}

//----------------------------------------------------------------------
string varSetPos2(string sVarName, double t, double p)
{
    string s1;
    StringConcatenate(s1, sVarName, " t2");
    string s2;
    StringConcatenate(s2,sVarName, " p2");
    
    GlobalVariableSet(s1, t);
    GlobalVariableSet(s2, p);
    
    return(s1 + s2);
}

//----------------------------------------------------------------------
string varSetPos3(string sVarName, double t, double p)
{
    string s1;
    StringConcatenate(s1, sVarName, " t3");
    string s2;
    StringConcatenate(s2, sVarName, " p3");
    
    GlobalVariableSet(s1, t);
    GlobalVariableSet(s2, p);
    
    return(s1 + s2);
}

//----------------------------------------------------------------------
string varSetStyle(string sVarName, int width, int style, color col)
{
    string s1;
    StringConcatenate(s1, sVarName, " width");
    string s2;
    StringConcatenate(s2, sVarName, " style");
    
    GlobalVariableSet(s1, width);
    GlobalVariableSet(s2, style);
    string s = s1 + s2;
    s = s + varSetColor(sVarName, col);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetLevelColor(string sVarName, color levelCol)
{
    string s;
    StringConcatenate(s, sVarName, " levelColor");
    GlobalVariableSet(s, levelCol);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetLevelStyle(string sVarName, int levelWidth, int levelStyle, color levelCol)
{
    string s1;
    StringConcatenate(s1, sVarName, " levelWidth");
    string s2;
    StringConcatenate(s2, sVarName, " levelStyle");
    
    GlobalVariableSet(s1, levelWidth);
    GlobalVariableSet(s2, levelStyle);
    string s = s1 + s2;
    s = s + varSetLevelColor(sVarName, levelCol);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetRay(string sVarName, int ray)
{
    string s;
    StringConcatenate(s, sVarName, " ray");
    GlobalVariableSet(s, ray);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetBack(string sVarName, int back)
{
    string s;
    StringConcatenate(s,sVarName, " back");
    GlobalVariableSet(s, back);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetAngle(string sVarName, double angle)
{
    string s;
    StringConcatenate(s, sVarName, " angle");
    GlobalVariableSet(s, angle);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetScale(string sVarName, double scale)
{
    string s;
    StringConcatenate(s, sVarName, " scale");
    GlobalVariableSet(s, scale);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetArrowCode(string sVarName, int arrowCode)
{
    string s;
    StringConcatenate(s, sVarName, " arrowCode");
    GlobalVariableSet(s, arrowCode);
    
    return(s);
}

//----------------------------------------------------------------------
string varSetText(string sVarName, string text, int fontSize, color col)
{
    string s1;
    StringConcatenate(s1, sVarName, " text ", text);
    string s2;
    StringConcatenate(s2, sVarName, " fontSize");
    GlobalVariableSet(s1, 0);
    GlobalVariableSet(s2, fontSize);
    string s;
    StringConcatenate(s,s1, s2);
    StringConcatenate(s,s, varSetColor(sVarName, col));
    
    return(s);
}
string varSetTF(string sVarName, int tf)
{
    string s;
    StringConcatenate(s, sVarName, " tf");
    GlobalVariableSet(s, tf);
    
    return(s);
}
string varSetFibo(string sVarName, int FIBOLEVELS,double &FiboLines[])
{
    //if(FIBOLEVELS==0) return("");
    string s;
    StringConcatenate(s, sVarName, " fl");
    GlobalVariableSet(s, FIBOLEVELS);   
    for(int i=0;i<FIBOLEVELS;i++)
    {
    string t;
    StringConcatenate(t, sVarName, " f",i);
    GlobalVariableSet(t, FiboLines[i]);
    StringConcatenate(s,s, t);
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
  	iChar = GlobalVariableGet(sVarPrefix+" text"+str_idx);
    text_local=text_local+ShortToString(iChar);
    //Print (iChar);
  }
  //Print(text_local);
  return(text_local);
}
//----------------------------------------------------------------------
//----------------------------------------------------------------------
string varGetFontName(string sVarPrefix, int length)
{
  //int nVar = GlobalVariablesTotal();
  int iChar=0;
  string text_local="";

  //Print ("fn_len="+length);
  for(int str_idx = 0 ; str_idx < length ; str_idx++){
  	iChar = GlobalVariableGet(sVarPrefix+" fn"+str_idx);
    text_local=text_local+ShortToString(iChar);
  }
  return(text_local);
}
//----------------------------------------------------------------------

//----------------------------------------------------------------------
string varGetTextOld(string sVarPrefix)
{
    string text;
    int nVar = GlobalVariablesTotal();
    
    for (int jVar = 0; jVar < nVar; jVar++) {
	string sVarName = GlobalVariableName(jVar);
	int x = StringFind(sVarName, sVarPrefix);
	if (x >= 0) {
	    text = StringSubstr(sVarName, x + StringLen(sVarPrefix));
	}
    }
    
    return(text);
}

//----------------------------------------------------------------------
void objSetTime1(string sObjName, datetime t)
{
    //ObjectSet(sObjName, OBJPROP_TIME1,  t);
    ObjectSetInteger(0, sObjName, OBJPROP_TIME,0,   t);
}

//----------------------------------------------------------------------
void objSetPrice1(string sObjName, double p)
{
    //ObjectSet(sObjName, OBJPROP_PRICE1, p);
    ObjectSetDouble(0, sObjName, OBJPROP_PRICE,0, p);
}
//----------------------------------------------------------------------
void objSetXY(string sObjName, int x, int y)
{
    ObjectSetInteger(0, sObjName, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, sObjName, OBJPROP_YDISTANCE, y);
}
//----------------------------------------------------------------------

//----------------------------------------------------------------------
void objSetPos1(string sObjName, datetime t, double p)
{
    objSetTime1(sObjName, t);
    objSetPrice1(sObjName, p);
}

//----------------------------------------------------------------------
void objSetPos2(string sObjName, datetime t, double p)
{
    ObjectSetInteger(0, sObjName, OBJPROP_TIME,1,  t);
    ObjectSetDouble(0,sObjName, OBJPROP_PRICE,1, p);
}

//----------------------------------------------------------------------
void objSetPos3(string sObjName, datetime t, double p)
{
    ObjectSetInteger(0,sObjName, OBJPROP_TIME,2,  t);
    ObjectSetDouble(0,sObjName, OBJPROP_PRICE,2, p);
}

//----------------------------------------------------------------------
void objSetStyle(string sObjName, int width, int style, color col)
{
    ObjectSetInteger(0,sObjName, OBJPROP_WIDTH, width);
    ObjectSetInteger(0,sObjName, OBJPROP_STYLE, style);
    ObjectSetInteger(0,sObjName, OBJPROP_COLOR, col);
}

//----------------------------------------------------------------------
void objSetLevelStyle(string sObjName, int levelWidth, int levelStyle, color levelCol)
{
    ObjectSetInteger(0,sObjName, OBJPROP_LEVELWIDTH, levelWidth);
    ObjectSetInteger(0,sObjName, OBJPROP_LEVELSTYLE, levelStyle);
    ObjectSetInteger(0,sObjName, OBJPROP_LEVELCOLOR, levelCol);
}

//----------------------------------------------------------------------
void objSetRay(string sObjName, int ray)
{
    ObjectSetInteger(0, sObjName, OBJPROP_RAY, ray);
}

//----------------------------------------------------------------------
void objSetBack(string sObjName, int back)
{
    ObjectSetInteger(0, sObjName, OBJPROP_BACK, back);
}

//----------------------------------------------------------------------
void objSetAngle(string sObjName, double angle)
{
    ObjectSetDouble(0,sObjName, OBJPROP_ANGLE, angle);
}

//----------------------------------------------------------------------
void objSetScale(string sObjName, double scale)
{
    ObjectSetDouble(0, sObjName, OBJPROP_SCALE, scale);
}

//----------------------------------------------------------------------
void objSetArrowCode(string sObjName, int arrowCode)
{
    ObjectSetInteger(0, sObjName, OBJPROP_ARROWCODE, arrowCode);
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
    ObjectSetInteger(0,sObjName, OBJPROP_TIMEFRAMES, tf);
}
//----------------------------------------------------------------------
void objSetFibo(string sObjName, int FIBOLEVELS,double &FiboLines[])
{
    ObjectSetInteger(0, sObjName, OBJPROP_LEVELS, FIBOLEVELS);   
    if(FIBOLEVELS>0){
      for(int i=0;i<FIBOLEVELS;i++){
         //ObjectSet(sObjName,OBJPROP_FIRSTLEVEL+i,FiboLines[i]);
         ObjectSetDouble(0,sObjName,OBJPROP_LEVELVALUE,i,FiboLines[i]);
         //ObjectSetFiboDescription(sObjName,i,DoubleToString(FiboLines[i]*100,1));//%$
         ObjectSetString(0,sObjName,OBJPROP_LEVELTEXT,i,DoubleToString(100*FiboLines[i],1));
      }
    }
}
//----------------------------------------------------------------------
string strChConv(string s, int ch = '_')
{
    int len = StringLen(s);
    
    for (int i = 0; i < len; i++) {
	if (StringGetChar(s, i) == ' ') {
	    s = StringSetCharacter(s, i, ch);
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
    //Print ("loop:"+loop);
    string s = str;
    //Print ("s0:"+s);

    for (; ;) {
      //s = StringTrimLeft(s);
      StringTrimLeft(s);
      //Print ("s1:"+s);
      int len = StringLen(s);
      //Print ("len:"+len);
      if (len <= 0) {
        break;
      }
  
      int x = StringFind(s, " ");
      //Print ("x:"+x);
      string w;
      if (x > 0) {
        w = StringSubstr(s, 0, x);
        s = StringSubstr(s, x + 1);
        //Print ("w:"+w);
        //Print ("s:"+s);
      } else {
        w = s;
        s = "";
        //Print ("w2:"+w);
        //Print ("s2:"+s);
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
  int type = ObjectGetInteger(0, sObjName, OBJPROP_TYPE, 0);
  string sObjStr = strSPACEencode(sObjName);
  string sVarName;

  int IsSelected = ObjectGetInteger(
      0,         // チャートID
      sObjName,      // オブジェクト名
      OBJPROP_SELECTED,          // プロパティID
      0);

  if(IsSelected == 0){
    // if the object is not selected then return
    return(sAll);
  }

  datetime t1         = ObjectGetInteger(0,sObjName, OBJPROP_TIME, 0);
  double   p1         = ObjectGetDouble(0,sObjName, OBJPROP_PRICE,0);
  datetime t2         = ObjectGetInteger(0,sObjName, OBJPROP_TIME,1);
  double   p2         = ObjectGetDouble(0,sObjName, OBJPROP_PRICE,1);
  datetime t3         = ObjectGetInteger(0,sObjName, OBJPROP_TIME,2);
  double   p3         = ObjectGetDouble(0,sObjName, OBJPROP_PRICE,2);
  int      width      = ObjectGetInteger(0,sObjName, OBJPROP_WIDTH);
  int      style      = ObjectGetInteger(0,sObjName, OBJPROP_STYLE);
  int      ray        = ObjectGetInteger(0,sObjName, OBJPROP_RAY);
  int      back       = ObjectGetInteger(0,sObjName, OBJPROP_BACK);
  color    col        = ObjectGetInteger(0,sObjName, OBJPROP_COLOR);
  int      fontSize   = ObjectGetInteger(0,sObjName, OBJPROP_FONTSIZE);
  double   angle      = ObjectGetDouble(0,sObjName, OBJPROP_ANGLE);
  double   scale      = ObjectGetDouble(0,sObjName, OBJPROP_SCALE);
  int      levelWidth = ObjectGetInteger(0,sObjName, OBJPROP_LEVELWIDTH);
  int      levelStyle = ObjectGetInteger(0,sObjName, OBJPROP_LEVELSTYLE);
  color    levelCol   = ObjectGetInteger(0,sObjName, OBJPROP_LEVELCOLOR);
  int      arrowCode  = ObjectGetInteger(0,sObjName, OBJPROP_ARROWCODE);
  int      TIMEFRAMES = ObjectGetInteger(0,sObjName, OBJPROP_TIMEFRAMES);
  int      FIBOLEVELS = ObjectGetInteger(0,sObjName, OBJPROP_LEVELS);
  double FiboLines[32];

  //Print("FIBOLEVELS=",FIBOLEVELS);
  if(FIBOLEVELS>0){
    for(int i=0;i<FIBOLEVELS;i++){
      //FiboLines[i] = ObjectGetInteger(0, sObjName,OBJPROP_FIRSTLEVEL+i);
      FiboLines[i] = ObjectGetDouble(0, sObjName,OBJPROP_LEVELVALUE, i);
      //Print("FiboLines[",i,"]",FiboLines[i]);
    }
  }
    
  switch (type) {
  case OBJ_TREND:
	if (bCopyTrend) {
	    if (isValidPos12(t1, p1, t2, p2)) {
		sVarName = getPrefix(S_TREND, sObjStr);
		StringConcatenate(sAll,sAll, varSet(sVarName));
		StringConcatenate(sAll,sAll, varSetPos1(sVarName, t1, p1));
		StringConcatenate(sAll,sAll, varSetPos2(sVarName, t2, p2));
		StringConcatenate(sAll,sAll, varSetStyle(sVarName, width, style, col));
		StringConcatenate(sAll,sAll, varSetRay(sVarName, ray));
		StringConcatenate(sAll,sAll, varSetBack(sVarName, back));
		StringConcatenate(sAll,sAll, varSetTF(sVarName, TIMEFRAMES));
	    }
	}
	break;
	
    case OBJ_RECTANGLE:
	if (bCopyRectangle) {
	    if (isValidPos12(t1, p1, t2, p2)) {
		sVarName = getPrefix(S_RECTANGLE, sObjStr);
		StringConcatenate(sAll,sAll, varSet(sVarName));
		StringConcatenate(sAll,sAll, varSetPos1(sVarName, t1, p1));
		StringConcatenate(sAll,sAll, varSetPos2(sVarName, t2, p2));
		StringConcatenate(sAll,sAll, varSetStyle(sVarName, width, style, col));
		StringConcatenate(sAll,sAll, varSetBack(sVarName, back));
		StringConcatenate(sAll,sAll, varSetTF(sVarName, TIMEFRAMES));
	    }
	}
	break;
	
    case OBJ_VLINE:
	if (bCopyVLine) {
	    if (isValidTime(t1)) {
		sVarName = getPrefix(S_VLINE, sObjStr);
		StringConcatenate(sAll,sAll, varSet(sVarName));
		StringConcatenate(sAll,sAll, varSetTime1(sVarName, t1));
		StringConcatenate(sAll,sAll, varSetStyle(sVarName, width, style, col));
		StringConcatenate(sAll,sAll, varSetBack(sVarName, back));
		StringConcatenate(sAll,sAll, varSetTF(sVarName, TIMEFRAMES));
	    }
	}
	break;
	
  case OBJ_HLINE:
	if (bCopyHLine) {
    if (isValidPrice(p1)) {
      sVarName = getPrefix(S_HLINE, sObjStr);
      //Print("sObjStr="+sObjStr);
      //Print("sVarName="+sVarName);
      StringAdd(sAll, varSet(sVarName));
      //Print("sAll="+sAll);
      StringAdd(sAll, varSetPrice1(sVarName, p1));
      //Print("sAll="+sAll);
      StringAdd(sAll, varSetStyle(sVarName, width, style, col));
      //Print("sAll="+sAll);
      StringAdd(sAll, varSetBack(sVarName, back));
      //Print("sAll="+sAll);
      StringAdd(sAll, varSetTF(sVarName, TIMEFRAMES));

      //StringConcatenate(sAll,sAll, varSet(sVarName));
      //StringConcatenate(sAll,sAll, varSetPrice1(sVarName, p1));
      //StringConcatenate(sAll,sAll, varSetStyle(sVarName, width, style, col));
      //StringConcatenate(sAll,sAll, varSetBack(sVarName, back));
      //StringConcatenate(sAll,sAll, varSetTF(sVarName, TIMEFRAMES));
      //Print("HLINE="+sAll);
    }
	}
	break;
	
    case OBJ_TEXT:
	if (bCopyText) {
	    if (isValidPos1(t1, p1)) {
		sVarName = getPrefix(S_TEXT, sObjStr);
		StringConcatenate(sAll,sAll, varSet(sVarName));
		StringConcatenate(sAll,sAll, varSetPos1(sVarName, t1, p1));
		//string text = ObjectDescription(sObjName);
		string text = ObjectGetString(0,sObjName, OBJPROP_TEXT,0);
		StringConcatenate(sAll,sAll, varSetText(sVarName, text, fontSize, col));
		StringConcatenate(sAll,sAll, varSetBack(sVarName, back));
		StringConcatenate(sAll,sAll, varSetAngle(sVarName, angle));
		StringConcatenate(sAll,sAll, varSetTF(sVarName, TIMEFRAMES));
	    }
	}
	break;
	
    case OBJ_ARROW:
	if (bCopyArrow) {
	    if (isValidPos1(t1, p1)) {
		sVarName = getPrefix(S_ARROW, sObjStr);
		StringConcatenate(sAll,sAll, varSet(sVarName));
		StringConcatenate(sAll,sAll, varSetPos1(sVarName, t1, p1));
		StringConcatenate(sAll,sAll, varSetStyle(sVarName, width, style, col));
		StringConcatenate(sAll,sAll, varSetBack(sVarName, back));
		StringConcatenate(sAll,sAll, varSetArrowCode(sVarName, arrowCode));
		StringConcatenate(sAll,sAll, varSetTF(sVarName, TIMEFRAMES));
	    }
	}
	break;
	
    case OBJ_FIBO:
	if (bCopyFibo) {
	    if (isValidPos12(t1, p1, t2, p2)) {
		sVarName = getPrefix(S_FIBO, sObjStr);
		StringConcatenate(sAll,sAll, varSet(sVarName));
		StringConcatenate(sAll,sAll, varSetPos1(sVarName, t1, p1));
		StringConcatenate(sAll,sAll, varSetPos2(sVarName, t2, p2));
		StringConcatenate(sAll,sAll, varSetStyle(sVarName, width, style, col));
		StringConcatenate(sAll,sAll, varSetRay(sVarName, ray));
		StringConcatenate(sAll,sAll, varSetBack(sVarName, back));
		StringConcatenate(sAll,sAll, varSetLevelStyle(sVarName, levelWidth, levelStyle, levelCol));
		StringConcatenate(sAll,sAll, varSetTF(sVarName, TIMEFRAMES));
		StringConcatenate(sAll,sAll, varSetFibo(sVarName,FIBOLEVELS,FiboLines));
	    }
	}
	break;
	
    case OBJ_EXPANSION:
	if (bCopyExpansion) {
	    if (isValidPos123(t1, p1, t2, p2, t3, p3)) {
		sVarName = getPrefix(S_EXPANSION, sObjStr);
		StringConcatenate(sAll,sAll, varSet(sVarName));
		StringConcatenate(sAll,sAll, varSetPos1(sVarName, t1, p1));
		StringConcatenate(sAll,sAll, varSetPos2(sVarName, t2, p2));
		StringConcatenate(sAll,sAll, varSetPos3(sVarName, t3, p3));
		StringConcatenate(sAll,sAll, varSetStyle(sVarName, width, style, col));
		StringConcatenate(sAll,sAll, varSetBack(sVarName, back));
		StringConcatenate(sAll,sAll, varSetRay(sVarName, ray));
		StringConcatenate(sAll,sAll, varSetLevelStyle(sVarName, levelWidth, levelStyle, levelCol));
		StringConcatenate(sAll,sAll, varSetTF(sVarName, TIMEFRAMES));
		StringConcatenate(sAll,sAll, varSetFibo(sVarName,FIBOLEVELS,FiboLines));
	    }
	}
	break;
    case OBJ_FIBOCHANNEL:
	if (bCopyFiboChannel) {
	    if (isValidPos123(t1, p1, t2, p2, t3, p3)) {
		sVarName = getPrefix(S_FIBOCHANNEL, sObjStr);
		StringConcatenate(sAll,sAll, varSet(sVarName));
		StringConcatenate(sAll,sAll, varSetPos1(sVarName, t1, p1));
		StringConcatenate(sAll,sAll, varSetPos2(sVarName, t2, p2));
		StringConcatenate(sAll,sAll, varSetPos3(sVarName, t3, p3));
		StringConcatenate(sAll,sAll, varSetStyle(sVarName, width, style, col));
		StringConcatenate(sAll,sAll, varSetBack(sVarName, back));
		StringConcatenate(sAll,sAll, varSetRay(sVarName, ray));
		StringConcatenate(sAll,sAll, varSetLevelStyle(sVarName, levelWidth, levelStyle, levelCol));
		StringConcatenate(sAll,sAll, varSetTF(sVarName, TIMEFRAMES));
		StringConcatenate(sAll,sAll, varSetFibo(sVarName,FIBOLEVELS,FiboLines));
		
	    }
	}
	break;	
    case OBJ_FIBOFAN:
	if (bCopyFiboFan) {
	    if (isValidPos12(t1, p1, t2, p2)) {
		sVarName = getPrefix(S_FIBOFAN, sObjStr);
		StringConcatenate(sAll,sAll, varSet(sVarName));
		StringConcatenate(sAll,sAll, varSetPos1(sVarName, t1, p1));
		StringConcatenate(sAll,sAll, varSetPos2(sVarName, t2, p2));
		StringConcatenate(sAll,sAll, varSetStyle(sVarName, width, style, col));
		StringConcatenate(sAll,sAll, varSetBack(sVarName, back));
		StringConcatenate(sAll,sAll, varSetLevelStyle(sVarName, levelWidth, levelStyle, levelCol));
		StringConcatenate(sAll,sAll, varSetTF(sVarName, TIMEFRAMES));
		StringConcatenate(sAll,sAll, varSetFibo(sVarName,FIBOLEVELS,FiboLines));
	    }
	}
	break;
    case OBJ_CHANNEL:
	if (bCopyChannel) {
	    if (isValidPos123(t1, p1, t2, p2, t3, p3)) {
		sVarName = getPrefix(S_CHANNEL, sObjStr);
		StringConcatenate(sAll,sAll, varSet(sVarName));
		StringConcatenate(sAll,sAll, varSetPos1(sVarName, t1, p1));
		StringConcatenate(sAll,sAll, varSetPos2(sVarName, t2, p2));
		StringConcatenate(sAll,sAll, varSetPos3(sVarName, t3, p3));
		StringConcatenate(sAll,sAll, varSetStyle(sVarName, width, style, col));
		StringConcatenate(sAll,sAll, varSetBack(sVarName, back));
		StringConcatenate(sAll,sAll, varSetLevelStyle(sVarName, levelWidth, levelStyle, levelCol));
		StringConcatenate(sAll,sAll, varSetTF(sVarName, TIMEFRAMES));

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
  
  int nObj = ObjectsTotal(0,0,-1);
  for (i = 0; i < nObj; i++) {
    string sObjName = ObjectName(0,i, 0, -1);
    if (StringFind(sObjName, sSlavePrefix) >= 0) {
      continue;
    }	
    if(ObjectFind(0,sObjName) == 0 ) {
        // only copy objs in main chart (window 0)
        StringConcatenate(sAll,sAll,writeGlobalVar(sObjName));
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
    int nObj = ObjectsTotal(0,0,-1);
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
	    //Print("sVarName:"+sVarName);
	    //Print("sSlavePrefix:"+sSlavePrefix);
  	if (StringFind(sVarName, sSlavePrefix) < 0) {
  	    //Print("String not found");
  	    continue;
  	}
    //Print("String  found");
  	int n = strSplit(sVarName, sVarParam);
    //Print("after Split");
  	if (n != 3) {
  	    continue;
  	}
    //Print("after Split2");
  	int type = getObjType(sVarParam);
    //Print("type:"+type);
  	//int pos_x         = GlobalVariableGet(StringConcatenate(sVarName, " x"));
  	//int pos_y         = GlobalVariableGet(StringConcatenate(sVarName, " y"));


  	string sVarName_tmp;

  	StringConcatenate(sVarName_tmp,sVarName, " x");
  	int pos_x           = GlobalVariableGet(sVarName_tmp);

  	StringConcatenate(sVarName_tmp,sVarName, " y");
  	int pos_y           = GlobalVariableGet(sVarName_tmp);

  	StringConcatenate(sVarName_tmp,sVarName, " t1");
  	datetime t1         = GlobalVariableGet(sVarName_tmp);

  	StringConcatenate(sVarName_tmp,sVarName, " p1");
  	double   p1         = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " t2");
  	datetime t2         = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " p2");
  	double   p2         = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " t3");
  	datetime t3         = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " p3");
  	double   p3         = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " width");
  	int      width      = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " style");
  	int      style      = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " ray");
  	int      ray        = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " back");
  	int      back       = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " color");
  	color    col        = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " fontSize");
  	int      fontSize   = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " angle");
  	double   angle      = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " scale");
  	double   scale      = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " levelWidth");
  	int      levelWidth = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " levelStyle");
  	int      levelStyle = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " levelColor");
  	color    levelCol   = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " arrowCode");
  	int      arrowCode  = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " tf");
  	int      tf         = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " tftype");
  	int      tftype         = GlobalVariableGet(sVarName_tmp);
  	StringConcatenate(sVarName_tmp,sVarName, " fl");
  	int      FIBOLEVELS = GlobalVariableGet(sVarName_tmp);

    //if(tftype==4 && tf==0) tf=OBJ_ALL_PERIODS;

    int tf_tmp=0;
    if(tftype == 4){
      if(tf==0x01FF || tf==0){
        tf_tmp=OBJ_ALL_PERIODS;
      }else if(tf == -1){
        tf_tmp=OBJ_NO_PERIODS;
      }else{
        if(tf&0x0001){
          tf_tmp |= OBJ_PERIOD_M1;
        }
        if(tf&0x0002){
          tf_tmp |= OBJ_PERIOD_M5;
        }
        if(tf&0x0004){
          tf_tmp |= OBJ_PERIOD_M15;
        }
        if(tf&0x0008){
          tf_tmp |= OBJ_PERIOD_M30;
        }
        if(tf&0x0010){
          tf_tmp |= OBJ_PERIOD_H1;
        }
        if(tf&0x0020){
          tf_tmp |= OBJ_PERIOD_H4;
        }
        if(tf&0x0040){
          tf_tmp |= OBJ_PERIOD_D1;
        }
        if(tf&0x0080){
          tf_tmp |= OBJ_PERIOD_W1;
        }
        if(tf&0x0100){
          tf_tmp |= OBJ_PERIOD_MN1;
        }
      }
      tf=tf_tmp;
    }

  	//int      text_len   = GlobalVariableGet(StringConcatenate(sVarName, " textlen"));
  	StringConcatenate(sVarName_tmp,sVarName, " textlen");
  	int text_len = GlobalVariableGet(sVarName_tmp);

    //int      fontname_len   = GlobalVariableGet(StringConcatenate(sVarName, " fnlen"));
  	StringConcatenate(sVarName_tmp,sVarName, " fnlen");
  	int fontname_len = GlobalVariableGet(sVarName_tmp);
  	
    double FiboLines[32];
    if(FIBOLEVELS>0){
      for(int i=0;i<FIBOLEVELS;i++){
        FiboLines[i] = GlobalVariableGet(StringConcatenate(sVarName, " f",i));
      }
  	}
    string text_tmp="";
  	string   text="";
  	string fontName="";
  	
  	switch (type) {
  	    
  	case OBJ_TREND:
  	    sObjName = getSlavePrefix(S_TREND, sVarParam[2]);
  	    ObjectCreate(0,sObjName, OBJ_TREND, 0, 0, 0);
  	    objSetPos1(sObjName, t1, p1);
  	    objSetPos2(sObjName, t2, p2);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetRay(sObjName, ray);
  	    objSetBack(sObjName, back);
  	    objSetTF(sObjName, tf);
        ObjectSetInteger(0,sObjName, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0,sObjName, OBJPROP_HIDDEN, false);
  	    break;
  	    
  	case OBJ_RECTANGLE:
  	    sObjName = getSlavePrefix(S_RECTANGLE, sVarParam[2]);
  	    ObjectCreate(0,sObjName, OBJ_RECTANGLE, 0, 0, 0);
  	    objSetPos1(sObjName, t1, p1);
  	    objSetPos2(sObjName, t2, p2);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetTF(sObjName, tf);
        ObjectSetInteger(0,sObjName, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0,sObjName, OBJPROP_HIDDEN, false);
  	    break;
  	    
  	case OBJ_VLINE:
  	    sObjName = getSlavePrefix(S_VLINE, sVarParam[2]);
  	    ObjectCreate(0,sObjName, OBJ_VLINE, 0, 0, 0);
  	    objSetPos1(sObjName, t1, p1);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetTF(sObjName, tf);
        ObjectSetInteger(0,sObjName, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0,sObjName, OBJPROP_HIDDEN, false);
  	    break;
  	    
  	case OBJ_HLINE:
  	    sObjName = getSlavePrefix(S_HLINE, sVarParam[2]);
  	    ObjectCreate(0,sObjName, OBJ_HLINE, 0, 0, 0);
  	    objSetPos1(sObjName, t1, p1);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetTF(sObjName, tf);
        ObjectSetInteger(0,sObjName, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0,sObjName, OBJPROP_HIDDEN, false);
  	    break;
  	    
  	case OBJ_TEXT:
  	    //StringConcatenate(text_tmp, sVarName, " text");
  	    text     = varGetText(text_tmp, text_len);
  	    fontName = varGetFontName(sVarName, fontname_len);
  	    sObjName = getSlavePrefix(S_TEXT, sVarParam[2]);
        if(ObjectFind(0, sObjName)<0){
    	    ObjectCreate(0,sObjName, OBJ_TEXT, 0, 0, 0);
        }

  	    //ObjectCreate(0,sObjName, OBJ_TEXT, 0, 0, 0);
  	    objSetPos1(sObjName, t1, p1);
  	    objSetText(sObjName, text, fontSize, col);
        ObjectSetString(0, sObjName, OBJPROP_FONT, fontName); 
  	    objSetBack(sObjName, back);
  	    objSetAngle(sObjName, angle);
  	    objSetTF(sObjName, tf);
        ObjectSetInteger(0,sObjName, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0,sObjName, OBJPROP_HIDDEN, false);
  	    break;
  	case OBJ_LABEL:
  	  //Print("debug here label");
	    //text     = varGetText(StringConcatenate(sVarName, " text"));
	    text     = varGetText(sVarName, text_len);
      //Print (text);
	    fontName = varGetFontName(sVarName, fontname_len);
      //Print (fontName);
	    sObjName = getSlavePrefix(S_LABEL, sVarParam[2]);
	    //ObjectCreate(sObjName, OBJ_TEXT, 0, 0, 0);
      if(ObjectFind(0, sObjName)<0){
  	    ObjectCreate(0,sObjName, OBJ_LABEL, 0, 0, 0);
      }
	    objSetXY(sObjName, pos_x, pos_y);
	    objSetText(sObjName, text, fontSize, col);
      ObjectSetString(0, sObjName, OBJPROP_FONT, fontName); 
	    objSetBack(sObjName, back);
	    objSetAngle(sObjName, angle);
	    objSetTF(sObjName, tf);
      ObjectSetInteger(0,sObjName, OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0,sObjName, OBJPROP_HIDDEN, false);
	    break;
  	    
  	case OBJ_ARROW:
  	    sObjName = getSlavePrefix(S_ARROW, sVarParam[2]);
  	    ObjectCreate(0,sObjName, OBJ_ARROW, 0, 0, 0);
  	    objSetPos1(sObjName, t1, p1);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetArrowCode(sObjName, arrowCode);
  	    objSetTF(sObjName, tf);
        ObjectSetInteger(0,sObjName, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0,sObjName, OBJPROP_HIDDEN, false);
  	    break;
  	    
  	case OBJ_FIBO:
  	    sObjName = getSlavePrefix(S_FIBO, sVarParam[2]);
  	    ObjectCreate(0,sObjName, OBJ_FIBO, 0, 0, 0);
  	    objSetPos1(sObjName, t1, p1);
  	    objSetPos2(sObjName, t2, p2);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetRay(sObjName, ray);
  	    objSetLevelStyle(sObjName, levelWidth, levelStyle, levelCol);
  	    objSetTF(sObjName, tf);
  	    objSetFibo(sObjName, FIBOLEVELS,FiboLines);
        ObjectSetInteger(0,sObjName, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0,sObjName, OBJPROP_HIDDEN, false);
  	    break;
  	    
  	case OBJ_EXPANSION:
  	    sObjName = getSlavePrefix(S_EXPANSION, sVarParam[2]);
  	    ObjectCreate(0,sObjName, OBJ_EXPANSION, 0, 0, 0);
  	    objSetPos1(sObjName, t1, p1);
  	    objSetPos2(sObjName, t2, p2);
  	    objSetPos3(sObjName, t3, p3);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetRay(sObjName, ray);
  	    objSetLevelStyle(sObjName, levelWidth, levelStyle, levelCol);
  	    objSetTF(sObjName, tf);
  	    objSetFibo(sObjName, FIBOLEVELS,FiboLines);
        ObjectSetInteger(0,sObjName, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0,sObjName, OBJPROP_HIDDEN, false);
  	    break;
  	case OBJ_FIBOCHANNEL:
  	    sObjName = getPrefix(S_FIBOCHANNEL, sVarParam[2]);
  	    ObjectCreate(0,sObjName, OBJ_FIBOCHANNEL, 0, 0, 0);
  	    objSetPos1(sObjName, t1, p1);
  	    objSetPos2(sObjName, t2, p2);
  	    objSetPos3(sObjName, t3, p3);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetRay(sObjName, ray);
  	    objSetLevelStyle(sObjName, width/*levelWidth*/, style/*levelStyle*/, col /*levelCol*/);
  	    objSetTF(sObjName, tf);
  	    objSetFibo(sObjName, FIBOLEVELS,FiboLines);
        ObjectSetInteger(0,sObjName, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0,sObjName, OBJPROP_HIDDEN, false);
  	    break;
  	case OBJ_FIBOFAN:
  	    sObjName = getPrefix(S_FIBOFAN, sVarParam[2]);
  	    ObjectCreate(0,sObjName, OBJ_FIBOFAN, 0, 0, 0);
  	    objSetPos1(sObjName, t1, p1);
  	    objSetPos2(sObjName, t2, p2);
  	    //objSetPos3(sObjName, t3, p3);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetLevelStyle(sObjName, levelWidth, levelStyle, levelCol);
  	    objSetTF(sObjName, tf);
  	    objSetFibo(sObjName, FIBOLEVELS,FiboLines);
        ObjectSetInteger(0,sObjName, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0,sObjName, OBJPROP_HIDDEN, false);
  	    break;
  	case OBJ_CHANNEL:
  	    sObjName = getPrefix(S_CHANNEL, sVarParam[2]);
  	    ObjectCreate(0,sObjName, OBJ_CHANNEL, 0, 0, 0);
  	    objSetPos1(sObjName, t1, p1);
  	    objSetPos2(sObjName, t2, p2);
  	    objSetPos3(sObjName, t3, p3);
  	    objSetStyle(sObjName, width, style, col);
  	    objSetBack(sObjName, back);
  	    objSetLevelStyle(sObjName, width/*levelWidth*/, style/*levelStyle*/, col /*levelCol*/);
  	    objSetTF(sObjName, tf);
        ObjectSetInteger(0,sObjName, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0,sObjName, OBJPROP_HIDDEN, false);
  	    break;	  	    	    
  	default:
  	    break;
  	}
  }
  ChartRedraw(NULL);
}
//----------------------------------------------------------------------
void updateClipBoard()
{
  int nVar = GlobalVariablesTotal();
  int jObj, jVar;
  string sObjName, sObjParam[];
  string sVarName, sVarParam[];
  int nDel = 0;
  string text_clipboard="";
  //Print ("nVar ="+nVar);
    
  for (jVar = 0; jVar < nVar; jVar++) {
  	sVarName = GlobalVariableName(jVar);
	  if (StringFind(sVarName, sSlavePrefix) < 0) {
	    // skip kankei nai global variable
	    continue;
	  }
    StringConcatenate(text_clipboard, text_clipboard, sVarName);
    StringConcatenate(text_clipboard, text_clipboard, "__%%__");
    StringConcatenate(text_clipboard, text_clipboard, GlobalVariableGet(sVarName));
    StringConcatenate(text_clipboard, text_clipboard, "\n");
  }
  //Print ("text_clipboard before="+text_clipboard);
  CopyTextToClipboard(text_clipboard);

  //Print ("clip board="+text_clipboard);
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

//----------------------------------------------------------------------
void startMQL4()
{
  //int ret = MessageBox("Object Copy?","Question",MB_YESNO|MB_ICONQUESTION);
  //if(ret==IDNO) PasteMode = true;
  //if(StringFind(WindowExpertName(),"COPY")==-1) PasteMode = true;   //MQLInfoString(MQL_PROGRAM_NAME)
  if(StringFind(MQLInfoString(MQL_PROGRAM_NAME),"COPY")==-1) PasteMode = true;   //MQLInfoString(MQL_PROGRAM_NAME)

  if(PasteMode){
    string string_clipboard;
    string_clipboard = CopyTextFromClipboard();
    //Print("clip board:"+string_clipboard);
    ConvertStringToGlobalVariables(string_clipboard);
    updateObjects();
    PlaySound("ok");
  }else{
    //Print("copy mode");
    updateVars();
    updateClipBoard();
    PlaySound("tick");
  }
}