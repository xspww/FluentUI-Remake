<img src="Assets/logodark.png#gh-dark-mode-only" alt="fluent">
<img src="Assets/logolight.png#gh-light-mode-only" alt="fluent">

# Fluent Remake ฉบับภาษาไทย

ไลบรารีนี้เขียนใหม่จาก [dawid-scripts/Fluent](https://github.com/dawid-scripts/Fluent) API ของ element ยังเหมือนต้นฉบับ แล้วเพิ่มการรองรับทัช การจัดแท็บเป็นกลุ่ม และ Dynamic Island เข้าไป

## ติดตั้งไลบรารี

โหลดไฟล์ release ก่อน

```lua
local Fluent = loadstring(game:HttpGet("https://github.com/xspww/FluentUI-Remake/releases/latest/download/main.lua"))()
```

Addon เป็นตัวเลือก ถ้าใช้ addon ให้โหลดจาก raw GitHub ก่อนเรียกใช้งาน

```lua
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/xspww/FluentUI-Remake/main/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/xspww/FluentUI-Remake/main/Addons/InterfaceManager.lua"))()
```

## สร้างหน้าต่างและแท็บ

หน้าต่างหนึ่งเก็บหลายแท็บ แท็บหนึ่งเก็บหลาย section section หนึ่งเก็บ element

```lua
local Window = Fluent:CreateWindow({
    Title = "Fluent",
    SubTitle = "Remake",
    Theme = "Dark",
})

local Tab = Window:AddTab({ Title = "Main", Icon = "box" })
local Section = Tab:AddSection("Section")

Section:AddButton({
    Title = "Button",
    Callback = function()
        print("clicked")
    end,
})

Section:AddToggle("MyToggle", {
    Title = "Toggle",
    Default = false,
    Callback = function(Value)
        print(Value)
    end,
})
```

ชื่อที่อยู่หน้าตารางตั้งค่าก็คือ key ตัว save manager ใช้ key นี้หา element อีกครั้ง

ตัวอย่างเต็มอยู่ใน [Example.client.lua](Example.client.lua)

## จัดแท็บเป็นกลุ่ม

ส่ง `Group` ไปที่ `AddTab` เพื่อวางแท็บไว้ใต้หัวข้อ หัวข้อทำหน้าที่เปิดกลุ่มอย่างเดียว ไม่เปลี่ยนหน้าเนื้อหา และเปิดได้ครั้งละหนึ่งกลุ่ม

```lua
Window:AddTab({ Title = "Main", Icon = "box" })
Window:AddTab({ Title = "Child one", Icon = "box", Group = "Section A", GroupIcon = "layers" })
Window:AddTab({ Title = "Child two", Icon = "box", Group = "Section A" })

Window:SetGroupOpen("Section A", true, true) -- name, open, animated
Window:ToggleGroup("Section A")              -- opens the group
```

พอเปิดกลุ่มอีกครั้ง ไลบรารีก็เลือกแท็บลูกที่คุณเลือกไว้ล่าสุดในกลุ่มนั้น ถ้าคุณยังไม่เคยเลือกแท็บลูกในกลุ่ม ไลบรารีจะเลือกตัวแรก แท็บที่อยู่ในกลุ่มจะแสดง breadcrumb รูปแบบ `Group > Tab`

แถวของแท็บลูกจะย่อเข้า ไม่มีลูกศรและป้ายสถานะ และไม่ตอบสนองต่อการ hover แถบ selector เป็นตัวบอกแท็บที่เลือกอยู่

## Dynamic Island

แถบขนาดเล็กอยู่บนกลางจอ กดแถบนี้เพื่อเปิดหรือปิดอินเทอร์เฟซ พอปิด หน้าต่างก็หดเข้าไปในแถบ พอเปิด แถบก็ขยายกลับเป็นหน้าต่าง หน้าต่างที่หดอยู่จะติดตามตำแหน่งของแถบแบบเรียลไทม์

ในแถบมีรูปโปรไฟล์ ชื่อ จุดสถานะที่กระพริบช้า ๆ และอัตราเฟรม ไลบรารีวัดอัตราเฟรมจากช่วงเวลา 5 วินาที ส่วนค่าดิบอ่านได้จาก `Fluent.DynamicIsland.RawFps`

คุณกำหนด `IslandName` และ `IslandAvatar` ได้ตอนสร้างหน้าต่าง หรือเรียกเมธอดของ island ทีหลังก็ได้

- `SetName(Text)` เปลี่ยนชื่อ
- `SetAvatar(Image)` รับรหัส `rbxassetid://` หรือ URL รูปแบบ `http(s)://` บน executor ที่มี `request`, `writefile` และ `getcustomasset` ไลบรารีจะโหลด URL แล้วแปลงเป็น content id แบบ `rbxasset://`
- `SetText(Text)` ล็อกข้อความที่แสดงแล้วหยุดการอัปเดตอัตราเฟรมอัตโนมัติ `SetText(nil)` กลับไปแสดงอัตราเฟรม
- `SetFpsFormat(Function)` ปรับรูปแบบข้อความอัตโนมัติ ฟังก์ชันรับค่าดิบและค่าที่ปัดแล้ว ส่ง `nil` เพื่อกลับไปใช้รูปแบบเดิม
- `SetStat(Text)` และ `ResetStat()` เป็นชื่อเรียกแทน `SetText`
- `RefreshAvatar()` โหลด URL รูปโปรไฟล์ใหม่

ถ้าไม่ต้องการแถบนี้ ให้ตั้ง `DynamicIsland = false` ตอนสร้างหน้าต่าง

## แสดงหน้าจอโหลด

ระหว่างที่ไลบรารีสร้างอินเทอร์เฟซ จะแสดงแผงกลางจอที่มีเส้นความคืบหน้าเส้นเดียว หน้าต่างและแถบ island จะซ่อนอยู่จนกว่าจะโหลดเสร็จ แผงนี้วางทับเกมโดยไม่มีพื้นหลังสีเข้มเต็มจอ

### แสดง splash อัตโนมัติ

`CreateWindow` แสดง splash โดยค่าเริ่มต้น พอคุณเพิ่ม element ตัวแรก ไลบรารีก็ปิด splash เวลาแสดงขั้นต่ำช่วยไม่ให้วาบเพียงเฟรมเดียว ถ้าไม่มี element เพิ่มเลย ตัว timeout จะปิด splash ให้เอง

ส่งตารางเพื่อเปลี่ยนข้อความและเวลา

```lua
local Window = Fluent:CreateWindow({
    Title = "Fluent",
    Loading = {
        Title = "Starting",
        Text = "Building the interface...",
        MinDuration = 0.6, -- อย่างน้อย 0.6 วินาทีบนจอ
        Timeout = 15,      -- ค่าเริ่มต้น 8 วินาที
    },
})
```

ถ้าไม่ต้องการ splash ให้ตั้ง `Loading = false`

### โหลดด้วยตนเอง

ใช้โหลดแบบกำหนดเองสำหรับงานที่สคริปต์ของคุณทำเอง คุณเป็นคนส่งเปอร์เซ็นต์ให้ `SetProgress` ไลบรารีไม่ได้วัดความคืบหน้าให้ ถ้าไม่ส่ง `Progress` จะได้แถบเคลื่อนที่แบบไม่ระบุเปอร์เซ็นต์

```lua
local Loading = Fluent:ShowLoading({
    Title = "Loading",
    Text = "Starting...",
    Timeout = 30,
})

for i, work in ipairs(steps) do
    Loading:SetText(("Working %d/%d"):format(i, #steps))
    work()
    Loading:SetProgress(i / #steps)
end

Loading:Close() -- หรือ Fluent:HideLoading()
```

`ShowLoading` คืน handle ดังนี้

- `SetProgress(Value)` เคลื่อนแถบจาก 0 ถึง 1 และอัปเดตเปอร์เซ็นต์
- `SetIndeterminate(true)` เปลี่ยนเป็นแถบเคลื่อนที่
- `SetText(Text)` และ `SetTitle(Text)` เปลี่ยนข้อความ
- `Close()` เฟดออกแล้วลบแผง `Destroy()` ลบแผงทันที

ถ้าแผงเปิดอยู่ การเรียก `ShowLoading` อีกครั้งจะอัปเดตแผงเดิม ไลบรารีไม่ซ้อนแผงสองอัน

ไลบรารีมีเมธอดช่วยสำหรับแผงที่เปิดอยู่

- `Fluent:SetLoadingProgress(Value)` อัปเดตแถบ
- `Fluent:SetLoadingText(Text)` อัปเดตข้อความ
- `Fluent:FinishLoading()` ปิดแผงหลังเวลาแสดงขั้นต่ำ
- `Fluent:HideLoading()` ปิดแผงทันที

แอนิเมชันใช้สปริงแบบ critically damped เริ่มที่ scale 0.97 ไม่ใช่ศูนย์ และออกตามทางที่เข้า ถ้าต้องการให้เหลือแค่การเฟด ให้ตั้ง `Fluent.ReducedMotion = true` หรือส่ง `ReducedMotion = true` ให้ `ShowLoading`

## API

แต่ละแถวระบุวัตถุที่เรียกใช้และเมธอดหนึ่งตัว ไลบรารีตั้ง `getgenv().Fluent` ให้เป็นตารางไลบรารี ฟิลด์สาธารณะมี `Version`, `Options`, `Themes`, `Theme`, `Unloaded`, `ReducedMotion`, `NotificationLimit`, `MinimizeKeybind` และ `DynamicIsland` `CreateWindow` สร้างหน้าต่างได้หนึ่งหน้าต่างต่อไลบรารีหนึ่งตัว `Config.Size` ไม่มีผล หน้าต่างมีขนาดคงที่ 635 คูณ 541 พิกเซล

### ไลบรารี

| เมธอด | สิ่งที่ทำ |
| --- | --- |
| `CreateWindow(Config)` | สร้างหน้าต่าง `Config` รับ `Title`, `SubTitle`, `Theme`, `MinimizeKey`, `TabWidth`, `DynamicIsland`, `IslandName`, `IslandAvatar` และ `Loading` |
| `SetTheme(Name)` | เปลี่ยน theme ชื่อ theme อยู่ใน `Fluent.Themes` ชื่อที่ไม่มีอยู่จะไม่เปลี่ยน theme |
| `Notify(Config)` | แสดงการแจ้งเตือนแล้วคืน handle `Config` รับ `Title`, `Content`, `SubContent`, `Duration` และ `MaxNotifications` |
| `ShowLoading(Config)` | แสดงแผงโหลดแล้วคืน handle การเรียกครั้งที่สองอัปเดตแผงที่เปิดอยู่ `Config` รับ `Title`, `Text`, `Progress`, `MinDuration`, `Timeout`, `Parent`, `ReducedMotion` และ `Auto` |
| `HideLoading()` | ปิดแผงที่เปิดอยู่ |
| `FinishLoading()` | ปิดแผงที่เปิดอยู่หลังเวลาแสดงขั้นต่ำ |
| `SetLoadingProgress(Value)` | อัปเดตแถบของแผงที่เปิดอยู่ |
| `SetLoadingText(Text)` | อัปเดตข้อความของแผงที่เปิดอยู่ |
| `GetIcon(Name)` | คืน URL ของไอคอน Lucide และคืน nil สำหรับชื่อที่ไม่มีอยู่ |
| `Destroy()` | ลบหน้าต่าง element และ signal |
| `LockInput(Name)` | เพิ่ม input lock ชื่อ `Name` ค่าเริ่มต้นคือ `default` |
| `UnlockInput(Name)` | ลบ input lock ชื่อ `Name` |
| `IsInputLocked()` | คืน true ถ้ามี input lock อย่างน้อยหนึ่งตัว |
| `IsTyping()` | คืน true ถ้ามี text box ได้รับ focus |
| `SafeCallback(Function, ...)` | เรียก callback และแสดงการแจ้งเตือนเมื่อเกิด error ไม่ทำอะไรขณะโหลด config |
| `Round(Number, Factor)` | ปัดเลข `Factor` กำหนดจำนวนตำแหน่งทศนิยมและมีค่าเริ่มต้นเป็น 0 |

### หน้าต่าง

| เมธอด | สิ่งที่ทำ |
| --- | --- |
| `AddTab(Config)` | เพิ่มแท็บ `Config` รับ `Title` และ `Icon` แท็บที่อยู่ในกลุ่มรับ `Group` และ `GroupIcon` เพิ่ม |
| `SelectTab(Index)` | เลือกแท็บตาม index ที่เป็นตัวเลข |
| `SetGroupOpen(Name, Open, Animated)` | เปิดหรือปิดกลุ่มของ navigation |
| `ToggleGroup(Name)` | เปิดกลุ่มของ navigation |
| `SetSearchQuery(Query)` | ค้นหา element จากชื่อและคำอธิบาย แล้วแสดงผลลัพธ์ใต้แถบชื่อเรื่อง |
| `SetNavQuery(Query)` | เรียก `SetSearchQuery` สคริปต์เดิมยังใช้ชื่อนี้ได้ |
| `FindElements(Query)` | คืนตารางผลลัพธ์ของ element ที่ตรงกับคำค้นหา |
| `RevealElement(Result)` | เลือกแท็บของผลลัพธ์แล้วเลื่อนไปที่ element |
| `Dialog(Config)` | เปิดกล่องข้อความ |
| `Minimize(Silent, Animated)` | สลับหน้าต่างระหว่างขนาดเปิดกับแถบ island `Silent` ปิดการแจ้งเตือนที่บอกวิธีเปิด `Animated` ใช้สปริง |
| `SetHidden(Hidden)` | ซ่อนหรือแสดงหน้าต่างโดยไม่เปลี่ยนสถานะ minimize |
| `Destroy()` | ลบหน้าต่างและ signal |

`SetGroupOpen` ไม่เปลี่ยนหน้าเนื้อหา `ToggleGroup` เปิดกลุ่มอย่างเดียว

### แท็บและ section

| เมธอด | สิ่งที่ทำ |
| --- | --- |
| `AddSection(SectionTitle)` | เพิ่ม section ให้แท็บแล้วคืน section นั้น |
| `AddButton(Config)` | เพิ่ม button |
| `AddParagraph(Config)` | เพิ่ม paragraph |
| `AddToggle(Name, Config)` | เพิ่ม toggle |
| `AddSlider(Name, Config)` | เพิ่ม slider |
| `AddDropdown(Name, Config)` | เพิ่ม dropdown |
| `AddColorpicker(Name, Config)` | เพิ่ม colorpicker |
| `AddKeybind(Name, Config)` | เพิ่ม keybind |
| `AddInput(Name, Config)` | เพิ่ม input |

`AddButton` และ `AddParagraph` รับเฉพาะ `Config` เพราะไม่มี key สำหรับเก็บชื่อ ส่วนอีกหกตัวรับ `Name` แล้วเก็บ element ไว้ใน `Fluent.Options` ภายใต้ชื่อนั้น แท็บและ section รับ constructor ทั้งแปดตัวเหมือนกัน

### Element

`Button` และ `Paragraph` มี `SetTitle`, `SetDesc` และ `Destroy` `Toggle`, `Slider`, `Dropdown`, `Colorpicker`, `Keybind` และ `Input` มี `SetValue`, `OnChanged` และ `Destroy` element ทุกตัวมี `SetTitle` และ `SetDesc` `OnChanged` ทำงานทันทีด้วยค่าปัจจุบัน

| เมธอด | ใช้กับ | สิ่งที่ทำ |
| --- | --- | --- |
| `SetTitle(Text)` | element ทุกตัว | เปลี่ยนข้อความชื่อ |
| `SetDesc(Text)` | element ทุกตัว | เปลี่ยนข้อความคำอธิบาย ข้อความว่างจะซ่อนป้ายนั้น |
| `Destroy()` | element ทุกตัว | ลบ element |
| `SetValue(Value)` | Toggle, Slider, Dropdown, Colorpicker, Keybind, Input | ตั้งค่า |
| `OnChanged(Callback)` | Toggle, Slider, Dropdown, Colorpicker, Keybind, Input | ลงทะเบียน callback สำหรับการเปลี่ยนค่า |
| `SetValue(HSV, Transparency)` | Colorpicker | รับตาราง hue, saturation และ value |
| `SetValueRGB(Color, Transparency)` | Colorpicker | รับ Color3 |
| `Open()` | Dropdown | เปิดรายการตัวเลือก |
| `Close()` | Dropdown | ปิดรายการตัวเลือก |
| `Display()` | Dropdown | รีเฟรชตัวเลือกที่แสดง |
| `BuildDropdownList()` | Dropdown | สร้างปุ่มตัวเลือกใหม่ |
| `SetValues(Values)` | Dropdown | แทนที่ตัวเลือก |
| `GetActiveValues()` | Dropdown | คืนตารางเมื่อ `Multi` เป็น true และคืน 1 หรือ 0 สำหรับการเลือกเดี่ยว |
| `SetValue(Key, Mode)` | Keybind | ตั้งปุ่มและโหมด |
| `OnClick(Callback)` | Keybind | ลงทะเบียน callback สำหรับการคลิก |
| `DoClick()` | Keybind | เรียก callback ของค่าและ callback ของการคลิก |
| `GetState()` | Keybind | คืนสถานะปัจจุบัน |

`Input` รับ `Numeric`, `Finished`, `Placeholder` และ `MaxLength` `Numeric` รับเฉพาะตัวเลข `Finished` เรียก callback ตอนกด Enter `Placeholder` ตั้งข้อความตัวอย่าง `MaxLength` ตัดข้อความให้สั้นลง `Dropdown` รับ `AllowNull` และ `AllowNull` ให้ลบตัวเลือกสุดท้ายได้

dropdown ที่ตั้ง `Multi = true` รับตาราง คุณส่ง map array หรือค่าเดียวก็ได้

```lua
Dropdown:SetValue({ two = true, three = true })
Dropdown:SetValue({ "two", "three" })
Dropdown:SetValue("two")
```

dropdown มีช่องค้นหาด้านบนของรายการ กด `Enter` เพื่อเลือกผลลัพธ์แรก กด `Esc` เพื่อปิดรายการ รายการจะแสดง `No results` เมื่อไม่มีตัวเลือกตรงกัน

### handle ของการโหลด

`ShowLoading` คืน handle นี้ ไลบรารีอ่าน `ReducedMotion` ตอนสร้างแผง

| เมธอด | สิ่งที่ทำ |
| --- | --- |
| `SetProgress(Value)` | เคลื่อนแถบจาก 0 ถึง 1 |
| `SetIndeterminate(Value)` | เปลี่ยนเป็นแถบเคลื่อนที่ |
| `SetText(Text)` | เปลี่ยนข้อความเนื้อหา |
| `SetTitle(Text)` | เปลี่ยนชื่อเรื่อง |
| `Close()` | เฟดออกแล้วลบแผง |
| `Destroy()` | ลบแผงทันที |
| `GetProgress()` | คืนความคืบหน้าปัจจุบัน |
| `GetMinDuration()` | คืนเวลาแสดงขั้นต่ำ |
| `GetElapsed()` | คืนจำนวนวินาทีตั้งแต่สร้างแผง |

### Dynamic Island

| เมธอด | สิ่งที่ทำ |
| --- | --- |
| `SetName(Name)` | เปลี่ยนชื่อ |
| `SetAvatar(Image)` | รับรหัส `rbxassetid://` หรือ URL แบบ `http(s)://` |
| `SetText(Text)` | ล็อกข้อความที่แสดง `nil` กลับไปแสดงอัตราเฟรม |
| `SetFpsFormat(Format)` | ปรับรูปแบบข้อความอัตโนมัติด้วยค่าดิบและค่าที่ปัดแล้ว `nil` กลับไปใช้รูปแบบเดิม |
| `SetStat(Text)` | เรียก `SetText` |
| `ResetStat()` | เรียก `SetText(nil)` |
| `RefreshAvatar()` | โหลด URL รูปโปรไฟล์ใหม่ |
| `Destroy()` | ลบแถบ island และ signal |

`SetText`, `SetFpsFormat`, `SetStat` และ `ResetStat` คืน island เพื่อใช้ต่อเป็นโซ่ได้

### การแจ้งเตือน

`Notify` คืน handle ที่มี `Open`, `Close`, `Destroy` และ `RemoveFromActive` `Open` ทำให้การแจ้งเตือนเคลื่อนเข้ามา `Close` เคลื่อนออกแล้วลบการแจ้งเตือน `Destroy` ลบทันที `RemoveFromActive` เอาการแจ้งเตือนออกจากรายการที่ทำงานอยู่

## Addon

addon เขียนการตั้งค่าลงไฟล์ของ executor addon แต่ละตัวต้องได้ไลบรารีก่อน `BuildConfigSection` และ `BuildInterfaceSection` รับแท็บหนึ่งตัวแล้วเพิ่ม section ให้แท็บนั้น

| วัตถุที่เรียก | เมธอด | สิ่งที่ทำ |
| --- | --- | --- |
| ทั้งสองตัว | `SetLibrary(Library)` | ส่งไลบรารีให้ addon |
| ทั้งสองตัว | `BuildFolderTree()` | สร้างโฟลเดอร์สำหรับการตั้งค่า |
| SaveManager | `BuildConfigSection(Tab)` | เพิ่ม section ของ config ให้แท็บ |
| InterfaceManager | `BuildInterfaceSection(Tab)` | เพิ่ม section ของ interface ให้แท็บ |
| SaveManager | `SetFolder(Folder)` | ตั้งโฟลเดอร์หลัก |
| SaveManager | `SetIgnoreIndexes(List)` | ข้าม key ของ element ที่ระบุตอนบันทึก |
| SaveManager | `IgnoreThemeSettings()` | ข้าม `InterfaceTheme` และ `MenuKeybind` |
| SaveManager | `Save(Name)` | เขียนไฟล์ config |
| SaveManager | `Load(Name)` | อ่านไฟล์ config |
| SaveManager | `RefreshConfigList()` | คืนชื่อไฟล์ config ทั้งหมด |
| SaveManager | `LoadAutoloadConfig()` | โหลด config ที่ระบุไว้ใน `autoload.txt` |
| InterfaceManager | `SetFolder(Folder)` | ตั้งโฟลเดอร์หลัก |
| InterfaceManager | `SaveSettings()` | เขียน `options.json` |
| InterfaceManager | `LoadSettings()` | อ่าน `options.json` |

```lua
SaveManager:SetLibrary(Fluent)
SaveManager:BuildFolderTree()
SaveManager:BuildConfigSection(Tab)

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildFolderTree()
InterfaceManager:BuildInterfaceSection(Tab)
```

save manager เก็บไฟล์ทั้งหมดไว้ใต้โฟลเดอร์เดียว interface manager เก็บ theme และปุ่มย่อหน้าต่าง

## สร้างและตรวจสอบ

ติดตั้งเครื่องมือด้วย `aftman install` Aftman ติดตั้ง Rojo, Darklua, Lune และ Selene และ `pnpm` ไม่ได้อยู่ใน `PATH`

รัน spec, linter และ build จาก PowerShell

```powershell
$env:PATH = "$env:USERPROFILE\.aftman\bin;$env:PATH"
lune.exe run spec/run.luau
selene.exe src --config selene.toml
lune.exe run build/init
```

spec ใช้ฟังก์ชัน `describe`, `it` และ `expect` แบบเดียวกับการทดสอบของ Flipper จึงรันใน Roblox Studio ได้ด้วย

build เขียนไฟล์สองไฟล์ลงโฟลเดอร์ `dist`

- `dist/main.rbxm` คือ place model เปิดใน Studio
- `dist/main.lua` คือสคริปต์ที่รวมแล้ว โหลดด้วย `loadstring`

## เครดิต

ฉบับนี้ยังคงเครดิตของโปรเจกต์ต้นฉบับ

- [dawid-scripts/Fluent](https://github.com/dawid-scripts/Fluent) โปรเจกต์ต้นฉบับ
- [richie0866/remote-spy](https://github.com/richie0866/remote-spy) ไฟล์ภาพของ UI
- [violin-suzutsuki/LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib) element และ save manager
- [Latte Softworks & Kotera](https://discord.gg/rMMByr4qas) bundler
