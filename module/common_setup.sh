# Remove any definitely conflicting modules that are installed
if [ -d /data/adb/modules/safetynet-fix ]; then
    touch /data/adb/modules/safetynet-fix/remove
    ui_print "! Universal SafetyNet Fix (USNF) module will be removed on next reboot"
fi

# Replace/hide conflicting custom ROM injection app folders/files to disable them
LIST=$MODPATH/example.app_replace.list
[ -f "$MODPATH/custom.app_replace.list" ] && LIST=$MODPATH/custom.app_replace.list
for APP in $(grep -v '^#' $LIST); do
    if [ -e "$APP" ]; then
        case $APP in
            /system/*) ;;
            *) PREFIX=/system;;
        esac
        HIDEPATH=$MODPATH$PREFIX/$APP
        if [ -d "$APP" ]; then
            mkdir -p $HIDEPATH
            if [ "$KSU" = "true" -o "$APATCH" = "true" ]; then
                setfattr -n trusted.overlay.opaque -v y $HIDEPATH
            else
                touch $HIDEPATH/.replace
            fi
        else
            mkdir -p $(dirname $HIDEPATH)
            if [ "$KSU" = "true" -o "$APATCH" = "true" ]; then
                mknod $HIDEPATH c 0 0
            else
                touch $HIDEPATH
            fi
        fi
        if [[ "$APP" = *"/overlay/"* ]]; then
            CFG=$(echo $APP | grep -oE '.*/overlay')/config/config.xml
            if [ -f "$CFG" ]; then
                if [ -d "$APP" ]; then
                    APK=$(readlink -f $APP/*.apk);
                elif [[ "$APP" = *".apk" ]]; then
                    APK=$(readlink -f $APP);
                fi
                if [ "$APK" ]; then
                    PKGNAME=$(unzip -p $APK AndroidManifest.xml | tr -d '\0' | grep -oE '[[:alnum:].-_]+\*http' | cut -d\* -f1)
                    if [ "$PKGNAME" ] && grep -q "overlay package=\"$PKGNAME" $CFG; then
                        HIDECFG=$MODPATH$PREFIX$CFG
                        if [ ! -f $HIDECFG ]; then
                            mkdir -p $(dirname $HIDECFG)
                            cp -fp $CFG $HIDECFG
                        fi
                        sed -i 's;<overlay \(package="'"$PKGNAME"'".*\) />;<!-- overlay \1 -->;' $HIDECFG
                    fi
                fi
            fi
        fi
        if [[ -d "$APP" -o "$APP" = *".apk" ]]; then
            ui_print "! $(basename $APP .apk) ROM app disabled, please uninstall any user app versions/updates after next reboot"
            [ "$PKGNAME" ] && ui_print "! Corresponding $PKGNAME entry commented to disable in copied overlay config"
        fi
    fi
done