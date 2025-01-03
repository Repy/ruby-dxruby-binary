$ErrorActionPreference = "Stop"

Write-Host "Install DirectX 9"
Invoke-WebRequest "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe" -OutFile ".\directx_Jun2010_redist.exe"
Start-Process -Wait -FilePath ".\directx_Jun2010_redist.exe" -ArgumentList "/Q", "/T:C:\directx"
Start-Process -Wait -FilePath "C:\directx\DXSETUP.exe" -ArgumentList "/silent"

Write-Host "Clone DXRuby"
Start-Process -NoNewWindow -Wait -FilePath "git.exe" -ArgumentList "clone", "https://github.com/Repy/dxruby.git"

function Build-DXRuby($url, $installpath, $ver) {
    Write-Host "Install Ruby $ver with Devkit"
    Invoke-WebRequest "$url" -OutFile ".\rubyinstaller.exe"
    Start-Process -Wait -FilePath ".\rubyinstaller.exe" -ArgumentList "/silent", "/currentuser"
    Remove-Item ".\rubyinstaller.exe"
    . "$installpath\bin\ridk.ps1" "enable"
    
    Write-Host "Build DXRuby for Ruby $ver"
    Start-Process -NoNewWindow -Wait -WorkingDirectory ".\dxruby\ext\dxruby" -FilePath "ruby.exe" -ArgumentList "extconf.rb"
    Start-Process -NoNewWindow -Wait -WorkingDirectory ".\dxruby\ext\dxruby" -FilePath "make.exe"
    New-Item -ItemType Directory ".\dxruby\lib\$ver"
    Move-Item ".\dxruby\ext\dxruby\dxruby.so" ".\dxruby\lib\$ver\dxruby.so"
    Start-Process -NoNewWindow -Wait -WorkingDirectory ".\dxruby\ext\dxruby" -FilePath "make.exe" -ArgumentList "clean"
}

Build-DXRuby "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.1.6-1/rubyinstaller-devkit-3.1.6-1-x64.exe" "C:\Ruby31-x64" "3.1_x64" 
Build-DXRuby "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.2.6-1/rubyinstaller-devkit-3.2.6-1-x64.exe" "C:\Ruby32-x64" "3.2_x64" 
Build-DXRuby "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.3.6-2/rubyinstaller-devkit-3.3.6-2-x64.exe" "C:\Ruby33-x64" "3.3_x64" 
Build-DXRuby "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.4.1-1/rubyinstaller-devkit-3.4.1-1-x64.exe" "C:\Ruby34-x64" "3.4_x64"

Build-DXRuby "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.1.6-1/rubyinstaller-devkit-3.1.6-1-x86.exe" "C:\Ruby31" "3.1" 
Build-DXRuby "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.2.6-1/rubyinstaller-devkit-3.2.6-1-x86.exe" "C:\Ruby32" "3.2" 
Build-DXRuby "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.3.6-2/rubyinstaller-devkit-3.3.6-2-x86.exe" "C:\Ruby33" "3.3" 
Build-DXRuby "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.4.1-1/rubyinstaller-devkit-3.4.1-1-x86.exe" "C:\Ruby34" "3.4"

Write-Host "Build DXRuby Gem"
Start-Process -NoNewWindow -Wait -WorkingDirectory ".\dxruby" -FilePath "git.exe" -ArgumentList "config", "--global", "user.email", "you@example.com"
Start-Process -NoNewWindow -Wait -WorkingDirectory ".\dxruby" -FilePath "git.exe" -ArgumentList "config", "--global", "user.name", "Your Name"
Start-Process -NoNewWindow -Wait -WorkingDirectory ".\dxruby" -FilePath "git.exe" -ArgumentList "add", "lib\*\*.so"
Start-Process -NoNewWindow -Wait -WorkingDirectory ".\dxruby" -FilePath "git.exe" -ArgumentList "commit", "-m", "tmp"  
Start-Process -NoNewWindow -Wait -WorkingDirectory ".\dxruby" -FilePath "gem.cmd" -ArgumentList "build", ".\dxruby.gemspec"

Write-Host "Upload GitHub Release"
$TAGNAME = Get-Date -Format "yyyyMMddHHmm"
Start-Process -NoNewWindow -Wait -FilePath "git.exe" -ArgumentList "tag", "-a", "${TAGNAME}", "-m", "${TAGNAME}"
Start-Process -NoNewWindow -Wait -FilePath "git.exe" -ArgumentList "push", "origin", "${TAGNAME}"
Start-Process -NoNewWindow -Wait -FilePath "gh.exe" -ArgumentList "release", "create", "${TAGNAME}", ".\dxruby\dxruby-1.4.7.gem"

Write-Host "Ganarate gem repos"
New-Item -ItemType Directory ".\repos"
New-Item -ItemType Directory ".\repos\gems"
Move-Item ".\dxruby\dxruby-1.4.7.gem" ".\repos\gems\dxruby-1.4.7.gem"
Start-Process -NoNewWindow -Wait -WorkingDirectory ".\repos" -FilePath "gem.cmd" -ArgumentList "generate_index"
