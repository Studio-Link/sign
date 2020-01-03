curl -o standalone.exe https://download.studio.link/nightly/v19.xx.x/v19.12.0-alpha-774.25e7c40/windows64/studio-link-standalone-v19.12.0.exe
appveyor-tools\secure-file -decrypt certificate.p12.enc -secret %p12_enc_secret% -salt %p12_enc_salt%
"%SignTool%" \h
