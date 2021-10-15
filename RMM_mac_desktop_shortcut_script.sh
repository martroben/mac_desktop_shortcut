#!/usr/bin/osascript


#######################################################################################################
##                                                                                                   ##
##  Script name: RMM_mac_desktop_shortcut_script.sh                                                  ##
##  Purpose of script: create support portal shortcuts to mac user desktops, using N-able RMM        ##
##  Author: Mart Roben                                                                               ##
##  Date Created: 15. Oct 2021                                                                       ##
##                                                                                                   ##
##  Copyright: BSD-3-Clause                                                                          ##
##  https://github.com/martroben/parallel_primes                                                     ##
##                                                                                                   ##
##  Contact: mart@altacom.eu                                                                         ##
##                                                                                                   ##
#######################################################################################################


use framework "AppKit"
use scripting additions


# --------------------------------------------------------------------------------
# SETTING PROPERTIES:

property this : a reference to current application
property NSWorkspace : a reference to NSWorkspace of this
property NSImage : a reference to NSImage of this

# --------------------------------------------------------------------------------




# --------------------------------------------------------------------------------
# RUN

on run
	
	# INPUTS
	
	# Name of support shortcut that will be placed to user devices
	set supportShortcutName to "MyCompany support"
	
	# Support shortcut target URL (self-service portal)
	set supportURL to "http://mycompany.portal.mspmanager.com/"
	
	# URL of support shortcut icon .png
	set iconURL to "http://mycompanyurl.com/myCompanyLogo.png"
	
	# Folder on local device to save the support shortcut icon .png to
	set iconDownloadPath to "/usr/local/rmmagent/MSP_icon.png"
	
	
	
	# ACTION:
	
	# Get list of local users
	set userList to getUserList()
	
	# Get users without support shortcut
	set usersWithoutShortcut to getUsersWithoutDesktopFile(userList, supportShortcutName & ".webloc")
	
	# If there are no users that are missing the shortcut, exit script
	if length of usersWithoutShortcut is equal to 0 then
		return "All users already have shortcuts. No changes made."
	end if
	
	# Download support shortcut icon .png file
  # true/false input determines whether already existing icon file should be replaced
	downloadFile(iconURL, iconDownloadPath, true)
	
	# Uncomment for testing - to place shortcut on single user desktop only
	# set usersWithoutShortcut to {"myMacUser"}
	
	# Cycle through users, add shortcuts and set icons for each
	repeat with i from 1 to count usersWithoutShortcut
		set supportShortcutLocation to "/Users/" & item i of usersWithoutShortcut & "/Desktop/"
		set supportShortcutPath to supportShortcutLocation & supportShortcutName & ".webloc"
		
		createWebShortcut_Medieval(supportShortcutLocation, supportShortcutName, supportURL)
		setShortcutIcon(iconDownloadPath, supportShortcutPath)
	end repeat
	
	return "Added '" & supportShortcutName & "' shortcut for the following users: " & listToString(usersWithoutShortcut)
	
end run

# --------------------------------------------------------------------------------




# --------------------------------------------------------------------------------
# HANDLERS (FUNCTIONS):

# Handler (function) to get list of users on local device,
# remove usernames starting with "_"
# add "Guest" as user to the list
to getUserList()
	
	set users to do shell script "dscl . list /Users | grep -v '^_'"
	set users to words of users & "Guest"
	return users
end getUserList



# Handler to cycle through users and return the ones that do have Desktop folder,
# but don't have a specified file on Desktop
to getUsersWithoutDesktopFile(listOfUsers, fileName)
	
	set usersWithoutFile to {}
	repeat with i from 1 to count listOfUsers
		
		set user to item i of listOfUsers
		set desktopPath to "/Users/" & user & "/Desktop/"
		set pathToFile to "/Users/" & user & "/Desktop/" & fileName
		
		# A string to pass as shell script command
		set shScriptString to "if [ -d " & desktopPath & " ] && [ ! -f \"" & pathToFile & "\" ]; then echo 1; else echo 0; fi"
		
		if (do shell script shScriptString) as number as boolean then
			set end of usersWithoutFile to user
		end if
	end repeat
	
	return usersWithoutFile
	
end getUsersWithoutDesktopFile



# Handler to download file (if it doesn't already exist)
to downloadFile(sourceURL, destinationPath, overwrite)
	
	if overwrite then
		set shScriptString to "set +o noclobber; curl \"" & sourceURL & "\" > \"" & destinationPath & "\""
	else
		set shScriptString to "if [ ! -s \"" & destinationPath & "\" ]; then curl \"" & sourceURL & "\" -o \"" & destinationPath & "\"; fi"
	end if
	
	do shell script shScriptString
end downloadFile



# Create a shortcut to a URL with specified name and location on local device
to createWebShortcut(shortcutLocationPath, shortcutName, targetURL)
	
	set localLocationAlias to POSIX file shortcutLocationPath as alias
	tell application "Finder" to make new internet location file to targetURL at localLocationAlias with properties {name:shortcutName}
end createWebShortcut



# Create a shortcut to a URL with specified name and location on local device
# Medieval version: writes a shortcut file manually from zero
# Doesn't use "tell Finder" and (hopefully) doesn't need user approvals
to createWebShortcut_Medieval(shortcutLocationPath, shortcutName, targetURL)
	
	set shortcutPath to shortcutLocationPath & shortcutName & ".webloc"
	
	# Manually create the xml content of the .webloc file
	set xmlContent to "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
	<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDsPropertyList-1.0.dtd\">
	<plist version=\"1.0\">
	<dict>
	<key>URL</key>
	<string>" & targetURL & "</string>
	</dict>
	</plist>"
	
	set shScriptString to "echo " & "\"" & xmlContent & "\" > \"" & shortcutPath & "\""
	do shell script shScriptString
	
	# Manually edit the com.apple.FinderInfo of created file to set the "Hide extension" attribute
	# (to hide ".webloc" in file name)
	# h/t https://eclecticlight.co/2017/12/19/xattr-com-apple-finderinfo-information-for-the-finder/
	set shScriptString2 to "xattr -wx com.apple.FinderInfo '0000000000000000001000000000000000000000000000000000000000000000' \"" & shortcutPath & "\""
	
	do shell script shScriptString2
	
end createWebShortcut_Medieval



# Set icon of the shortcut file to specified .png
# h/t https://apple.stackexchange.com/questions/6901/how-can-i-change-a-file-or-folder-icon-using-the-terminal
to setShortcutIcon(iconPath, shortcutPath)
	set sharedWorkspace to NSWorkspace's sharedWorkspace()
	set newImage to NSImage's alloc()
	set icon to newImage's initWithContentsOfFile:iconPath
	
	set success to sharedWorkspace's setIcon:icon forFile:shortcutPath options:0
end setShortcutIcon



# Handler to turn a list of names into comma separated string
to listToString(theList)
	set {TID, text item delimiters} to {text item delimiters, ", "}
	set {theString, text item delimiters} to {theList as text, TID}
	
	return theString
end listToString

# --------------------------------------------------------------------------------
