MODID=LocationManagerServiceExWakelockFixer

AUTOMOUNT=true

PROPFILE=false

POSTFSDATA=false

LATESTARTSERVICE=false

print_modname() {
  ui_print "*****************************************"
  ui_print " LocationManagerServiceEx Wakelock Fixer "
  ui_print "               drizzt @ XDA              "
}

REPLACE="
/system/framework/services.jar
/system/framework/oat/arm64/services.odex
"

set_permissions() {
  set_perm_recursive  $MODPATH  0  0  0755  0644
}
