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

เรียกฟังก์ชันเหล่านี้จากไลบรารี

- `CreateWindow(Config)` สร้างหน้าต่าง ไลบรารีมีได้หนึ่งหน้าต่าง ตารางตั้งค่ารับ `Title`, `SubTitle`, `Theme`, `MinimizeKey`, `TabWidth`, `DynamicIsland`, `IslandName`, `IslandAvatar` และ `Loading` ขนาดหน้าต่างคงที่ที่ 635 คูณ 541
- `SetTheme(Name)` เปลี่ยน theme ชื่อ theme อยู่ใน `Fluent.Themes` ไลบรารีไม่สนใจชื่อที่ไม่มีอยู่
- `Notify(Config)` แสดงการแจ้งเตือน
- `ShowLoading(Config)` แสดงหน้าจอโหลดกลางจอแล้วคืน handle ตารางตั้งค่ารับ `Title`, `Text`, `Progress`, `MinDuration`, `Timeout`, `Parent` และ `ReducedMotion` handle มี `SetProgress`, `SetIndeterminate`, `SetText`, `SetTitle`, `Close` และ `Destroy`
- `HideLoading()` ปิดหน้าจอโหลด
- `FinishLoading()` ปิดหน้าจอโหลดหลังเวลาแสดงขั้นต่ำ
- `SetLoadingProgress(Value)` และ `SetLoadingText(Text)` อัปเดตหน้าจอโหลดที่เปิดอยู่
- `GetIcon(Name)` คืน URL ของไอคอน Lucide
- `Destroy()` ลบหน้าต่าง element และ signal

เรียกฟังก์ชันเหล่านี้จากหน้าต่าง

- `AddTab(Config)` เพิ่มแท็บ ตารางตั้งค่ารับ `Title` และ `Icon` แท็บที่อยู่ในกลุ่มรับ `Group` และ `GroupIcon` เพิ่ม
- `SelectTab(Index)` แสดงแท็บ
- `SetGroupOpen(Name, Open, Animated)` เปิดหรือปิดกลุ่มของ navigation
- `ToggleGroup(Name)` เปิดกลุ่มของ navigation
- `SetNavQuery(Text)` กรองแถว sidebar ตามชื่อ ช่องค้นหาในแถบชื่อเรื่องเป็นตัวขับเคลื่อน
- `Dialog(Config)` เปิดกล่องข้อความ
- `Minimize()` ซ่อนหน้าต่าง การเปิดปิดด้วยแถบ island มีแอนิเมชัน ส่วน keybind เกิดขึ้นทันที

เรียกฟังก์ชันเหล่านี้จากแท็บหรือ section เพื่อเพิ่ม element element ส่วนใหญ่รับชื่อและตารางตั้งค่า

- `AddButton(Config)`
- `AddParagraph(Config)`
- `AddToggle(Name, Config)`
- `AddSlider(Name, Config)`
- `AddDropdown(Name, Config)`
- `AddColorpicker(Name, Config)`
- `AddKeybind(Name, Config)`
- `AddInput(Name, Config)`

element ส่วนใหญ่มี `SetValue`, `OnChanged` และ `Destroy` dropdown มี `SetValues` และ `GetActiveValues` เพิ่ม ส่วน keybind มี `GetState` เพิ่ม

dropdown มีช่องค้นหาด้านบนของรายการ พิมพ์เพื่อกรองตัวเลือก กด `Enter` เพื่อเลือกผลลัพธ์แรก กด `Esc` เพื่อปิดรายการ ใช้ได้ทั้งแบบเลือกเดี่ยวและเลือกหลายตัว ถ้าไม่มีตัวเลือกตรงกัน รายการจะแสดง `No results`

dropdown ที่ตั้ง `Multi = true` รับตาราง คุณส่ง map array หรือค่าเดียวก็ได้

```lua
Dropdown:SetValue({ two = true, three = true })
Dropdown:SetValue({ "two", "three" })
Dropdown:SetValue("two")
```

## Addon

addon เขียนการตั้งค่าลงไฟล์ของ executor addon แต่ละตัวต้องได้ไลบรารีก่อน `BuildConfigSection` และ `BuildInterfaceSection` รับแท็บหนึ่งตัวแล้วเพิ่ม section ให้แท็บนั้น

```lua
SaveManager:SetLibrary(Fluent)
SaveManager:BuildFolderTree()
SaveManager:BuildConfigSection(Tab)

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildFolderTree()
InterfaceManager:BuildInterfaceSection(Tab)
```

save manager เก็บไฟล์ทั้งหมดไว้ใต้โฟลเดอร์เดียว interface manager เก็บ theme และปุ่มย่อหน้าต่าง

## สร้างและทดสอบ

ติดตั้งเครื่องมือแล้วสร้างไฟล์

```bash
aftman install
pnpm install
pnpm run bundle
```

Aftman ติดตั้ง Rojo, Darklua, Lune และ Selene ให้แน่ใจว่า `~/.aftman/bin` อยู่ใน `PATH`

build เขียนไฟล์สองไฟล์ลงโฟลเดอร์ `dist`

- `dist/main.rbxm` คือ place model เปิดใน Studio
- `dist/main.lua` คือสคริปต์ที่รวมแล้ว โหลดด้วย `loadstring`

ถ้าต้องการเฉพาะ place model ให้รัน `pnpm run rojo`

spec อยู่ในโฟลเดอร์ `spec` รันด้วย Lune

```bash
pnpm run test
```

spec ใช้ฟังก์ชัน `describe`, `it` และ `expect` แบบเดียวกับการทดสอบของ Flipper จึงรันใน Roblox Studio ได้ด้วย

รัน linter ด้วย Selene

```bash
pnpm run lint
```

## เครดิต

ฉบับนี้ยังคงเครดิตของโปรเจกต์ต้นฉบับ

- [dawid-scripts/Fluent](https://github.com/dawid-scripts/Fluent) โปรเจกต์ต้นฉบับ
- [richie0866/remote-spy](https://github.com/richie0866/remote-spy) ไฟล์ภาพของ UI
- [violin-suzutsuki/LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib) element และ save manager
- [Latte Softworks & Kotera](https://discord.gg/rMMByr4qas) bundler
