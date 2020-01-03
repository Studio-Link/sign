curl -o standalone.exe https://download.studio.link/releases/%APPVEYOR_REPO_TAG_NAME%/windows64/studio-link-standalone-%APPVEYOR_REPO_TAG_NAME%.exe
"%SignTool%" sign /fd SHA256 /a /f certificate.pfx /p %pfx_password% /tr http://time.certum.pl standalone.exe
copy standalone.exe studio-link-standalone-signed-%APPVEYOR_REPO_TAG_NAME%.exe
"%SignTool%" verify /pa studio-link-standalone-signed-%APPVEYOR_REPO_TAG_NAME%.exe
appveyor PushArtifact studio-link-standalone-signed-%APPVEYOR_REPO_TAG_NAME%.exe
