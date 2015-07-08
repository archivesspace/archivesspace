---
title: Resetting passwords 
layout: en
permalink: /user/resetting-passwords/ 
---

Under the `scripts` directory you will find a script that lets you
reset a user's password.  You can invoke it as:

    scripts/password-reset.sh theusername newpassword  # or password-reset.bat under Windows

If you are running against MySQL, you can use this command to set a
password while the system is running.  If you are running against the
demo database, you will need to shutdown ArchivesSpace before running
this script.


