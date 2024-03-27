#!/bin/bash

mv .git/config config

rm -rf .git

git init -b main

mv config .git/config

git add --all .

git commit -m "monthly cleanup"

git push origin main --force

echo "################################################################"
echo "###################    cleanup  Done      ######################"
echo "################################################################"
