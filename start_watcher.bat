off
echo
Starting
Git
Watcher...
powershell
-NoProfile
-ExecutionPolicy
Bypass
-Command
& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \
%~dp0watch_and_push.ps1\' -Verb RunAs -WindowStyle Hidden}
echo
Watcher
started
successfully!
This
window
will
close
in
3
seconds.
timeout
/t
3
^>nul
