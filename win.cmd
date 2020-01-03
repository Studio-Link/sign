curl -o standalone.exe https://download.studio.link/nightly/v19.xx.x/v19.12.0-alpha-774.25e7c40/windows64/studio-link-standalone-v19.12.0.exe
"%SignTool%" sign /fd SHA256 /a /f certificate.pfx /p %pfx_password% /tr http://time.certum.pl standalone.exe
"%SignTool%" verify /pa standalone.exe
appveyor PushArtifact standalone.exe
