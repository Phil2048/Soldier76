-- User configuration
UserConfig = {
    -- 基础力度
    power = 5,
    -- 启动控制 (scrolllock, capslock, numlock)
    startControl = "capslock"
}

-- 全局状态
State = {
    -- 左键状态
    G1 = false,
    -- 右键状态
    G3 = false
}

-- 是否启动
function IsStart ()
    return IsKeyLockOn(UserConfig.startControl)
end

-- 压枪主循环 - 持续压枪（需要按住按键）
function RecoilLoop ()
    OutputLogMessage("压枪循环启动\n")

    -- 等待按键状态同步（最多等待50ms）
    local waitCount = 0
    while not IsMouseButtonPressed(1) and waitCount < 5 do
        Sleep(10)
        waitCount = waitCount + 1
    end

    if not IsMouseButtonPressed(1) then
        OutputLogMessage("警告：左键状态同步超时，取消压枪\n")
        return
    end

    local count = 0
    -- 使用 IsMouseButtonPressed 实时检测物理按键状态
    -- 注意：由于 arg 参数被转换了，这里要用原始物理按键编号
    -- 重要：必须同时按住左键和右键才能持续触发，点击无效
    while IsStart() and IsMouseButtonPressed(1) and IsMouseButtonPressed(3) do
        -- 检测 Shift 键状态，如果按下则暂停压枪，Shift 未按下，执行正常压枪
        if not IsModifierPressed("shift") then
            MoveMouseRelative(0, UserConfig.power + math.random(-1, 1))
            Sleep(math.random(7, 9))
            count = count + 1
            -- 每50次输出一次状态，方便调试
            if count % 50 == 0 then
                OutputLogMessage("  [循环中] 第%d次 | 左键:%s 右键:%s CapsLock:%s\n", count, IsMouseButtonPressed(1), IsMouseButtonPressed(3), IsStart())
            end
        end
    end
    OutputLogMessage("压枪循环结束 | 共执行%d次 | 退出原因: 左键=%s, 右键=%s, CapsLock=%s\n", count, IsMouseButtonPressed(1), IsMouseButtonPressed(3), IsStart())
end

-- 入口函数
function OnEvent (event, arg, family)
    -- 与 IsMouseButtonPressed 方法统一
    if arg == 2 then arg = 3 elseif arg == 3 then arg = 2 end

    -- 详细日志，方便调试
    if family == "mouse" and (event == "MOUSE_BUTTON_PRESSED" or event == "MOUSE_BUTTON_RELEASED") then
        OutputLogMessage("=== 事件: %s | 按键: %d | CapsLock: %s | 实时状态: 左键=%s, 右键=%s ===\n", 
            event, arg, IsKeyLockOn("capslock"), IsMouseButtonPressed(1), IsMouseButtonPressed(3))
    end

    -- 记录按键状态并触发压枪
    if family == "mouse" then
        if event == "MOUSE_BUTTON_PRESSED" then
            if arg == 1 then
                State.G1 = true
            elseif arg == 3 then
                State.G3 = true
            end

            -- 每次按键都检查是否满足启动条件
            if State.G1 and State.G3 and IsStart() then
                OutputLogMessage(">>> 启动压枪循环 <<<\n")
                RecoilLoop()
            end

        elseif event == "MOUSE_BUTTON_RELEASED" then
            if arg == 1 then
                State.G1 = false
            elseif arg == 3 then
                State.G3 = false
            end
        end
    end

    -- 一键滑步
    if family == "mouse" and event == "MOUSE_BUTTON_PRESSED" and arg == 6 then
        OutputLogMessage("滑步\n")
        ReleaseKey("w")
        Sleep(10 + math.random(10, 15))
        PressAndReleaseKey("c")
        Sleep(10 + math.random(10, 15))
        PressAndReleaseKey("w")
        Sleep(10 + math.random(10, 15))
        PressAndReleaseKey("c")
    end

    -- 配置文件切换时清理状态
    if event == "PROFILE_DEACTIVATED" then
        State.G1 = false
        State.G3 = false
        EnablePrimaryMouseButtonEvents(false)
        ReleaseKey("lshift")
        ReleaseKey("lctrl")
        ReleaseKey("lalt")
        ReleaseKey("rshift")
        ReleaseKey("rctrl")
        ReleaseKey("ralt")
    end
end

-- 启用鼠标按键 1 事件报告
EnablePrimaryMouseButtonEvents(true)
-- 设置随机数种子
math.randomseed(GetRunningTime())