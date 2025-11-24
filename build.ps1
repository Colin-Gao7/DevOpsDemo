# build.ps1 - 在 Jenkins 中执行的 PowerShell 脚本

# --- 1. 定义变量 ---
$SolutionFile = "WpfApp1.sln" # <-- 替换为你的解决方案文件名
$UnitTestProject = "WpfDemo/WpfApp1/wpfapp1.test/wpfapp1.test.csproj" # <-- 替换为你的单元测试项目路径
$TestResultsDir = "$PSScriptRoot\TestResults" # 在工作区创建一个 TestResults 目录
$TestReportFile = "$TestResultsDir\TestReport.xml" # 最终的测试报告文件 (JUnit/xUnit 格式)

# 确保 dotnet CLI 在 PATH 中
Write-Host "--- 1. 恢复 NuGet 包 ---"
dotnet restore $SolutionFile

# --- 2. 构建 WPF 项目 ---
Write-Host "--- 2. 构建 WPF 项目 (Release) ---"
dotnet build $SolutionFile --configuration Release --no-restore 
if ($LASTEXITCODE -ne 0) {
    throw "构建失败。"
}

# --- 3. 执行单元测试并生成 TRX 报告 ---
Write-Host "--- 3. 执行单元测试并生成 TRX 报告 ---"
if (-not (Test-Path $TestResultsDir)) {
    New-Item -Path $TestResultsDir -ItemType Directory | Out-Null
}

# 运行测试，生成 TRX 格式报告
# TRX 是 .NET/Visual Studio 的原生格式，但 Jenkins 更喜欢 JUnit XML。
# 我们先生成 TRX，后面再处理。
dotnet test $UnitTestProject `
    --configuration Release `
    --no-build `
    --logger "trx;LogFileName=testresults.trx" `
    --results-directory $TestResultsDir

# 确保测试结果文件存在，即使测试失败，也会生成报告
if (-not (Test-Path "$TestResultsDir\testresults.trx")) {
    Write-Warning "未找到 testresults.trx 文件。跳过格式转换。"
}
else {
    # --- 4. (可选) 将 TRX 转换为 JUnit XML 格式 ---
    # Jenkins 的 xUnit/JUnit 插件通常需要 JUnit XML 格式。
    # 步骤：
    # a. 需要安装 dotnet tool (例如 trx2junit 或 Microsoft.VisualStudio.QualityTools.UnitTestFramework.Interop)
    # b. 最简单的方法是使用一个名为 trx2junit 的 .NET 全局工具（需要事先在 Agent 上安装）
    # 如果你没有安装工具，可以省略此步骤，但需要配置 JUnit/xUnit 插件来解析 TRX 文件。
    
    # 假设你使用了一个简单的 TRX 到 JUnit 转换工具
    # 示例 (假设你使用了一个名为 'TrxToJunit' 的工具)
    # Write-Host "--- 4. 转换 TRX 到 JUnit XML ---"
    # TrxToJunit "$TestResultsDir\testresults.trx" -o $TestReportFile
    
    # 如果你直接使用 dotnet test 的 trx 文件，则跳过转换。
    # **请注意，许多 Jenkins 插件可以直接解析 TRX 文件。**
    # 为通用性，我们假设我们生成的是 TRX 文件，并告诉 Jenkins 插件如何处理它。
    
    # 实际上，dotnet test 运行后，通常会返回 0（成功）或 1（测试失败）。
    # 如果测试失败，我们让 PowerShell 脚本成功结束（$LASTEXITCODE = 0），
    # 这样 Jenkins 才能执行后续的 Post-Build 步骤来发布测试结果。
}