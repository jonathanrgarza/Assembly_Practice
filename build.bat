@echo off
REM Build script for NASM assembly files
REM Usage: build.bat [debug|release|clean] <path_to_asm_file> [exe|dll] <additional_linker_arguments>
REM e.g. build.bat debug HelloWorld\HelloWorld.asm      will build HelloWorld.asm in debug mode

echo Build script started executing at %time% ...

REM Process command line arguments. Default is to build in release configuration.
set BuildType=%1
if "%BuildType%"=="" (set BuildType=release)

set PathToFile=%2
if "%PathToFile%"=="" (
    echo Missing required path to the ASM file
    goto error
)

set BuildExt=%3
if "%BuildExt%"=="" (set BuildExt=exe)

set AdditionalLinkerFlags=%4

REM Get project name (file name) from PathToFile
FOR %%i IN ("%PathToFile%") DO (
    set ProjectName=%%~ni
)

echo Building %ProjectName% in %BuildType% configuration ...

set BuildDir=%~dp0build

if "%BuildType%"=="clean" (
    REM This allows execution of expressions at execution time instead of parse time, for user input
    setlocal EnableDelayedExpansion
    echo Cleaning build from directory: %BuildDir%. Files will be deleted^^!
    echo Continue ^(Y/N^)^?
    set /p ConfirmCleanBuild=
    if /I "!ConfirmCleanBuild!" EQU "Y" (
        echo Removing files in %BuildDir%...
        del /s /q %BuildDir%\*.*
    )
    goto end
)

REM Start with VS 2019 Native Tools Command Prompt
set VSTOOLS="%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat"

REM    Set up the Visual Studio environment variables for calling the MSVC compiler;
REM    the check for DevEnvDir is to make sure the vcvarsall.bat
REM    is only called once per-session (since repeated invocations will screw up
REM    the environment)
if not defined DevEnvDir (
    REM check if path exists
    if not exist %VSTOOLS% (
        echo Could not locate %VSTOOLS%
        echo Will try VS 2017 version...

        REM Try VS 2017
        set VSTOOLS="%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvarsall.bat"

        if not exist %VSTOOLS% (
            echo Could not find a supported version of Visual Studio installed
            goto error
        )
    )

    call %VSTOOLS% x64
)

echo Building in directory: %BuildDir% ...

if not exist %BuildDir% mkdir %BuildDir%
pushd %BuildDir%

set NasmExe="%ProgramFiles%\NASM\nasm.exe"

set EntryPoint=%PathToFile%

set IntermediateObj=%BuildDir%\%ProjectName%.obj
set OutBin=%BuildDir%\%ProjectName%.%BuildExt%

set CommonCompilerFlags=-f win64 -I%~dp0 -l "%BuildDir%\%ProjectName%.lst"

set DebugCompilerFlags=-gcv8

if "%BuildExt%"=="exe" (
    set BinLinkerFlagsMSVC=/subsystem:console /entry:main
) else (
    set BinLinkerFlagsMSVC=/dll
)

set CommonLinkerFlagsMSVC=%BinLinkerFlagsMSVC% /defaultlib:ucrt.lib /defaultlib:msvcrt.lib /defaultlib:legacy_stdio_definitions.lib /defaultlib:Kernel32.lib /defaultlib:Shell32.lib /nologo /incremental:no
set DebugLinkerFlagsMSVC=/opt:noref /debug /pdb:"%BuildDir%\%ProjectName%.pdb"
set ReleaseLinkerFlagsMSVC=/opt:ref

if "%BuildType%"=="debug" (
    set CompileCommand=%NasmExe% %CommonCompilerFlags% %DebugCompilerFlags% -o "%IntermediateObj%" %EntryPoint%
    set LinkCommand=link "%IntermediateObj%" %CommonLinkerFlagsMSVC% %DebugLinkerFlagsMSVC% %AdditionalLinkerFlags% /out:"%OutBin%"
) else (
    set CompileCommand=%NasmExe% %CommonCompilerFlags% -o "%IntermediateObj%" %EntryPoint%
    set LinkCommand=link "%IntermediateObj%" %CommonLinkerFlagsMSVC%  %ReleaseLinkerFlagsMSVC% %AdditionalLinkerFlags% /out:"%OutBin%"
)

echo.
echo Compiling (command follows below)...
echo %CompileCommand%

%CompileCommand%

if %errorlevel% neq 0 goto error

echo.
echo Linking (command follows below)...
echo %LinkCommand%

%LinkCommand%

if %errorlevel% neq 0 goto error
if %errorlevel% == 0 goto success

:error
echo.
echo ***************************************
echo *      !!! An error occurred!!!       *
echo ***************************************
goto end

:success
echo.
echo ***************************************
echo *    Build completed successfully!    *
echo ***************************************
goto end

:end
echo.
echo Build script finished execution at %time%.
popd
exit /b %errorlevel%