  local channels = ModelChannels(props)
  ctls = {{Name="hwconnect",ControlType="Button",PinStyle="Both",UserPin=true,ButtonType="Toggle",Count=1},
    {Name="Status",ControlType="Indicator",IndicatorType="Status",PinStyle="Output",UserPin=true,Count=1}}
  for i,n in ipairs{"ip","model","fw","id","band","txmode","quadmode","encmode"} do
    table.insert(ctls,{Name = "hw"..n,ControlType=i==1 and"Text"or"Indicator",IndicatorType="Text",PinStyle=i==1 and"Both"or"Output",UserPin=true,Count=1}) end
  for ch=1,channels do
    local pre = string.format("ch_%i_",ch)
    table.insert(ctls,{Name=pre.."mute",ControlType="Button",ButtonType="Toggle",Count=1,PinStyle="Both",UserPin=true})
    table.insert(ctls,{Name=pre.."gain",ControlType="Knob",Min=-18,Max=42,ControlUnit="dB",Count=1,PinStyle="Both",UserPin=true})
    table.insert(ctls,{Name=pre.."bat_chstat",ControlType="Knob",Min=0,Max=100,ControlUnit="Percent",PinStyle="Output",UserPin=true,Count=1})
    for _,base in ipairs{"name","grp","status","freq","tv"}do table.insert(ctls,{Name=pre..base,ControlType="Indicator",IndicatorType=(base=="status"and"Status"or"Text"),Count=1,PinStyle="Output",UserPin=true})end
    for _,tx in ipairs{"type","ofs","rfpwr","pwrlk","intdet","enc"} do table.insert(ctls,{ Name = pre.."tx_"..tx, ControlType="Indicator",IndicatorType="Text",PinStyle="Output",UserPin=true, Count=1})end
    for _,batt in ipairs{"cyc","rtime","type","temp"} do table.insert(ctls,{ Name = pre.."bat_"..batt, ControlType="Indicator",IndicatorType="Text",PinStyle="Output",UserPin=true,Count=1})end
    for qual=1,5 do table.insert(ctls,{Name=string.format("%squal_%i",pre,qual),ControlType="Indicator",IndicatorType="Led",Count=1}) end
    for aud=1,8 do table.insert(ctls,{Name=string.format("%saud_%i",pre,aud),ControlType="Indicator",IndicatorType="Led",Count=1}) end
    for _,ab in ipairs{"a","b"} do
      table.insert(ctls,{Name = string.format("%s%s_ant",pre,ab),ControlType = "Indicator",IndicatorType = "Led", Count=1})
      for rf=1,6 do table.insert(ctls,{ Name = string.format("%s%s_rf_%i",pre,ab,rf), ControlType = "Indicator", IndicatorType = "Led", Count=1 }) end
    end
  end 