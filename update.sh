#!/bin/bash
hexo clean && hexo g && hexo d -g
git add .
git commit -m "by icean"
git push -u origin master
