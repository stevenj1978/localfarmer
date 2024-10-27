@echo off
cd C:\localfarmerz
git add .
git commit -m "Automatic commit on %date% at %time%"
git push origin main  # Change 'main' if your branch name is different
