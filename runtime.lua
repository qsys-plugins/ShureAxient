-- Services 
AD4 = TcpSocket.New()
AD4.ReadTimeout = 15
PollTimer = Timer.New()
rapidjson = require("rapidjson")

-- Constants
Channels = ModelChannels(Properties)
status_state = { OK = 0, COMPROMISED = 1, FAULT = 2, NOTPRESENT = 3, MISSING = 4, INITIALIZING = 5 }
ANTSTAT={X="",R="Red",B="Blue"}
QUADSTAT={XX="Quad Off",XXXX="Quad ON"}
BATTYPE={LION="Lithium Ion",ALKA="Alkaline",NIMH="Nickel Metal-Hydride",LITH="Lithium",UNKN="Unknown"}
BATTMIN={[0xFFFD]="Battery communication warning",[0xFFFE]="Battery time calculating",[0xFFFF]="Unknown"}
TXMODE={HIGH_DENSITY="High Density",STANDARD="Standard"}
QUADENC={OFF="Off",ON="On"}
Tx={Int={DETECTED={Color="Orange",Msg="Interference Detected",State="COMPROMISED"},NONE={Color="Green",Msg="",State="OK"}},
    Enc={ERROR={Color="Red",Msg="Mismatched Transmitter (Encryption)",State="FAULT"},OK={Color="Green",Msg="",State="OK"}}}
Data={BATTTEMP={C={0,0,0,0},F={0,0,0,0}},BATTTYPE={"","","",""},TXMODEL={"","","",""},MODEL=""}

-- Control Aliases
hw,ch = {connect=Controls.hwconnect,ip=Controls.hwip,status=Controls.Status},{}
for chan=1,Channels do
  local pre,chtable = string.format("ch_%i_",chan),{}
  local insert = {qual={},audlev={},rf={}}
  for _,base in ipairs{"name","mute","gain","grp","status","freq","tv"}do chtable[base] = Controls[pre..base]end
  for _,tx in ipairs{"type","ofs","rfpwr","pwrlk","intdet","enc"}do chtable["tx"..tx] = Controls[pre.."tx_"..tx]end
  for _,batt in ipairs{"cyc","rtime","type","temp","chstat"}do chtable["bat"..batt] = Controls[pre.."bat_"..batt]end
  for qual=1,5 do table.insert(insert.qual,Controls[string.format("%squal_%i",pre,qual)])end
  for aud=1,8 do table.insert(insert.audlev,Controls[string.format("%saud_%i",pre,aud)])end
  for _,ab in ipairs{"a","b"} do insert.rf[ab]={ant=Controls[string.format("%s%s_ant",pre,ab)],meter={}}
  for rf=1,6 do table.insert(insert.rf[ab].meter,Controls[string.format("%s%s_rf_%i",pre,ab,rf)])end end
  for n,ctlT in pairs(insert) do chtable[n]=ctlT end table.insert(ch,chtable)
end

