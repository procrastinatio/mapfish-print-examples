#!/bin/bash


# Generating rounded rectangles
#
# Colors: https://www.imagemagick.org/script/color.php

convert  -size 10x6 xc:skyblue        -scale 100x60    \
      \( +clone  -alpha extract \
     -draw 'fill black polygon 0,0 0,15 15,0 fill white circle 15,15 15,0' \
     \( +clone -flip \) -compose Multiply -composite \
    \( +clone -flop \) -compose Multiply -composite \
    \) -alpha off -compose CopyOpacity -composite  rounded_corners.png


function drawBox() {
    local color=$1
    echo ${color}
    convert  -size 97x27 xc:${color}       \
        \( +clone -alpha extract \
        \( -size 5x5 xc:black -draw 'fill white circle 5,5 5,0' -write mpr:arc +delete \) \
        \( mpr:arc \) -gravity northwest -composite \
        \( mpr:arc -flip \) -gravity southwest -composite \
        \( mpr:arc -flop \) -gravity northeast -composite \
        \( mpr:arc -rotate 180 \) -gravity southeast -composite \) \
        -alpha off -compose CopyOpacity -composite rounded_corners_${color}.png 
}



for c in springgreen yellow3 tomato grey45 turquoise khaki deepskyblue purple; do
    drawBox ${c}
done
