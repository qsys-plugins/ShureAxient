  local channels,model,ct,chofs,mofs,col=ModelChannels(props),GetModel(props),{g="Green",a="Amber",y="Yellow",r="Red",b="Blue",p="Purple"},{x=-4,y=195},{x=96,y=60,ofs=100},{a="ggggyyyr",r="aaaaar"}
  layout={hwip={PrettyName="Receiver~Address",Style="TextBox",FontSize=12,Position={116,449},Size={100,16}},Status={PrettyName="Receiver~Status",Style="TextBox",Position={62,473},Size={221,16}},
    hwconnect={PrettyName="Receiver~Connect",Style="Button",Legend="Connect",Font="Roboto",FontStyle="Bold",Position={225,449},Size={58,16},Color=Color.Button.On,UnlinkOffColor=true,OffColor=Color.Button.Off}}
  graphics={
    {Type="GroupBox",StrokeWidth=0,Fill=Color.Black,Position={0,0},Size={106+channels*100,572}},
    {Type="Svg",Image=SVG.SHURE,Position={7,6},Size={84,14}},-- Shure Logo
    {Type="Svg",Image=SVG.AD,Position={channels==2 and 94 or 181,6},Size={144,12}},-- AD Logo
    {Type="Svg",Image=SVG.Base..SVG.AD4,Position={channels==2 and 244 or 443,6},Size={40,12}},-- AD4
    {Type="Svg",Image=SVG.Base..SVG[channels==2 and"D"or"Q"],Position={channels==2 and 286 or 485,6},Size={12+(channels==2 and 0 or 2),12+(channels==2 and 0 or 1)}},-- D/Q
    {Type="Label",Text="v"..PluginInfo.Version,HTextAlign="Right",Color=Color.White,FontSize=7,Position={channels==2 and 247 or 449,20},Size={53,9}},
    {Type="GroupBox",Text=model.." Status",Color=Color.White,Fill=Color.LtrGray,StrokeWidth=1,StrokeColor=Color.White,CornerRadius=8,HTextAlign="Left",Position={15,441},Size={281,122}},
    {Type="Label",Text="IP",HTextAlign="Right",Color=Color.White,FontSize=10,Position={92,449},Size={21,16}},
    {Type="Label",Text="Status",HTextAlign="Right",Color=Color.White,FontSize=10,Position={21,476},Size={38,16}}
  }
  local function AddLED(dia,n,t)layout[n]={Style="Led",Style="Led",Color=t.c,UnlinkOffColor=true,OffColor=Color.LED.Off,Position=t.p,Size={dia,dia},Margin=1,StrokeWidth=0}end
  local function AddCtl(name,t)layout[name]={PrettyName=t.pn,Style=t.st,ButtonStyle=t.bt,Color=t.clr,Position=t.p,FontSize=t.fs,Legend=t.l,CornerRadius=t.cr,Margin=t.m,OffColor=t.oc,UnlinkOffColor=t.oc~=nil,Size=t.s}end
  local function AddTxt(name,ix,ch,t,clr)t.p,t.s,t.st,t.fs={chofs.x+ch*100,ix==1 and 46 or(chofs.y+ix*14)},{100,14},t.st or"Textbox",t.fs or 9 AddCtl(name,t)end
  local function AddLabel(t)table.insert(graphics,{Type="Label",Text=t.t,HTextAlign=t.hta~=nil and t.hta or"Center",FontSize=t.fs~=nil and t.fs or 10,Font=t.f,
    FontStyle=t.fst,StrokeWidth=t.sw,StrokeColor=t.sc,Color=t.c,Fill=t.fl,Position=t.p,Size=t.s})end
  for i,c in ipairs{{l={"Model","Firmware","Device ID","RF Band"},n={"model","fw","id","band"},x={p=30,s=36}},{l={"Transmission","Quadversity","Encryption"},n={"txmode","quadmode","encmode"},x={p=143,s=69}}} do for r,l in ipairs(c.l)do
    local pretty = l..tostring(i==2 and" Mode"or"")table.insert(graphics,{Type="Label",Text=pretty,Name=c.n[r],HTextAlign="Right",FontSize=7,Color=Color.White,Position={c.x.p,485+r*14},Size={c.x.s,14}})
    AddCtl("hw"..c.n[r],{pn="Receiver~"..pretty,st="Text",p={c.x.p+(i==1 and 40 or 73),485+r*14},fs=9,s={67,14}})
  end end 
  local ctltable = {{c="name",p="Channel Name",fs=11},{c="mute",p="Mute",st="Button",bt="Toggle",clr=Color.LED.Red,oc=Color.LtrGray,cr=2,m=1,l="MUTE"},{c="gain",p="Gain",st="Text",clr=Color.Gain},
    {c="grp",p="Group"},{c="status",p="Status",fs=6},{prefix={c="bat",p="Battery"},t={{c="cyc",p="Cycles"},{c="rtime",p="Run Time"},{c="type",p="Type"},{c="temp",p="Temperature"},{c="chstat",p="Charge Status",clr=Color.BattMeter}}},
    {prefix={c="tx",p="Transmitter",sp="Transmitter"},t={{c="type",p="Type"},{c="ofs",p="Offset"},{c="rfpwr",p="RF Power"},{c="pwrlk",p="Power Lock"},{c="intdet",p="Interference Detection"},{c="enc",p="Encryption"}}}}
  local function AddMeterBlock(ch)local pre,xofs =string.format("ch_%i_",ch),mofs.x+(mofs.ofs*ch-mofs.ofs)
    for ix,mt in ipairs{{n="freq",p="Frequency",s={52,25},px=0},{n="tv",p="TV",s={49,25},px=51}}do layout[string.format("ch_%i_%s",ch,mt.n)]=
      {PrettyName=string.format("Channel %i~%s",ch,mt.p),Style="TextBox",Font="Roboto",FontStyle="Medium",FontSize=10.5,Position={mt.px+0+xofs,mofs.y},Size=mt.s,TextBoxStyle="NoBackground"}end
    for _,ml in ipairs{{p={0+xofs ,0+mofs.y},s={52,25}},{p={51+xofs,0+mofs.y},s={49,25}},{p={0+xofs,24+mofs.y},s={64,14},t="RF"},{p={63+xofs,24+mofs.y},s={37,14},t="Audio"},
      {p={0+xofs,38+mofs.y},s={64,111}},{p={63+xofs,38+mofs.y},s={37,111}},{p={0+xofs ,148+mofs.y},s={100,16},t="Q",hta="Left"}} do
      local lt={sw=1,sc=Color.Stroke,fl=Color.BGBlack,f="Roboto",fst="Medium",fs=10.5,c=Color.White}for k,v in pairs(ml)do lt[k]=v end AddLabel(lt)end
    for qual=1,5 do AddLED(13,string.format("%squal_%i",pre,qual),{p={18*qual-5+xofs,149+mofs.y},c=Color.LED.Purple})end
    for aud=1,8 do AddLED(13,string.format("%saud_%i",pre,aud),{p={75+xofs, 145+mofs.y-13*aud},c=Color.LED[ct[(col.a):sub(aud,aud)] ]})end
    for abix,ab in ipairs{"a","b"} do local px = xofs+abix*39-34 AddLED(14,string.format("%s%s_ant",pre,ab),{p={px,40+mofs.y},c=Color.LED.Blue})
      for rf=1,6 do local py=147+mofs.y-14*rf AddLED(14,string.format("%s%s_rf_%i",pre,ab,rf),{p={px,py},c=Color.LED[ct[(col.r):sub(rf,rf)] ]})
        if abix==1 then AddLabel{t=tostring(rf<6 and -95+5*rf or "OL"),p={chofs.x+ch*100+19,py},s={25,14},f="Roboto",fst="Medium",c=Color.White,fs=10.5}end end
      AddLabel{t=ab:upper(),p={px,52+mofs.y},s={14,12},f="Roboto",fst="Medium",c=Color.White,fs=10.5}
    end
  end
  for ch=1,channels do
    AddMeterBlock(ch)AddLabel{t=string.format("Channel %i",ch),p={chofs.x+ch*100,27},s={100,16},hta="Center",fs=11,c=Color.White,f="Roboto",fst="Bold",}
    local yindex,pre=0,{c=string.format("ch_%i_",ch),p=string.format("Channel %i~",ch)}
    for yix,base in ipairs(ctltable)do local pre=string.format("ch_%i_",ch)
      if base.t~=nil then
        for subix,subbase in ipairs(base.t)do yindex=yindex+1 local mid=base.prefix local name=string.format("%s%s_%s",pre,mid.c,subbase.c)
          AddTxt(name,yindex,ch,{pn=string.format("Channel %i~%s~%s",ch,mid.p,subbase.p),clr=subbase.clr,fs=subbase.fs})
          if ch==1 then if mid.sp~=nil then mid.p=mid.sp end AddLabel{t=string.format("%s %s",mid.p,subbase.p),hta="Right",p={2,chofs.y+yindex*14},c=Color.White,s={84,14},fs=7}end
        end
      else yindex=yindex+1
        AddTxt(string.format("%s%s",pre,base.c),yindex,ch,{pn=string.format("Channel %i~%s",ch,base.p),fs=base.fs,m=base.m,clr=base.clr,oc=base.oc,bt=base.bt,st=base.st,l=base.l})
        if ch==1 then AddLabel{t=base.p,hta="Right",c=Color.White,p={2,yindex==1 and 46 or(chofs.y+yindex*14)},s={84,14},fs=base.fs~=nil and base.fs or 7}end
      end
    end
  end