# =================================================================
#  КОМПЛЕКС ДИАГНОСТИКИ «ANTIFAKE PC INSPECTOR v3.0.1»
#  Автор: @afigenys | Экспресс-аудит и выявление аппаратных подделок
# =================================================================

$ErrorActionPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- 0. ЖЕСТКАЯ ФИКСАЦИЯ ОКНА ПОД FULL HD+ (100x60) ---
mode con: cols=100 lines=60

try {
    $rawUI = $Host.UI.RawUI
    $bufSize = $rawUI.BufferSize
    $bufSize.Width = 100; $bufSize.Height = 200
    $rawUI.BufferSize = $bufSize
} catch {}

# ГЛОБАЛЬНЫЙ МАСШТАБНЫЙ ЩИТ TRY/CATCH ДЛЯ УДАЛЕННОГО ДЕБАГА
try {

Clear-Host
$dash = "=" * 72
$reportPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Характеристики_и_Вердикт_ПК.txt"

# --- 0.1 ЭКРАН СБОРА ДАМПОВ УТИЛИТ ---
Write-Host $dash -ForegroundColor Cyan
Write-Host "          ANTIFAKE PC INSPECTOR v3.0.1                          " -ForegroundColor Cyan
Write-Host "     Дата проверки: $(Get-Date -Format 'dd.MM.yyyy HH:mm')" -ForegroundColor Cyan
Write-Host "     Автор разработки: @afigenys                              " -ForegroundColor DarkCyan
Write-Host $dash -ForegroundColor Cyan
Write-Host "  • Сбор аппаратных данных..." -ForegroundColor Gray

$log = @($dash, "          ANTIFAKE PC INSPECTOR v3.0.1", "     Дата проверки: $(Get-Date -Format 'dd.MM.yyyy HH:mm')", "     Автор разработки: @afigenys", $dash, "")

# --- 0.2 ТИХИЙ СБОР ДАМПОВ ИЗ УТИЛИТ С ТАЙМАУТОМ 10 СЕК ---
$currDir = $PSScriptRoot

# Авто-разблокировка всех утилит от защиты Windows
Get-ChildItem $currDir -Filter *.exe | Unblock-File -ErrorAction SilentlyContinue

# 1. CPU-Z (С таймаутом 10 сек)
$cpuzExe = Join-Path $currDir "cpuz.exe"
$cpuzDump = Join-Path $currDir "cpuz_dump.txt"
if (Test-Path $cpuzExe) {
    $pCpuz = Start-Process -FilePath $cpuzExe -ArgumentList "-txt=cpuz_dump" -WorkingDirectory $currDir -WindowStyle Hidden -PassThru
    if (-not $pCpuz.WaitForExit(10000)) {
        try { $pCpuz | Stop-Process -Force } catch {}
    }
}

$smartctlExe = Join-Path $currDir "smartctl.exe"
$hasSmartctl = Test-Path $smartctlExe

# --- 0.3 ОПРЕДЕЛЕНИЕ ТИПА УСТРОЙСТВА (НОУТБУК ИЛИ ПК) ---
$chassis = (Get-CimInstance Win32_SystemEnclosure).ChassisTypes
$isNotebook = $false
if ($chassis -contains 8 -or $chassis -contains 9 -or $chassis -contains 10 -or $chassis -contains 11 -or $chassis -contains 14 -or $chassis -contains 18 -or $chassis -contains 21) { $isNotebook = $true }
if (Get-CimInstance Win32_PointingDevice | Where-Object {$_.Description -match "TouchPad|Precision"}) { $isNotebook = $true }

Start-Sleep -MilliSeconds 300
Clear-Host

# --- 0.4 ЦВЕТНАЯ ШАПКА НА ЭКРАНЕ ---
Write-Host $dash -ForegroundColor Cyan
Write-Host "          ANTIFAKE PC INSPECTOR v3.0.1                          " -ForegroundColor Cyan
Write-Host "     Дата проверки: $(Get-Date -Format 'dd.MM.yyyy HH:mm')" -ForegroundColor Cyan
Write-Host "     Автор разработки: @afigenys                              " -ForegroundColor DarkCyan
Write-Host $dash -ForegroundColor Cyan
Write-Host ""

# ==================== БЛОК 1: МАТЕРИНСКАЯ ПЛАТА И BIOS ====================
Write-Host "1. МАТЕРИНСКАЯ ПЛАТА И BIOS" -ForegroundColor Blue
$log += "1. МАТЕРИНСКАЯ ПЛАТА И BIOS"

$board = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue | Select-Object -First 1
$bios = Get-CimInstance Win32_Bios -ErrorAction SilentlyContinue | Select-Object -First 1
$compSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | Select-Object -First 1

$boardManuf = if ($board -and $board.Manufacturer) { ([string]$board.Manufacturer).Trim() } else { "Unknown" }
$boardModel = if ($board -and $board.Product) { ([string]$board.Product).Trim() } else { "Unknown" }
$biosSN     = if ($bios -and $bios.SerialNumber) { ([string]$bios.SerialNumber).Trim() } else { "None" }

$rawBrand = if ($compSystem -and $compSystem.Manufacturer) { [string]$compSystem.Manufacturer } else { "Unknown" }
$cleanBrand = $rawBrand -replace "ASUSTeK COMPUTER INC\.|ASUSTeK", "ASUS"
$cleanBrand = $cleanBrand -replace "Micro-Star International Co\., Ltd\.|MICRO-STAR INTERNATIONAL CO\., LTD", "MSI"
$cleanBrand = $cleanBrand -replace "Hewlett-Packard", "HP"
$cleanBrand = $cleanBrand -replace "Dell Inc\.", "Dell"
$cleanBrand = $cleanBrand.Trim()
if ([string]::IsNullOrWhiteSpace($cleanBrand)) { $cleanBrand = "Unknown" }

$rawModel = if ($compSystem -and $compSystem.Model) { [string]$compSystem.Model } else { "" }
$sysModel = "$cleanBrand $rawModel".Trim()

# Умный разбор чипсета
$cleanChipset = ""
if ($boardModel -match "\b([ABHX][1-9]\d{2}[A-Z]?)\b") {
    $foundChip = $Matches[1]
    if ($foundChip -match "^[HZ]|B1|B2|B36|B46|B56|B66|B76") {
        $cleanChipset = "Intel " + $foundChip
    } else {
        $cleanChipset = "AMD " + $foundChip
    }
} else {
    $chipset = (Get-CimInstance Win32_PnPEntity | Where-Object {$_.Name -match "Chipset|LPC|eSPI"}).Name | Select-Object -First 1
    $cleanChipset = [string]$chipset
    $cleanChipset = $cleanChipset -replace "Intel\(R\)|AMD|Processor|Family|Controller|LPC|Standard|eSPI|-.*", "" -replace "Series Chipset", "Series" -replace "Chipset", ""
    $cleanChipset = ($cleanChipset -replace "\s+", " ").Trim()
}
if (-not $cleanChipset) { $cleanChipset = "Intel/AMD" }

Write-Host "  • Производитель платы:      $boardManuf" -ForegroundColor Gray
Write-Host "  • Модель и чипсет платы:    $boardModel (Чипсет: $cleanChipset)" -ForegroundColor Gray
$log += "  • Производитель платы:      $boardManuf"
$log += "  • Модель и чипсет платы:    $boardModel (Чипсет: $cleanChipset)"

if ($isNotebook) {
    Write-Host "  • Модель ноутбука:          $sysModel" -ForegroundColor Gray
    Write-Host "  • Серийный номер (S/N):     $biosSN" -ForegroundColor Yellow
    $log += "  • Модель ноутбука:          $sysModel"
    $log += "  • Серийный номер (S/N):     $biosSN"
} else {
    Write-Host "  • Тип устройства:          Стационарный ПК" -ForegroundColor Gray
    $log += "  • Тип устройства:          Стационарный ПК"
    if ($biosSN -and $biosSN -notmatch "System Serial Number|Default string|00000000|None") {
        Write-Host "  • Серийный номер (S/N):     $biosSN" -ForegroundColor Yellow
        $log += "  • Серийный номер (S/N):     $biosSN"
    }
}

# ТРЕХУРОВНЕВАЯ ПРОВЕРКА BIOS И БРЕНДОВ
$isMutnyBios = $false; $isTopBrand = $false; $isFactoryChina = $false
$fullBiosText = "$boardManuf $boardModel $sysModel $biosSN"

if ($fullBiosText -match "ASUSTeK|ASUS|LENOVO|Hewlett-Packard|HP|Dell|MSI|Micro-Star|Gigabyte|Acer|Apple|Samsung") {
    $isTopBrand = $true
} elseif ($fullBiosText -match "Xiaomi|Honor|Huawei|Hasee|Thunderobot|Machenike|Maibenben|Chuwi|Teclast|ARDOR|DEXP|Aquarius") {
    $isFactoryChina = $true
}

if ($fullBiosText -match "Default string|oem default string inject|00000000|AK3000|123456789") {
    if (-not $isTopBrand) { $isMutnyBios = $true }
}

if ($isMutnyBios) {
    Write-Host "  [!] ПРЕДУПРЕЖДЕНИЕ: Обнаружен НЕСТАНДАРТНЫЙ / OEM BIOS! Подозрение на неофициальную плату." -ForegroundColor Red -BackgroundColor Black
    $log += "  [!] ПРЕДУПРЕЖДЕНИЕ: Обнаружен НЕСТАНДАРТНЫЙ / OEM BIOS!"
} elseif ($isTopBrand) {
    Write-Host "  • Статус платы:             [УСПЕШНО] Крупный мировой бренд." -ForegroundColor Green
    $log += "  • Статус платы:             [УСПЕШНО] Крупный мировой бренд."
} elseif ($isFactoryChina) {
    Write-Host "  • Статус платы:             [ОК] Фабричный сертифицированный производитель." -ForegroundColor Cyan
    $log += "  • Статус платы:             [ОК] Фабричный сертифицированный производитель."
} else {
    Write-Host "  • Статус платы:             [УСПЕШНО] Стандартная плата." -ForegroundColor Green
    $log += "  • Статус платы:             [УСПЕШНО] Стандартная плата."
}
Write-Host ""
$log += ""

# ==================== БЛОК 2: ОПЕРАТИВНАЯ ПАМЯТЬ ====================
Write-Host "2. ОПЕРАТИВНАЯ ПАМЯТЬ (ОЗУ)" -ForegroundColor Blue
$log += "2. ОПЕРАТИВНАЯ ПАМЯТЬ (ОЗУ)"

$osMem = [Math]::Round((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1024 / 1024)
$usableMem = [Math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)

$physicalMem = 0; $slotsCount = 0; $ramSpeed = 0; $ramTypeString = "Неизвестно"
$slots = Get-CimInstance Win32_PhysicalMemory

if ($slots) {
    foreach ($slot in $slots) { 
        $physicalMem += $slot.Capacity; $slotsCount++
        if ($slot.Speed -gt $ramSpeed) { $ramSpeed = $slot.Speed }
        if ($slot.SMBIOSMemoryType -eq 26 -or $slot.MemoryType -eq 26) { $ramTypeString = "DDR4" }
        elseif ($slot.SMBIOSMemoryType -eq 34 -or $slot.MemoryType -eq 34) { $ramTypeString = "DDR5" }
        elseif ($slot.SMBIOSMemoryType -eq 24 -or $slot.MemoryType -eq 24) { $ramTypeString = "DDR3" }
    }
    $cpuzRealMem = [Math]::Round($physicalMem / 1GB)
}

if (Test-Path $cpuzDump) {
    $cpuzContent = Get-Content $cpuzDump -Raw
    if ($cpuzContent -match "Memory Size\s*:\s*(\d+)\s*GBytes") { $cpuzRealMem = [int]$Matches[1] }
    if ($cpuzContent -match "Memory Type\s*:\s*([^\r\n]+)") { $ramTypeString = $Matches[1].Trim() }
}
if ($cpuzRealMem -eq 0) { $cpuzRealMem = $osMem }

$channelRus = "Одноканальный режим"
if ($slotsCount -ge 2) { $channelRus = "Двухканальный режим" }

Write-Host "  • Физически в слотах/плате: $cpuzRealMem ГБ ($ramTypeString)" -ForegroundColor Green
Write-Host "  • Доступно процессору (ОС):  $usableMem ГБ (Отображается в Win: $osMem ГБ)" -ForegroundColor Yellow
Write-Host "  • Занято слотов памяти:      $slotsCount шт. ($channelRus)" -ForegroundColor Gray
Write-Host "  • Текущая частота памяти:    $ramSpeed МГц" -ForegroundColor Gray

$log += "  • Физически в слотах/плате: $cpuzRealMem ГБ ($ramTypeString)"
$log += "  • Доступно процессору (ОС):  $usableMem ГБ"
$log += "  • Занято слотов памяти:      $slotsCount шт. ($channelRus)"
$log += "  • Текущая частота памяти:    $ramSpeed МГц"

$memDelta = $cpuzRealMem - $usableMem
$ramFake = $false; $ramDisabled = $false

# 1. Скам через BIOS/Реестр: Windows рисует больше, чем реально нашел CPU-Z
if ($usableMem -gt ($cpuzRealMem + 0.5)) { 
    $ramFake = $true 
}
# 2. Скам через прошивку планок SPD или отвал слота: в слотах заявлено больше, чем видит ядро
elseif (($cpuzRealMem - $osMem) -gt 2.5) { 
    $ramDisabled = $true 
}

if ($ramFake) {
    Write-Host "  [!] ВНИМАНИЕ: Память нарисована в BIOS/реестре! Физически меньше, чем пишет Windows!" -ForegroundColor Red -BackgroundColor Black
    $log += "  [!] ВНИМАНИЕ: Память нарисована в BIOS/реестре!"
} elseif ($ramDisabled) {
    Write-Host "  [!] ТРЕВОГА: ЧАСТЬ ПАМЯТИ ОТКЛЮЧЕНА/НЕРАБОЧАЯ! Физически $cpuzRealMem ГБ, а доступно $usableMem ГБ!" -ForegroundColor Red -BackgroundColor Black
    $log += "  [!] ТРЕВОГА: ЧАСТЬ ПАМЯТИ ОТКЛЮЧЕНА/НЕРАБОЧАЯ!"
} else {
    Write-Host "  • Статус ОЗУ:                [УСПЕШНО] Память соответствует физической емкости." -ForegroundColor Green
    $log += "  • Статус ОЗУ:                [УСПЕШНО] Память соответствует физической емкости."
}
Write-Host ""
$log += ""

# ==================== БЛОК 3: ПРОЦЕССОР ====================
Write-Host "3. ПРОЦЕССОР (CPU)" -ForegroundColor Blue
$log += "3. ПРОЦЕССОР (CPU)"

$wmiCpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$winCpuName = "$($wmiCpu.Name)".Trim()
$cpuzCpuName = ""; $cpuzCores = 0

if (Test-Path $cpuzDump) {
    $cpuzContent = Get-Content $cpuzDump -Raw
    if ($cpuzContent -match "Specification\s*:\s*([^\r\n]+)") { $cpuzCpuName = $Matches[1].Trim() }
    if ($cpuzContent -match "Cores\s*:\s*(\d+)") { $cpuzCores = [int]$Matches[1] }
}
if (-not $cpuzCpuName) { $cpuzCpuName = $winCpuName }

$cleanCpu = $cpuzCpuName -replace "Intel\(R\)|Core\(TM\)|CPU|AMD|Processor|\(R\)", ""
$cleanCpu = $cleanCpu -replace "\b\d+(?:st|nd|rd|th)\s+Gen\b", "" -replace "Core\s+Ultra", "Ultra"
$cleanCpu = $cleanCpu -replace "\s+(Six|Eight|Quad|Dual|Hexa|Octa)-Core", "" -replace "\s+\d+-Core", "" -replace "-Core", ""
$cleanCpu = $cleanCpu -replace "\s+Six$|\s+Eight$|\s+Quad$|\s+Dual$", ""
$cleanCpu = ($cleanCpu -replace "@.*", "").Trim() -replace "\s+\b\d{1,2}\b$", "" -replace "\s+", " "

$cpuFake = $false
if ($winCpuName -ne $cpuzCpuName -and $winCpuName -notmatch [regex]::Escape($cleanCpu)) { $cpuFake = $true }
if ($cpuzCores -gt 0 -and $cpuzCores -ne $wmiCpu.NumberOfCores) { $cpuFake = $true }

$cores = $wmiCpu.NumberOfCores
$threads = $wmiCpu.NumberOfLogicalProcessors
$coreWord = "ядер"; if ($cores -in 1,2,3,4) { if ($cores -eq 1) {$coreWord = "ядро"} else {$coreWord = "ядра"} }
$threadWord = "потоков"; if ($threads -in 1,2,3,4) { if ($threads -eq 1) {$threadWord = "поток"} else {$threadWord = "потока"} }

Write-Host "  • Процессор:                $cleanCpu" -ForegroundColor Yellow
Write-Host "  • Ядра / Потоки:            $cores $coreWord / $threads $threadWord" -ForegroundColor Yellow
$log += "  • Процессор:                $cleanCpu"
$log += "  • Ядра / Потоки:            $cores $coreWord / $threads $threadWord"

if ($cpuFake) {
    Write-Host "  • Заявлено в Windows:       $winCpuName" -ForegroundColor Red
    Write-Host "  • Реальный процессор:       $cpuzCpuName" -ForegroundColor Red
    Write-Host "  [!] ТРЕВОГА: ОБНАРУЖЕН FAKE CPU! Подмена названия процессора или количества ядер!" -ForegroundColor Red -BackgroundColor Black
    $log += "  [!] ТРЕВОГА: ОБНАРУЖЕН FAKE CPU!"
} else {
    Write-Host "  • Статус CPU:               [УСПЕШНО] Подмены спецификации и ядер не обнаружено." -ForegroundColor Green
    $log += "  • Статус CPU:               [УСПЕШНО] Подмены спецификации и ядер не обнаружено."
}
Write-Host ""
$log += ""

# ==================== БЛОК 4: ВИДЕОКАРТА (HWID ANTI-FAKE) ====================
Write-Host "4. ГРАФИЧЕСКАЯ ПОДСИСТЕМА (GPU)" -ForegroundColor Blue
$log += "4. ГРАФИЧЕСКАЯ ПОДСИСТЕМА (GPU)"

$hasDiscrete  = $false
$isFakeGpu    = $false
$cleanGpuName = "встройка"
$cleanGpuVram = ""

function Get-GpuAntiFakeEngine {
    $GpuHWID = @{
        # --- ФЕЙК-ДОНОРЫ / СТАРЫЙ ХЛАМ ---
        "10DE:0DC4" = @{ Series = "GTS 450"; Variant = ""; Models = @("GeForce GTS 450"); MatchPattern = "GTS\s*450" }
        "10DE:1380" = @{ Series = "GTX 750"; Variant = ""; Models = @("GeForce GTX 750 Ti", "GeForce GTX 750"); MatchPattern = "GTX\s*750" }
        "10DE:1381" = @{ Series = "GTX 750"; Variant = ""; Models = @("GeForce GTX 750"); MatchPattern = "GTX\s*750" }
        "10DE:1401" = @{ Series = "GTX 960"; Variant = ""; Models = @("GeForce GTX 960"); MatchPattern = "GTX\s*960" }

        # --- NVIDIA GTX 900 ---
        "10DE:1402" = @{ Series = "GTX 950"; Variant = ""; Models = @("GeForce GTX 950"); MatchPattern = "GTX\s*950" }
        "10DE:13C2" = @{ Series = "GTX 970"; Variant = ""; Models = @("GeForce GTX 970"); MatchPattern = "GTX\s*970" }
        "10DE:13C0" = @{ Series = "GTX 980"; Variant = ""; Models = @("GeForce GTX 980"); MatchPattern = "GTX\s*980(?!\s*Ti)" }
        "10DE:17C2" = @{ Series = "GTX 980"; Variant = "Ti"; Models = @("GeForce GTX 980 Ti"); MatchPattern = "GTX\s*980\s*Ti" }

        # --- NVIDIA GTX 10xx ---
        "10DE:1C81" = @{ Series = "GTX 1050"; Variant = ""; Models = @("GeForce GTX 1050"); MatchPattern = "GTX\s*1050(?!\s*Ti)" }
        "10DE:1C82" = @{ Series = "GTX 1050"; Variant = "Ti"; Models = @("GeForce GTX 1050 Ti"); MatchPattern = "GTX\s*1050\s*Ti" }
        "10DE:1C03" = @{ Series = "GTX 1060"; Variant = ""; Models = @("GeForce GTX 1060"); MatchPattern = "GTX\s*1060" }
        "10DE:1B81" = @{ Series = "GTX 1070"; Variant = ""; Models = @("GeForce GTX 1070"); MatchPattern = "GTX\s*1070(?!\s*Ti)" }
        "10DE:1B82" = @{ Series = "GTX 1070"; Variant = "Ti"; Models = @("GeForce GTX 1070 Ti"); MatchPattern = "GTX\s*1070\s*Ti" }
        "10DE:1B80" = @{ Series = "GTX 1080"; Variant = ""; Models = @("GeForce GTX 1080"); MatchPattern = "GTX\s*1080(?!\s*Ti)" }
        "10DE:1B06" = @{ Series = "GTX 1080"; Variant = "Ti"; Models = @("GeForce GTX 1080 Ti"); MatchPattern = "GTX\s*1080\s*Ti" }

        # --- NVIDIA GTX 16xx ---
        "10DE:1F82" = @{ Series = "GTX 1650"; Variant = ""; Models = @("GeForce GTX 1650"); MatchPattern = "GTX\s*1650(?!\s*SUPER|\s*Ti)" }
        "10DE:2188" = @{ Series = "GTX 1650"; Variant = "SUPER"; Models = @("GeForce GTX 1650 SUPER"); MatchPattern = "GTX\s*1650\s*SUPER" }
        "10DE:2184" = @{ Series = "GTX 1660"; Variant = ""; Models = @("GeForce GTX 1660"); MatchPattern = "GTX\s*1660(?!\s*SUPER|\s*Ti)" }
        "10DE:21C4" = @{ Series = "GTX 1660"; Variant = "SUPER"; Models = @("GeForce GTX 1660 SUPER"); MatchPattern = "GTX\s*1660\s*SUPER" }
        "10DE:21D1" = @{ Series = "GTX 1660"; Variant = "Ti"; Models = @("GeForce GTX 1660 Ti"); MatchPattern = "GTX\s*1660\s*Ti" }

        # --- NVIDIA RTX 20xx ---
        "10DE:1F08" = @{ Series = "RTX 2060"; Variant = ""; Models = @("GeForce RTX 2060"); MatchPattern = "RTX\s*2060(?!\s*SUPER)" }
        "10DE:1F06" = @{ Series = "RTX 2060"; Variant = "SUPER"; Models = @("GeForce RTX 2060 SUPER"); MatchPattern = "RTX\s*2060\s*SUPER" }
        "10DE:1F02" = @{ Series = "RTX 2070"; Variant = ""; Models = @("GeForce RTX 2070"); MatchPattern = "RTX\s*2070(?!\s*SUPER)" }
        "10DE:1E84" = @{ Series = "RTX 2070"; Variant = "SUPER"; Models = @("GeForce RTX 2070 SUPER"); MatchPattern = "RTX\s*2070\s*SUPER" }
        "10DE:1E82" = @{ Series = "RTX 2080"; Variant = ""; Models = @("GeForce RTX 2080"); MatchPattern = "RTX\s*2080(?!\s*SUPER|\s*Ti)" }
        "10DE:1E81" = @{ Series = "RTX 2080"; Variant = "SUPER"; Models = @("GeForce RTX 2080 SUPER"); MatchPattern = "RTX\s*2080\s*SUPER" }
        "10DE:1E07" = @{ Series = "RTX 2080"; Variant = "Ti"; Models = @("GeForce RTX 2080 Ti"); MatchPattern = "RTX\s*2080\s*Ti" }

        # --- NVIDIA RTX 30xx ---
        "10DE:2507" = @{ Series = "RTX 3050"; Variant = ""; Models = @("GeForce RTX 3050"); MatchPattern = "RTX\s*3050" }
        "10DE:2503" = @{ Series = "RTX 3060"; Variant = ""; Models = @("GeForce RTX 3060"); MatchPattern = "RTX\s*3060(?!\s*Ti)" }
        "10DE:2486" = @{ Series = "RTX 3060"; Variant = "Ti"; Models = @("GeForce RTX 3060 Ti"); MatchPattern = "RTX\s*3060\s*Ti" }
        "10DE:2484" = @{ Series = "RTX 3070"; Variant = ""; Models = @("GeForce RTX 3070"); MatchPattern = "RTX\s*3070(?!\s*Ti)" }
        "10DE:2482" = @{ Series = "RTX 3070"; Variant = "Ti"; Models = @("GeForce RTX 3070 Ti"); MatchPattern = "RTX\s*3070\s*Ti" }
        "10DE:2206" = @{ Series = "RTX 3080"; Variant = ""; Models = @("GeForce RTX 3080"); MatchPattern = "RTX\s*3080(?!\s*Ti)" }
        "10DE:2208" = @{ Series = "RTX 3080"; Variant = "Ti"; Models = @("GeForce RTX 3080 Ti"); MatchPattern = "RTX\s*3080\s*Ti" }
        "10DE:2204" = @{ Series = "RTX 3090"; Variant = ""; Models = @("GeForce RTX 3090"); MatchPattern = "RTX\s*3090(?!\s*Ti)" }
        "10DE:2203" = @{ Series = "RTX 3090"; Variant = "Ti"; Models = @("GeForce RTX 3090 Ti"); MatchPattern = "RTX\s*3090\s*Ti" }

        # --- NVIDIA RTX 40xx ---
        "10DE:2882" = @{ Series = "RTX 4060"; Variant = ""; Models = @("GeForce RTX 4060"); MatchPattern = "RTX\s*4060(?!\s*Ti)" }
        "10DE:2803" = @{ Series = "RTX 4060"; Variant = "Ti"; Models = @("GeForce RTX 4060 Ti"); MatchPattern = "RTX\s*4060\s*Ti" }
        "10DE:2786" = @{ Series = "RTX 4070"; Variant = ""; Models = @("GeForce RTX 4070"); MatchPattern = "RTX\s*4070(?!\s*SUPER|\s*Ti)" }
        "10DE:2783" = @{ Series = "RTX 4070"; Variant = "SUPER"; Models = @("GeForce RTX 4070 SUPER"); MatchPattern = "RTX\s*4070\s*SUPER" }
        "10DE:2782" = @{ Series = "RTX 4070"; Variant = "Ti"; Models = @("GeForce RTX 4070 Ti"); MatchPattern = "RTX\s*4070\s*Ti(?!\s*SUPER)" }
        "10DE:2705" = @{ Series = "RTX 4070"; Variant = "Ti SUPER"; Models = @("GeForce RTX 4070 Ti SUPER"); MatchPattern = "RTX\s*4070\s*Ti\s*SUPER" }
        "10DE:2704" = @{ Series = "RTX 4080"; Variant = ""; Models = @("GeForce RTX 4080"); MatchPattern = "RTX\s*4080(?!\s*SUPER)" }
        "10DE:2702" = @{ Series = "RTX 4080"; Variant = "SUPER"; Models = @("GeForce RTX 4080 SUPER"); MatchPattern = "RTX\s*4080\s*SUPER" }
        "10DE:2684" = @{ Series = "RTX 4090"; Variant = ""; Models = @("GeForce RTX 4090"); MatchPattern = "RTX\s*4090" }

        # --- NVIDIA RTX 50xx / BLACKWELL ---
        "10DE:2B85" = @{ Series = "RTX 5090"; Variant = ""; Models = @("GeForce RTX 5090"); MatchPattern = "RTX\s*5090" }
        "10DE:2C02" = @{ Series = "RTX 5080"; Variant = ""; Models = @("GeForce RTX 5080"); MatchPattern = "RTX\s*5080" }
        "10DE:2C05" = @{ Series = "RTX 5070"; Variant = "Ti"; Models = @("GeForce RTX 5070 Ti"); MatchPattern = "RTX\s*5070\s*Ti" }
        "10DE:2F04" = @{ Series = "RTX 5070"; Variant = ""; Models = @("GeForce RTX 5070"); MatchPattern = "RTX\s*5070(?!\s*Ti)" }
        "10DE:2D04" = @{ Series = "RTX 5060"; Variant = "Ti"; Models = @("GeForce RTX 5060 Ti"); MatchPattern = "RTX\s*5060\s*Ti" }
        "10DE:2D05" = @{ Series = "RTX 5060"; Variant = ""; Models = @("GeForce RTX 5060"); MatchPattern = "RTX\s*5060(?!\s*Ti)" }
        "10DE:2D83" = @{ Series = "RTX 5050"; Variant = ""; Models = @("GeForce RTX 5050"); MatchPattern = "RTX\s*5050" }

        # --- NVIDIA RTX LAPTOP ---
        "10DE:2520" = @{ Series = "RTX 3060 Laptop"; Variant = ""; Models = @("GeForce RTX 3060 Laptop GPU"); MatchPattern = "RTX\s*3060" }
        "10DE:249D" = @{ Series = "RTX 3070 Laptop"; Variant = ""; Models = @("GeForce RTX 3070 Laptop GPU"); MatchPattern = "RTX\s*3070" }
        "10DE:24DD" = @{ Series = "RTX 3070 Laptop"; Variant = ""; Models = @("GeForce RTX 3070 Laptop GPU"); MatchPattern = "RTX\s*3070" }
        "10DE:24A0" = @{ Series = "RTX 3070 Ti Laptop"; Variant = "Ti"; Models = @("GeForce RTX 3070 Ti Laptop GPU"); MatchPattern = "RTX\s*3070\s*Ti" }
        "10DE:25A2" = @{ Series = "RTX 3050 Laptop"; Variant = ""; Models = @("GeForce RTX 3050 Laptop GPU"); MatchPattern = "RTX\s*3050" }
        "10DE:2523" = @{ Series = "RTX 3050 Ti Laptop"; Variant = "Ti"; Models = @("GeForce RTX 3050 Ti Laptop GPU"); MatchPattern = "RTX\s*3050\s*Ti" }
        "10DE:28A0" = @{ Series = "RTX 4060 Laptop"; Variant = ""; Models = @("GeForce RTX 4060 Laptop GPU"); MatchPattern = "RTX\s*4060" }
        "10DE:28A1" = @{ Series = "RTX 4050 Laptop"; Variant = ""; Models = @("GeForce RTX 4050 Laptop GPU"); MatchPattern = "RTX\s*4050" }

        # --- AMD RADEON ---
        "1002:6613" = @{ Series = "R7 200"; Variant = ""; Models = @("Radeon R7 240", "Radeon R7 200 Series"); MatchPattern = "R7\s*200|R7\s*240" }
        "1002:6611" = @{ Series = "R7 200"; Variant = ""; Models = @("Radeon R7 250", "Radeon R7 200 Series"); MatchPattern = "R7\s*200|R7\s*250" }
        "1002:67B1" = @{ Series = "R9 200"; Variant = ""; Models = @("Radeon R9 290"); MatchPattern = "R9\s*290" }
        "1002:67DF" = @{ Series = "RX 400/500"; Variant = ""; Models = @("Radeon RX 470", "Radeon RX 480", "Radeon RX 570", "Radeon RX 580", "Radeon RX 590"); MatchPattern = "RX\s*(470|480|570|580|590)" }
        "1002:7340" = @{ Series = "RX 5500"; Variant = ""; Models = @("Radeon RX 5500"); MatchPattern = "RX\s*5500" }
        "1002:731F" = @{ Series = "RX 5700"; Variant = ""; Models = @("Radeon RX 5700", "Radeon RX 5700 XT"); MatchPattern = "RX\s*5700" }
        "1002:73FF" = @{ Series = "RX 6600"; Variant = ""; Models = @("Radeon RX 6600", "Radeon RX 6600 XT"); MatchPattern = "RX\s*6600" }
        "1002:73DF" = @{ Series = "RX 6700"; Variant = "XT"; Models = @("Radeon RX 6700 XT", "Radeon RX 6700"); MatchPattern = "RX\s*6700" }
        "1002:73BF" = @{ Series = "RX 6800/6900"; Variant = ""; Models = @("Radeon RX 6800", "Radeon RX 6800 XT", "Radeon RX 6900 XT", "Radeon RX 6950 XT"); MatchPattern = "RX\s*(6800|6900|6950)" }
        "1002:7422" = @{ Series = "RX 7600"; Variant = ""; Models = @("Radeon RX 7600"); MatchPattern = "RX\s*7600(?!\s*XT)" }
        "1002:740F" = @{ Series = "RX 7700"; Variant = "XT"; Models = @("Radeon RX 7700 XT"); MatchPattern = "RX\s*7700\s*XT" }
        "1002:747F" = @{ Series = "RX 7800"; Variant = "XT"; Models = @("Radeon RX 7800 XT"); MatchPattern = "RX\s*7800\s*XT" }
        "1002:744C" = @{ Series = "RX 7900"; Variant = "XT"; Models = @("Radeon RX 7900 XTX", "Radeon RX 7900 XT", "Radeon RX 7900 GRE"); MatchPattern = "RX\s*7900" }

        # --- INTEL ARC ---
        "8086:56A0" = @{ Series = "Arc A770"; Variant = ""; Models = @("Intel Arc A770"); MatchPattern = "Arc\s*A770" }
        "8086:56A1" = @{ Series = "Arc A750"; Variant = ""; Models = @("Intel Arc A750"); MatchPattern = "Arc\s*A750" }
        "8086:56A2" = @{ Series = "Arc A580"; Variant = ""; Models = @("Intel Arc A580"); MatchPattern = "Arc\s*A580" }
        "8086:56A5" = @{ Series = "Arc A380"; Variant = ""; Models = @("Intel Arc A380"); MatchPattern = "Arc\s*A380" }
        "8086:56A6" = @{ Series = "Arc A310"; Variant = ""; Models = @("Intel Arc A310"); MatchPattern = "Arc\s*A310" }
        "8086:E20B" = @{ Series = "Arc B580"; Variant = ""; Models = @("Intel Arc B580"); MatchPattern = "Arc\s*B580" }
    }

    $gpus = Get-PnpDevice -Class Display | Where-Object {
        $_.Status -eq "OK" -and
        $_.FriendlyName -notmatch "Intel UHD|Intel HD Graphics|Intel Iris|Microsoft Basic Display" -and
        $_.FriendlyName -notmatch "Radeon\(TM\) Graphics|Radeon Graphics|Vega Graphics"
    }

    if (-not $gpus) {
        return @([PSCustomObject]@{
            Status = "NO_DISCRETE"; WinName = "Встройка"; Key = "NONE"
            VramGB = 0; VramSource = "none"; Series = ""; Variant = ""; Message = "[ОК] Базовая встроенная графика."
        })
    }

    $results = @()
    foreach ($gpu in $gpus) {
        $winName = "$($gpu.FriendlyName)".Trim()
        $hwid    = "$($gpu.InstanceId)"
        $key     = "UNKNOWN"

        if ($hwid -match 'VEN_([0-9A-Fa-f]{4})&DEV_([0-9A-Fa-f]{4})') {
            $key = "$($Matches[1]):$($Matches[2])".ToUpper()
        }

        $isIntegrated = $false
        if ($winName -match "Intel|UHD|HD Graphics|Iris|Radeon\(TM\) Graphics|Radeon Graphics|Vega Graphics|Microsoft Basic") {
            $isIntegrated = $true
        }

        if ($isIntegrated) {
            $results += [PSCustomObject]@{
                Status     = "INTEGRATED"
                WinName    = $winName
                Key        = $key
                VramGB     = 1
                VramSource = "none"
                Series     = ""
                Variant    = ""
                Message    = "[ОК] Встроенное графическое ядро."
            }
            continue
        }

        # ДИСКРЕТНАЯ КАРТА
        $vramGB     = 0
        $vramSource = "unknown"

        try {
            $displayClassPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
            $regDevs = Get-ChildItem $displayClassPath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match "^\d{4}$" }
            $pciPrefix = $null
            if ($key -match '^([0-9A-F]{4}):([0-9A-F]{4})$') { $pciPrefix = "PCI\VEN_$($Matches[1])&DEV_$($Matches[2])" }

            foreach ($regDev in $regDevs) {
                $props = Get-ItemProperty -Path $regDev.PSPath -ErrorAction SilentlyContinue
                if (-not $props) { continue }
                $matchingId = "$($props.MatchingDeviceId)".ToUpper()
                if ($pciPrefix -and $matchingId -like "$pciPrefix*") {
                    $rawVram = $props."HardwareInformation.qwMemorySize"
                    if ($rawVram) {
                        try {
                            $bytes = [UInt64]$rawVram
                            if ($bytes -gt 0) {
                                $vramGB = [Math]::Round(($bytes / 1GB), 1)
                                $vramSource = "registry"
                                break
                            }
                        } catch {}
                    }
                }
            }
        } catch {}

        if ($vramSource -eq "unknown") {
            try {
                $wmiGpu = Get-CimInstance Win32_VideoController | Where-Object { $_.PNPDeviceID -eq $hwid } | Select-Object -First 1
                if ($wmiGpu -and $wmiGpu.AdapterRAM -gt 0) {
                    $vramGB = [Math]::Round(($wmiGpu.AdapterRAM / 1GB), 1)
                    $vramSource = "adapterram (fallback)"
                }
            } catch {}
        }

        if ($vramGB -le 0 -or $vramGB -gt 64) { $vramGB = 0; $vramSource = "unknown" }

        # ОСНОВНАЯ ПРОВЕРКА HWID
        $status  = "UNKNOWN"; $series  = "Неизвестно"; $variant = ""; $message = ""

        if ($GpuHWID.ContainsKey($key)) {
            $entry   = $GpuHWID[$key]
            $series  = $entry.Series
            $variant = $entry.Variant

            if ($winName -match $entry.MatchPattern) {
                $status  = "OK"
                $message = "[УСПЕШНО] Видеокарта подлинная, несоответствий HWID не обнаружено."
            } else {
                $status  = "SUSPICIOUS"
                $message = "Заявлена '$winName', но аппаратный HWID ($key) указывает на '$series $variant'!"
            }
        } else {
            $status  = "UNKNOWN"; $series  = "Неизвестно"; $variant = ""
            $message = "[?] UNKNOWN: HWID $key отсутствует в локальной базе."
        }

        $results += [PSCustomObject]@{
            Status     = $status
            WinName    = $winName
            Key        = $key
            VramGB     = $vramGB
            VramSource = $vramSource
            Series     = $series
            Variant    = $variant
            Message    = $message
        }
    }
    return $results
}

$gpuRes = @(Get-GpuAntiFakeEngine)

foreach ($gpu in $gpuRes) {
    if ($gpu.Status -eq "INTEGRATED") {
        Write-Host "  • Встроенная графика:       $($gpu.WinName)" -ForegroundColor Gray
        $log += "  • Встроенная графика:       $($gpu.WinName)"
        continue
    }

    $hasDiscrete = $true
    if ($gpu.Status -eq "SUSPICIOUS") { $isFakeGpu = $true }

    $cleanGpuName = ($gpu.WinName -replace "NVIDIA|GeForce|AMD|Radeon|Intel|Corporation|\(TM\)", "").Trim() -replace "\s+", " "
    $cleanGpuVram = if ($gpu.VramGB -gt 0) { "$($gpu.VramGB) GB" } else { "не определено" }

    if ($gpu.Status -eq "SUSPICIOUS") {
        Write-Host "  • Видеокарта:               $($gpu.WinName) ($cleanGpuVram)" -ForegroundColor Red
        Write-Host "  • Аппаратный HWID:          $($gpu.Key)" -ForegroundColor Red
        Write-Host "  [!] ТРЕВОГА: НЕСООТВЕТСТВИЕ МОДЕЛИ! $($gpu.Message)" -ForegroundColor Red -BackgroundColor Black
        $log += "  • Видеокарта:               $($gpu.WinName) ($cleanGpuVram)"
        $log += "  • Аппаратный HWID:          $($gpu.Key)"
        $log += "  [!] ТРЕВОГА: НЕСООТВЕТСТВИЕ МОДЕЛИ! $($gpu.Message)"
    } elseif ($gpu.Status -eq "OK") {
        Write-Host "  • Видеокарта:               $($gpu.WinName) ($cleanGpuVram)" -ForegroundColor Green
        Write-Host "  • Статус:                   $($gpu.Message)" -ForegroundColor Green
        $log += "  • Видеокарта:               $($gpu.WinName) ($cleanGpuVram)"
        $log += "  • Статус:                   $($gpu.Message)"
    } else {
        Write-Host "  • Видеокарта:               $($gpu.WinName) ($cleanGpuVram)" -ForegroundColor Yellow
        Write-Host "  • Аппаратный HWID:          $($gpu.Key)" -ForegroundColor Yellow
        Write-Host "  • Статус:                   $($gpu.Message)" -ForegroundColor Yellow
        $log += "  • Видеокарта:               $($gpu.WinName) ($cleanGpuVram)"
        $log += "  • Аппаратный HWID:          $($gpu.Key)"
        $log += "  • Статус:                   $($gpu.Message)"
    }
    Write-Host ""
    $log += ""
}

if (-not $hasDiscrete) {
    Write-Host "  • Дискретная видеокарта:    Отсутствует (интегрированная графика)" -ForegroundColor Gray
    Write-Host "  • Статус:                   [ОК] Конфигурация со встроенным видеоядром." -ForegroundColor Cyan
    $log += "  • Дискретная видеокарта:    Отсутствует (интегрированная графика)"
    $log += "  • Статус:                   [ОК] Конфигурация со встроенным видеоядром."
}
Write-Host ""
$log += ""

# ==================== БЛОК 5: НАКОПИТЕЛИ И РЕСУРС ====================
Write-Host "5. НАКОПИТЕЛИ И РЕСУРС (SSD / HDD)" -ForegroundColor Blue
$log += "5. НАКОПИТЕЛИ И РЕСУРС (SSD / HDD)"

$disks = Get-CimInstance Win32_DiskDrive | Where-Object {$_.InterfaceType -ne "USB"}
$isDyingDisk = $false

foreach ($d in $disks) {
    $dIndex = $d.Index
    $dSize = [Math]::Round($d.Size / 1GB)
    $dModel = "$($d.Model)".Trim()
    
    $hours = $null; $wear = $null; $badSectors = 0; $cdiHealth = $null

    try {
        $pDisk = Get-PhysicalDisk | Where-Object {$_.DeviceId -eq "$dIndex" -or $_.FriendlyName -eq $dModel} | Select-Object -First 1
        if ($pDisk) {
            $counter = $pDisk | Get-StorageReliabilityCounter
            if ($counter) {
                if ($counter.PowerOnHours -gt 0) { $hours = $counter.PowerOnHours }
                if ($counter.Wear -ne $null -and $counter.Wear -ge 0) { $wear = $counter.Wear }
            }
        }
    } catch {}

    if ($hasSmartctl) {
        $smartOut = & $smartctlExe -a "/dev/pd$dIndex" 2>$null
        if ($smartOut) {
            if (-not $hours) {
                if ($smartOut -match "Power_On_Hours[^\r\n]*?\s+(\d+)\r?\n" -or $smartOut -match "Power On Hours:\s+([\d,]+)" -or $smartOut -match "\b9\s+Power_On_Hours[^\r\n]*?\s+(\d+)\b") {
                    $hours = [int]($Matches[1] -replace ",", "")
                }
            }
            if ($smartOut -match "Percentage Used:\s+(\d+)%") { 
                $cdiHealth = 100 - [int]$Matches[1] 
            } 
            elseif ($smartOut -match "\b(?:231|169|177|202)\s+[\w_-]+\s+0x[0-9a-fA-F]+\s+(\d+)") {
                $val = [int]$Matches[1]
                if ($val -gt 0 -and $val -le 100) { $cdiHealth = $val }
            }
            
            if ($smartOut -match "Reallocated_Sector_Ct[^\r\n]*?\s+(\d+)\s*\r?\n" -or $smartOut -match "\b5\s+Reallocated_Sector_Ct[^\r\n]*?\s+(\d+)\b") {
                $badSectors = [int]$Matches[1]
            }
        }
    }
    
    Write-Host "  • Накопитель:               $dModel ($dSize ГБ)" -ForegroundColor Gray
    $log += "  • Накопитель:               $dModel ($dSize ГБ)"
    
    if ($hours -ne $null -and $hours -gt 0 -and $hours -lt 200000) {
        $days = [Math]::Round($hours / 24)
        Write-Host "    └─ Наработка:             $hours ч. (~$days дн.)" -ForegroundColor Yellow
        $log += "    └─ Наработка:             $hours ч. (~$days дн.)"
    }
    
    $healthPct = $null
    
    if ($cdiHealth -ne $null -and $cdiHealth -ge 0 -and $cdiHealth -le 100) {
        $healthPct = $cdiHealth; $wear = 100 - $healthPct
    } elseif ($wear -ne $null -and $wear -ge 0) {
        $healthPct = 100 - $wear
    }
    
    if (($healthPct -eq $null -or $healthPct -eq 100) -and $hours -gt 1500) {
        $wear = [Math]::Max(1, [Math]::Floor($hours / 5000))
        $healthPct = 100 - $wear
    }
    
    if ($healthPct -ne $null) {
        if ($healthPct -lt 0) { $healthPct = 0 }
        $healthColor = "Green"
        if ($healthPct -lt 80) { $healthColor = "Yellow" }
        if ($healthPct -lt 50) { $healthColor = "Red" }
        
        Write-Host "    └─ Здоровье SSD:          $healthPct % (Износ: $wear%)" -ForegroundColor $healthColor
        $log += "    └─ Здоровье SSD:          $healthPct % (Износ: $wear%)"
    } else {
        Write-Host "    └─ Здоровье SSD:          Не определено (SMART заблокирован)" -ForegroundColor Gray
        $log += "    └─ Здоровье SSD:          Не определено (SMART заблокирован)"
    }

    if ($badSectors -gt 10 -or $d.Status -ne "OK" -or ($wear -and $wear -gt 70)) {
        $isDyingDisk = $true
        Write-Host "    └─ [!] КРИТИЧЕСКАЯ ДЕГРАДАЦИЯ: Переназначенных секторов: $badSectors шт. [ДИСК ИЗНОШЕН!]" -ForegroundColor Red -BackgroundColor Black
        $log += "    └─ [!] КРИТИЧЕСКАЯ ДЕГРАДАЦИЯ: Переназначенных секторов: $badSectors шт. [ДИСК ИЗНОШЕН!]"
    } elseif ($badSectors -gt 0) {
        Write-Host "    └─ [ВНИМАНИЕ] Обнаружены переназначенные сектора: $badSectors шт." -ForegroundColor Yellow
        $log += "    └─ [ВНИМАНИЕ] Обнаружены переназначенные сектора: $badSectors шт."
        Write-Host "    └─ Статус:                [ОК] Диск рабочий (Требуется наблюдение)." -ForegroundColor Yellow
    } else {
        Write-Host "    └─ Статус:                [УСПЕШНО] Состояние накопителя отличное." -ForegroundColor Green
        $log += "    └─ Статус:                [УСПЕШНО] Состояние накопителя отличное."
    }
}
Write-Host ""
$log += ""

# ==================== БЛОК 6: СОСТОЯНИЕ АККУМУЛЯТОРА ====================
Write-Host "6. СОСТОЯНИЕ АККУМУЛЯТОРА (АКБ)" -ForegroundColor Blue
$log += "6. СОСТОЯНИЕ АККУМУЛЯТОРА (АКБ)"

$battDesign = 0
$battCurrent = 0
$battWear = 0
$battReportPath = Join-Path $env:TEMP "battery_report.html"
$battReportCreated = $false

if ($isNotebook) {
    try {
        if (Test-Path $battReportPath) {
            Remove-Item $battReportPath -Force -ErrorAction SilentlyContinue
        }
        $null = & powercfg /batteryreport /output "$battReportPath" 2>&1
        if (Test-Path $battReportPath) {
            $battReportCreated = $true
        }
    } catch {}

    if ($battReportCreated) {
        try {
            $batteryHtml = Get-Content $battReportPath -Raw -ErrorAction Stop
            $cleanText = $batteryHtml -replace '(?i)<style>.*?</style>', ''
            $cleanText = $cleanText -replace '<[^>]+>', ' '
            $cleanText = $cleanText -replace '&nbsp;|&#160;', ' '
            $cleanText = $cleanText -replace '\s+', ' '

            if ($cleanText -match "(?:Design Capacity|Расчетная емкость|Расчётная ёмкость)\s*([\d\s\s,.]+)\s*(mWh|Wh|mAh)") {
                $battDesign = [double](($Matches[1] -replace '[\s\s,.]', '').Trim())
            }

            if ($cleanText -match "(?:Full Charge Capacity|Емкость при полной зарядке)\s*([\d\s\s,.]+)\s*(mWh|Wh|mAh)") {
                $battCurrent = [double](($Matches[1] -replace '[\s\s,.]', '').Trim())
            }
        } catch {}
    }

    if ($battDesign -le 0 -or $battCurrent -le 0) {
        $wmiBattery = Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity -ErrorAction SilentlyContinue
        $wmiDesign = Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData -ErrorAction SilentlyContinue
        if ($wmiBattery -and $wmiDesign) {
            $battDesign = $wmiDesign.DesignedCapacity
            $battCurrent = $wmiBattery.FullChargedCapacity
        }
    }

    if ($battDesign -gt 0 -and $battCurrent -gt 0) {
        $battWear = [Math]::Round((($battDesign - $battCurrent) / $battDesign) * 100)

        if ($battWear -lt 0) { $battWear = 0 }
        if ($battWear -gt 100) { $battWear = 100 }

        Write-Host "  • Емкость АКБ:              Паспортная: $battDesign mWh | Текущая: $battCurrent mWh" -ForegroundColor Gray
        Write-Host "  • Износ батареи:            $battWear %" -ForegroundColor $(if($battWear -gt 40){"Red"}elseif($battWear -gt 20){"Yellow"}else{"Green"})

        $log += "  • Емкость АКБ:              Паспортная: $battDesign mWh | Текущая: $battCurrent mWh"
        $log += "  • Износ батареи:            $battWear %"

        if ($battWear -gt 40) {
            Write-Host "  • Статус АКБ:               [ВНИМАНИЕ] Высокий износ аккумулятора." -ForegroundColor Red -BackgroundColor Black
            $log += "  • Статус АКБ:               [ВНИМАНИЕ] Высокий износ аккумулятора."
        }
        elseif ($battWear -gt 20) {
            Write-Host "  • Статус АКБ:               [!] Умеренный износ батареи." -ForegroundColor Yellow
            $log += "  • Статус АКБ:               [!] Умеренный износ батареи."
        }
        else {
            Write-Host "  • Статус АКБ:               [УСПЕШНО] Аккумулятор в отличном состоянии." -ForegroundColor Green
            $log += "  • Статус АКБ:               [УСПЕШНО] Аккумулятор в отличном состоянии."
        }
    }
    else {
        Write-Host "  • Статус АКБ:               [?] Параметры батареи не определены." -ForegroundColor Yellow
        $log += "  • Статус АКБ:               [?] Параметры батареи не определены."
    }

    if (Test-Path $battReportPath) {
        Remove-Item $battReportPath -Force -ErrorAction SilentlyContinue
    }
}
else {
    Write-Host "  • Статус:                   Батарея не предусмотрена (Стационарный ПК)." -ForegroundColor Gray
    $log += "  • Статус:                   Батарея не предусмотрена (Стационарный ПК)."
}

Write-Host ""
$log += ""

# ==================== БЛОК 7: ДИСПЛЕЙ И МАТРИЦА ====================
Write-Host "7. ДИСПЛЕЙ И МАТРИЦА" -ForegroundColor Blue
$log += "7. ДИСПЛЕЙ И МАТРИЦА"

# Надежный опрос видеокарты с активным разрешением (защита от гибридных ноутбуков)
$disp = Get-CimInstance Win32_VideoController | Where-Object { $_.CurrentHorizontalResolution -gt 0 } | Select-Object -First 1
if (-not $disp) { $disp = Get-CimInstance Win32_VideoController | Select-Object -First 1 }

$wRes = $disp.CurrentHorizontalResolution
$hRes = $disp.CurrentVerticalResolution
$refresh = $disp.CurrentRefreshRate

$cleanRefresh = $refresh
if ($refresh -in 58..59) { $cleanRefresh = 60 }
elseif ($refresh -in 141..143) { $cleanRefresh = 144 }
elseif ($refresh -in 163..164) { $cleanRefresh = 165 }
elseif ($refresh -in 238..239) { $cleanRefresh = 240 }
elseif ($refresh -in 358..359) { $cleanRefresh = 360 }
elseif ($refresh -in 378..379) { $cleanRefresh = 380 }

$resLabel = "Full HD"
if ($wRes -ge 3840) { $resLabel = "4K Ultra HD" }
elseif ($wRes -ge 2560) { $resLabel = "2K QHD" }
elseif ($wRes -lt 1600) { $resLabel = "HD" }

$diagInches = "24"
try {
    $edid = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams
    if ($edid) {
        $cmW = $edid.MaxHorizontalImageSize
        $cmH = $edid.MaxVerticalImageSize
        if ($cmW -gt 0 -and $cmH -gt 0) {
            $diagInches = [Math]::Round(([Math]::Sqrt($cmW*$cmW + $cmH*$cmH) / 2.54))
        }
    }
} catch {}

Write-Host "  • Экран и разрешение:       $diagInches`" дюймов | $wRes x $hRes ($resLabel)" -ForegroundColor Gray
Write-Host "  • Частота обновления:       $cleanRefresh Гц" -ForegroundColor $(if($cleanRefresh -ge 120){"Green"}else{"Gray"})

$log += "  • Экран и разрешение:       $diagInches`" дюймов | $wRes x $hRes ($resLabel)"
$log += "  • Частота обновления:       $cleanRefresh Гц"

if ($cleanRefresh -ge 120) {
    Write-Host "  • Категория экрана:        [ГЕЙМИНГ] Высокогерцовая матрица ($cleanRefresh Гц)." -ForegroundColor Green
    $log += "  • Категория экрана:        [ГЕЙМИНГ] Высокогерцовая матрица ($cleanRefresh Гц)."
} else {
    Write-Host "  • Категория экрана:        Стандартный дисплей ($cleanRefresh Гц)." -ForegroundColor Gray
    $log += "  • Категория экрана:        Стандартный дисплей ($cleanRefresh Гц)."
}
Write-Host ""
$log += ""

# ==================== БЛОК 8: ВЕРДИКТ И ОЦЕНКА ====================
Write-Host $dash -ForegroundColor Cyan

# --- ОБЩИЙ ВЕРДИКТ ---
if ($isMutnyBios -or $ramFake -or $cpuFake -or $isFakeGpu -or $isDyingDisk) {
    Write-Host " ОБЩИЙ ВЕРДИКТ: [ВНИМАНИЕ] ОБНАРУЖЕНЫ НЕСООТВЕТСТВИЯ ИЛИ ДЕФЕКТЫ ЖЕЛЕЗА!" -ForegroundColor Red -BackgroundColor Black
    $log += " ОБЩИЙ ВЕРДИКТ: [ВНИМАНИЕ] ОБНАРУЖЕНЫ НЕСООТВЕТСТВИЯ ИЛИ ДЕФЕКТЫ ЖЕЛЕЗА!"
}
else {
    Write-Host " ОБЩИЙ ВЕРДИКТ: [УСПЕШНО] Аппаратных подделок и скрытых дефектов не обнаружено." -ForegroundColor Green
    $log += " ОБЩИЙ ВЕРДИКТ: [УСПЕШНО] Аппаратных подделок и скрытых дефектов не обнаружено."
}

Write-Host $dash -ForegroundColor Cyan
Write-Host ""

Write-Host "8. КЛАССИФИКАЦИЯ И ОЦЕНКА" -ForegroundColor Blue
$log += "8. КЛАССИФИКАЦИЯ И ОЦЕНКА"

$deviceType = if ($isNotebook) { "Ноутбук" } else { "Системный блок" }
$verdictClass = "Универсальный рабочий ПК"

$winName = if ($hasDiscrete -and $gpuRes[0]) { $gpuRes[0].WinName } else { "" }

# 1. УСТАРЕВШАЯ ПЛАТФОРМА
if ($winName -match "Radeon\s+R7\s+200|R7\s+200\s+Series|Radeon\s+R5|GeForce\s+710|GeForce\s+730|GeForce\s+610|GeForce\s+620|HD\s+Graphics\s+4000|HD\s+Graphics\s+3000|Radeon\s+HD\s+[0-9]{4}|GeForce\s+[0-9]{4}\s+GT|GeForce\s+[0-9]{3}\s+GT") {
    if ($isNotebook) { $verdictClass = "Ретро-ноутбук (Базовые задачи)" }
    else { $verdictClass = "Устаревшая конфигурация (Ретро)" }
}
# 2. ИГРОВОЙ НОУТБУК ТОП-КЛАССА
elseif ($isNotebook -and $usableMem -ge 12 -and $hasDiscrete -and $cleanGpuName -match "RTX|RX 7|RX 6|RX 5700|RX 5600") {
    $verdictClass = "Мощный игровой ноутбук"
}
# 3. ТОПОВЫЙ ИГРОВОЙ ПК
elseif ($hasDiscrete -and $cleanGpuName -match "4090|4080|4070\s*Ti|4070\s*SUPER|4070S|5090|5080|5070\s*Ti|7900\s*XTX|7900\s*XT|6950\s*XT|6900\s*XT|3090\s*Ti|3090|3080\s*Ti|3080") {
    $verdictClass = "Флагманский игровой ПК"
}
# 4. МОЩНЫЙ ИГРОВОЙ
elseif ($hasDiscrete -and $cleanGpuName -match "5070|4070|7800\s*XT|7700\s*XT|6800\s*XT|6800|6750\s*XT|6700\s*XT|3070\s*Ti|3070|2080\s*Ti|2080\s*SUPER|2080") {
    $verdictClass = "Производительный игровой ПК"
}
# 5. ИГРОВОЙ СРЕДНИЙ КЛАСС
elseif ($hasDiscrete -and ($refresh -ge 120 -or $cleanGpuName -match "5060\s*Ti|5060|4060\s*Ti|4060|3060\s*Ti|3060|3050|2070|2060|1660\s*Ti|1660\s*SUPER|1660|1080\s*Ti|1080|1070\s*Ti|1070|7600\s*XT|7600|6650\s*XT|6600\s*XT|6600|5700\s*XT|5600\s*XT|5500\s*XT")) {
    $verdictClass = "Игровой ПК среднего уровня"
}
# 6. БЮДЖЕТНЫЙ ГЕЙМИНГ
elseif ($hasDiscrete -and $cleanGpuName -match "RX\s*6400|RX\s*6500|RX\s*550|RX\s*560|RX\s*570|RX\s*580|GTX\s*1050|GTX\s*1650|GTX\s*1630|GT\s*1030") {
    $verdictClass = "Бюджетный игровой ПК"
}
# 7. ФЛАГМАНСКИЙ УЛЬТРАБУК
elseif ($isNotebook -and $usableMem -ge 12 -and -not $hasDiscrete -and ($wRes -ge 2560 -or $diagInches -eq "14")) {
    $verdictClass = "Премиальный ультрабук"
}
# 8. ОФИСНЫЙ СЕГМЕНТ
elseif (-not $hasDiscrete -and $usableMem -ge 16) {
    $verdictClass = "Производительный офисный ПК"
}
elseif (-not $hasDiscrete -and $usableMem -ge 12) {
    $verdictClass = "Сбалансированный офисный ПК"
}
elseif (-not $hasDiscrete -and $usableMem -ge 8) {
    $verdictClass = "Стандартный офисный ПК"
}
elseif (-not $hasDiscrete) {
    $verdictClass = "Базовая рабочая станция"
}
elseif ($hasDiscrete) {
    $verdictClass = "Бюджетный ПК с дискретной графикой"
}

# --- СТРОКА ДЛЯ ПОИСКА АНАЛОГОВ ---
$avitoGpuString = if ($hasDiscrete) { "$cleanGpuName $cleanGpuVram" } else { "встройка" }
$avitoSearchHint = "$deviceType $cleanCpu $cpuzRealMem GB $ramTypeString $avitoGpuString".Trim() -replace "\s+", " "

# --- ФЛАГИ ПРЕДУПРЕЖДЕНИЙ ---
$alarmFlags = ""
if ($isMutnyBios) { $alarmFlags += " [ВНИМАНИЕ: OEM/НЕСТАНДАРТНЫЙ BIOS]" }
if ($isDyingDisk) { $alarmFlags += " [ТРЕВОГА: ДИСК ИЗНОШЕН]" }
if ($ramFake)     { $alarmFlags += " [ТРЕВОГА: СКРУЧЕНА ПАМЯТЬ]" }
if ($isFakeGpu)   { $alarmFlags += " [ТРЕВОГА: ПОДДЕЛЬНАЯ ВИДЕОКАРТА]" }
if ($cpuFake)     { $alarmFlags += " [ТРЕВОГА: FAKE CPU]" }

Write-Host "  • Класс устройства:        " -NoNewline -ForegroundColor Gray
Write-Host "$verdictClass" -NoNewline -ForegroundColor Blue

if ($alarmFlags) {
    Write-Host "$alarmFlags" -ForegroundColor Red -BackgroundColor Black
} else {
    Write-Host ""
}

Write-Host "  • Поисковый запрос аналогов: " -NoNewline -ForegroundColor Gray
Write-Host "$avitoSearchHint" -ForegroundColor Green

$log += "  • Класс устройства:        $verdictClass $alarmFlags"
$log += "  • Поисковый запрос аналогов: $avitoSearchHint"

# --- РЕКОМЕНДАЦИИ ПРИ ВЫЯВЛЕНИИ ПРОБЛЕМ ---
if ($isMutnyBios -or $isDyingDisk -or $ramFake -or $isFakeGpu -or $cpuFake) {
    Write-Host ""
    Write-Host $dash -ForegroundColor Cyan
    Write-Host "  [!] РЕКОМЕНДАЦИИ ПО ОЦЕНКЕ И ДОПОЛНИТЕЛЬНОЙ ПРОВЕРКЕ:" -ForegroundColor Red -BackgroundColor Black
    Write-Host "  • Скорректировать оценочную стоимость с учетом выявленных рисков." -ForegroundColor Gray

    if ($isMutnyBios) {
        Write-Host "  • Нестандартный BIOS: проверить ревизию платы и происхождение прошивки." -ForegroundColor Red
    }
    if ($isDyingDisk) {
        Write-Host "  • Накопитель имеет критический износ или сбойные сектора — подлежит замене." -ForegroundColor Red
    }
    if ($ramFake) {
        Write-Host "  • Несовпадение объема ОЗУ — перепроверить планки памяти аппаратно." -ForegroundColor Red
    }
    if ($isFakeGpu) {
        Write-Host "  • Видеокарта: аппаратный HWID не соответствует драйверу — подделка!" -ForegroundColor Red
    }
    if ($cpuFake) {
        Write-Host "  • Процессор: подмена спецификации или числа ядер — требуется детальный тест." -ForegroundColor Red
    }

    Write-Host "  • Рекомендуется запустить стресс-тесты OCCT и FurMark минимум на 5-10 минут." -ForegroundColor Gray
    Write-Host "  • Обязательно проверить работу портов USB, видеовыходов, Wi-Fi и звука." -ForegroundColor Gray

    $log += $dash
    $log += "  [!] РЕКОМЕНДАЦИИ ПО ОЦЕНКЕ И ДОПОЛНИТЕЛЬНОЙ ПРОВЕРКЕ:"
    if ($isMutnyBios) { $log += "  • Нестандартный BIOS: проверить ревизию платы и происхождение прошивки." }
    if ($isDyingDisk) { $log += "  • Накопитель имеет критический износ или сбойные сектора — подлежит замене." }
    if ($ramFake)     { $log += "  • Несовпадение объема ОЗУ — перепроверить планки памяти аппаратно." }
    if ($isFakeGpu)   { $log += "  • Видеокарта: аппаратный HWID не соответствует драйверу — подделка!" }
    if ($cpuFake)     { $log += "  • Процессор: подмена спецификации или числа ядер — требуется детальный тест." }
    $log += "  • Рекомендуется запустить стресс-тесты OCCT и FurMark минимум на 5-10 минут."
    $log += "  • Обязательно проверить работу портов USB, видеовыходов, Wi-Fi и звука."
}

Write-Host $dash -ForegroundColor Cyan
$log += $dash

# ==================== ФИНАЛ И СОХРАНЕНИЕ ====================
[System.IO.File]::WriteAllLines($reportPath, $log, [System.Text.Encoding]::UTF8)

Remove-Item $cpuzDump -ErrorAction SilentlyContinue
Remove-Item (Join-Path $env:TEMP "battery_report.html") -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Полный отчет сохранен на Рабочий стол: Характеристики_и_Вердикт_ПК.txt" -ForegroundColor Green
Write-Host "Нажмите Enter для завершения..." -ForegroundColor Yellow
$null = Read-Host

}
catch {
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Red
    Write-Host "  [!] ПРОИЗОШЛА ОШИБКА: $($_.Exception.Message)" -ForegroundColor Red -BackgroundColor Black
    Write-Host "  [!] Сбой произошел на строке: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
    Write-Host "==================================================================" -ForegroundColor Red
    Write-Host ""

    if ($log) {
        $log += ""
        $log += "[!] ОТЧЕТ ПРЕРВАН ИЗ-ЗА ОШИБКИ НА СТРОКЕ $($_.InvocationInfo.ScriptLineNumber)"
        try { [System.IO.File]::WriteAllLines($reportPath, $log, [System.Text.Encoding]::UTF8) } catch {}
    }

    Write-Host "Сделайте фото экрана с номером строки ошибки." -ForegroundColor Gray
    Write-Host "Нажмите Enter для выхода..." -ForegroundColor Yellow
    $null = Read-Host
    exit
}