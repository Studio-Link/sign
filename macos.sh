#!/bin/zsh

lipo_glue() {
	content_path="${1}.${2}/Contents/MacOS/${1}"
	lipo $content_path \
		../macos_arm64/$content_path -create -output ${1}
	cp -a ${1} $content_path
	lipo -info $content_path
	if [[ "${2}" == "app" ]]; then
		codesign --options runtime --entitlements ../entitlements.plist -f --verbose \
			-s "Developer ID Application: Sebastian Reimers (CX34XZ2JTT)" ${1}.${2}
	else
		codesign -f --verbose -s "Developer ID Application: Sebastian Reimers (CX34XZ2JTT)" ${1}.${2}
	fi
	zip -r ${3}.zip ${1}.${2}
	rm -Rf ${1}.${2}
} 

requeststatus() { # $1: requestUUID
    requestUUID=${1?:"need a request UUID"}
    req_status=$(xcrun altool --notarization-info "$requestUUID" \
                              --username "$APPLE_ID" \
                              --password "$APPLE_APP_PASSWORD" 2>&1 \
                 | awk -F ': ' '/Status:/ { print $2; }' )
    echo "$req_status"
}

notarizefile() { # $1: path to file to notarize, $2: identifier
    filepath=${1:?"need a filepath"}
    
    # upload file
    echo "## uploading $filepath for notarization"
    requestUUID=$(xcrun altool --notarize-app \
                               --primary-bundle-id "link.studio.standalone.zip" \
                               --username "$APPLE_ID" \
                               --password "$APPLE_APP_PASSWORD" \
			       --asc-provider "CX34XZ2JTT" \
                               --file "$filepath" 2>&1 \
                  | awk '/RequestUUID/ { print $NF; }')
                               
    echo "Notarization RequestUUID: $requestUUID"
    
    if [[ $requestUUID == "" ]]; then 
        echo "could not upload for notarization"
        exit 1
    fi
        
    # wait for status to be not "in progress" any more
    request_status="in progress"
    while [[ "$request_status" == "in progress" ]]; do
        echo -n "waiting... "
        sleep 10
        request_status=$(requeststatus "$requestUUID")
        echo "$request_status"
    done
    
    # print status information
    xcrun altool --notarization-info "$requestUUID" \
                 --username "$APPLE_ID" \
                 --password "$APPLE_APP_PASSWORD"
    echo 
    
    if [[ $request_status != "success" ]]; then
        echo "## could not notarize $filepath"
        exit 1
    fi
    
}

security create-keychain -p travis sl-build.keychain
security list-keychains -s ~/Library/Keychains/sl-build.keychain
security unlock-keychain -p travis ~/Library/Keychains/sl-build.keychain
security set-keychain-settings ~/Library/Keychains/sl-build.keychain
security import cert_2020.p12 -k ~/Library/Keychains/sl-build.keychain -P $KEY_PASSWORD_2020 -A
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k travis sl-build.keychain

for p in macos_arm64 macos_x86_64; do
	mkdir -p $p
	cd $p
	curl -o studio-link-standalone.zip https://download.studio.link/releases/$APPVEYOR_REPO_TAG_NAME/$p/hardened/studio-link-standalone-$APPVEYOR_REPO_TAG_NAME.zip
	unzip studio-link-standalone.zip
	rm studio-link-standalone.zip

	curl -o studio-link-plugin.zip https://download.studio.link/releases/$APPVEYOR_REPO_TAG_NAME/$p/hardened/studio-link-plugin.zip
	unzip studio-link-plugin.zip
	rm studio-link-plugin.zip

	curl -o studio-link-plugin-onair.zip https://download.studio.link/releases/$APPVEYOR_REPO_TAG_NAME/$p/hardened/studio-link-plugin-onair.zip
	unzip studio-link-plugin-onair.zip
	rm studio-link-plugin-onair.zip
	cd ..
done

cd macos_x86_64

lipo_glue StudioLinkStandalone app studio-link-standalone
notarizefile "studio-link-standalone.zip"
unzip studio-link-standalone.zip
rm studio-link-standalone.zip
codesign -dvv StudioLinkStandalone.app
xcrun stapler staple "StudioLinkStandalone.app"
zip -r studio-link-standalone-$APPVEYOR_REPO_TAG_NAME.zip StudioLinkStandalone.app
appveyor PushArtifact studio-link-standalone-$APPVEYOR_REPO_TAG_NAME.zip

lipo_glue StudioLink component studio-link-plugin
notarizefile "studio-link-plugin.zip"
unzip studio-link-plugin.zip
rm studio-link-plugin.zip
xcrun stapler staple "StudioLink.component"
zip -r studio-link-plugin StudioLink.component
appveyor PushArtifact studio-link-plugin.zip

lipo_glue StudioLinkOnAir component studio-link-plugin-onair
notarizefile "studio-link-plugin-onair.zip"
unzip studio-link-plugin-onair.zip
rm studio-link-plugin-onair.zip
xcrun stapler staple "StudioLinkOnAir.component"
zip -r studio-link-plugin-onair StudioLinkOnAir.component
appveyor PushArtifact studio-link-plugin-onair.zip