-- Helper functions
function TablePretty(tbl,sort)return rapidjson.encode(tbl,{pretty=true,sort_keys=sort})end
function CamelCase(str)
  local outstr={}
  for word in str:gmatch("(%S+)") do
    local wordout={}for char in word:gmatch(".") do table.insert(wordout,#wordout==0 and char:upper() or char:lower())end
    table.insert(outstr,table.concat(wordout))
  end return table.concat(outstr," ")
end
function ExtractText(str) local msg,text={}
  -- Extract strings from {} and replace with token, then chop up on spaces into array and restore text
  if str:find("{.-}")then text,str=((str.." "):match("{(.-)%s+}")):gsub(" ","`"),str:gsub("{.-}","TEXTSTR") end
  for chunk in str:gmatch(" ([%w%-%p]+)")do if chunk:find("TEXTSTR")then chunk = text:gsub("`"," ")end table.insert(msg,chunk)end
  return msg
end
  -- Status Update
function Status( msg, state, chan )
  if chan==nil then
    if state=="OK" and #msg==0 then
      msg="Connected"..tostring(#Data.MODEL>0 and " to "..Data.MODEL or "")
    end
  else
    if ch[chan].txtype.String=="Unknown" then
      msg="No Transmitter"..tostring(#msg>0 and "; "..msg or "")
      if status_state[state]~=2 then state="NOTPRESENT" end
    end
  end
  local st = chan==nil and hw.status or ch[chan].status
  st.Value = status_state[state]
  st.String = msg
  if ((DebugDesc and #msg>0) or (status_state[state]>0)) and chan==nil then print("Status: "..msg) end
end 
function BitsToBool(n)
  bits,bool = bitstring.binstream(string.char(n)),{}
  for i=1,#bits do table.insert(bool,tonumber(bits:sub(9-i,9-i))==1) end
  return bool
end
function GetAll()if AD4.IsConnected then AD4:Write("< GET 0 ALL >") end end
FormatFn = {PEAKRMS=function(v)return v-120 end}
function BatteryChargable(chan,origmsg)return Data.BATTTYPE[chan]=="ALCA"or Data.BATTTYPE[chan]=="LITH" end
function NA(chan,origmsg,temp)
  local txmod,chrg,msg=Data.TXMODEL[chan],BatteryChargable(chan)
  local present=txmod~="Unknown"and#txmod~=0
  return not (present or chrg),(present or chrg) and "Not Applicable" or origmsg
end

-- Command Methods
ChannelFn = {
  CHAN_NAME=function(chan,name)ch[chan].name.String=name end,
  AUDIO_MUTE=function(chan,msg)ch[chan].mute.Boolean=msg=="ON"end,
  AUDIO_GAIN=function(chan,msg)ch[chan].gain.Value=msg-18 end,
  FREQUENCY=function(chan,msg)ch[chan].freq.String=string.format("%.03f",msg/1000)end,
  GROUP_CHANNEL=function(chan,msg)local p1,p2=msg:match("(%d+),(%d+)")ch[chan].grp.String=string.format("{ %i, %i }",tonumber(p1),tonumber(p2))end,
  ANTENNA_STATUS=function(chan,msg)end,
  TX_BATT_CYCLE_COUNT=function(chan,msg)
    ch[chan].batcyc.IsIndeterminate,ch[chan].batcyc.String=NA(chan,msg==0xFFFF and"Unknown"or string.format("%i",msg),rx)end,
  TX_BATT_MINS=function(chan,min)ch[chan].batrtime.IsIndeterminate,ch[chan].batrtime.String=NA(chan,min>0xFFFC and BATTMIN[min]or string.format("%i:%02i",min//60,min%60))end,
  TX_BATT_TYPE=function(chan,btype)ch[chan].battype.String,Data.BATTTYPE[chan],ch[chan].battype.IsIndeterminate=BATTYPE[btype],btype,btype=="UNKN"end,
  TX_BATT_TEMP=function(chan,temp,scale,rx)
    local t=temp==0xFF and"Unknown"or temp.."°"..scale
    Data.BATTTEMP[scale][chan]=t
    local isind,msg=NA(chan,string.format("%s / %s",Data.BATTTEMP.C[chan],Data.BATTTEMP.F[chan]) )
    ch[chan].battemp.String =msg 
    ch[chan].battemp.IsIndeterminate= isind
  end,
  TX_BATT_CHARGE_PERCENT=function(chan,chg)
    ch[chan].batchstat.Position=chg==0xFF and 0 or chg/100 
    ch[chan].batchstat.IsIndeterminate=NA(chan,"")
    ch[chan].batchstat.IsDisabled=not BatteryChargable(chan,"")
  end,
  TX_MODEL=function(chan,mod)ch[chan].txtype.String=mod=="UNKNOWN"and"Unknown"or mod Data.TXMODEL[chan]=ch[chan].txtype.String end,
  TX_OFFSET=function(chan,ofs)ch[chan].txofs.String=ofs==0xFF and"Unknown" or string.format("%i dB",ofs-12)ch[chan].txofs.IsIndeterminate=ofs==0xFF end,
  TX_POWER_LEVEL=function(chan,pl)ch[chan].txrfpwr.String=pl==0xFF and"Unknown"or string.format("%i mW",pl)ch[chan].txrfpwr.IsIndeterminate=pl==0xFF end,
  TX_LOCK=function(chan,lock)ch[chan].txpwrlk.String=CamelCase(lock)ch[chan].txpwrlk.IsIndeterminate=ch[chan].txtype.String=="Unknown"end,
  INTERFERENCE_STATUS=function(chan,int)ch[chan].txintdet.String=int ch[chan].txintdet.Color=Tx.Int[int].Color Status(Tx.Int[int].Msg,Tx.Int[int].State,chan)end,
  ENCRYPTION_STATUS=function(chan,enc)ch[chan].txenc.String=enc ch[chan].txenc.Color=Tx.Enc[enc].Color Status(Tx.Enc[enc].Msg,Tx.Enc[enc].State,chan)end,
  RSSI_LED_BITMAP=function(chan,data)
    local ab=string.char(0x60+data[1])
    for ix,led in ipairs(ch[chan].rf[string.char(0x60+data[1])].meter)do
      local mask=BitsToBool(tonumber(data[2]))
      led.Boolean=mask[ix]
    end
  end,
  RSSI=function(chan,data)end,
} 
UnitFn = {
  MODEL=function(model)Controls.hwmodel.String=model end,
  FW_VER=function(fwver)Controls.hwfw.String=fwver end,
  DEVICE_ID=function(devid)Controls.hwid.String=devid end,
  RF_BAND=function(rfband)Controls.hwband.String=rfband end,
  TRANSMISSION_MODE=function(txmode)Controls.hwtxmode.String=TXMODE[txmode]end,
  QUADVERSITY_MODE=function(qmode,rx)Controls.hwquadmode.String=QUADENC[qmode]end,
  ENCRYPTION_MODE=function(emode,rx)Controls.hwencmode.String=QUADENC[emode]end,
}
sampleFn = {
  CHANNEL_QUALITY=function(chan,data)local q=tonumber(data)for dot,led in ipairs(ch[chan].qual)do led.Boolean = dot<=q and q~=255 end end,
  AUDIO_LED_BITMAP=function(chan,val)local boolT=BitsToBool(val)for c,led in ipairs(ch[chan].audlev)do led.Boolean= boolT[c]end end,
  AUDIO_LEVEL_PEAK=function(chan,data)end,--print(string.format("Channel %i AUDIO_LEVEL_PEAK: %idBFS",chan,FormatFn.PEAKRMS(data)))end,
  AUDIO_LEVEL_RMS=function(chan,data)end,--print(string.format("Channel %i AUDIO_LEVEL_RMS: %idBFS",chan,FormatFn.PEAKRMS(data)))end,
  ANTENNA_STATUS=function(chan,data)for i=1,#data do local ant,color=ch[chan].rf[string.char(0x60+i)].ant,ANTSTAT[data:sub(i,i)]ant.Color,ant.Boolean=color,#color>0 end end,
  RF_BAND=function(chan,data)print("RF_BAND",chan,data)end,
  RSSI=function(chan,data,ab)local abb = string.byte(ab)-0x40 end
}

function parseSample(chan,msg,rx)
  for _,fmt in ipairs{"CHANNEL_QUALITY","AUDIO_LED_BITMAP","AUDIO_LEVEL_PEAK","AUDIO_LEVEL_RMS","ANTENNA_STATUS"}do
    local elem1 = table.remove(msg,1)
    if elem1:find("%D")==nil then elem1=tonumber(elem1)end
    sampleFn[fmt](chan,elem1)
  end for i=1,2 do for j,fmt in ipairs{"RSSI_LED_BITMAP","RSSI"} do ChannelFn[fmt](chan,{i,table.remove(msg,1)})end end
end

function parseReport(rx)
  local msg=ExtractText(rx)
  local rxcmd,mch = table.remove(msg,1),table.remove(msg,1)
  if rxcmd=="SAMPLE"then if table.remove(msg,1)=="ALL" then parseSample(tonumber(mch),msg,rx)end -- Sample Response
  elseif mch:find("%D")then if #msg==1 then msg=msg[1]UnitFn[mch](msg,rx)end -- Global Response
  else -- Channel Resp
    local chan,extra = tonumber(mch)
    if chan <= Channels then local rcmd = table.remove(msg,1)
      if #msg==1 then msg=msg[1]if not msg:find("%D")then msg=tonumber(msg)end end
      if rcmd:find("TX_BATT_TEMP")then extra=rcmd:sub(#rcmd) rcmd="TX_BATT_TEMP" end
      if ChannelFn[rcmd]~=nil then ChannelFn[rcmd](chan,msg,extra,rx)end
    end
  end
end

function Startup()
  GetAll()
  PollTimer:Start(10)
  for i=1,Channels do
    AD4:Write("< SET "..i.." METER_RATE 00100 >")
  end
  for i=1,Channels do
    ch[i].mute.EventHandler=function(m)AD4:Write(string.format("< SET %i AUDIO_MUTE O%s >",i,m.Boolean and "N" or "FF"))end
    ch[i].gain.EventHandler=function(g)g.Value=math.floor(g.Value)AD4:Write(string.format("< SET %i AUDIO_GAIN %i >",i,g.Value+18))end
  end
end

AD4.EventHandler = function(sock, evt, err)
  if evt == TcpSocket.Events.Connected then
    Status( "", "OK")
    Startup()
  elseif evt == TcpSocket.Events.Reconnect then
    Status( "socket reconnecting...", "INITIALIZING")
  elseif evt == TcpSocket.Events.Data then
    while AD4:Search(">") do
      parseReport(AD4:ReadLine(TcpSocket.EOL.Custom," >"))
    end
  elseif evt == TcpSocket.Events.Closed then
    Status( "socket closed by remote", "FAULT")
  elseif evt == TcpSocket.Events.Error then
    Status( "socket closed due to error: "..tostring(err),"FAULT")
  elseif evt == TcpSocket.Events.Timeout then
    Status( "socket closed due to timeout","FAULT")
  end
end

function Connect()
  if hw.connect.Boolean then
    if AD4.IsConnected then AD4:Disconnect() end
    Status( "Connecting to Shure Axient Receiver...", "INITIALIZING")
    AD4:Connect(hw.ip.String,2202)
  else
    AD4:Disconnect()
    Status( "Disconnected", "OK")
  end
end

PollTimer.EventHandler=GetAll
hw.ip.EventHandler = Connect  
hw.connect.EventHandler = Connect
Connect()