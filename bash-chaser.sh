#!/bin/bash

# bashgame, socat version, developed on ubuntu 8.04
# launch with: xterm -e ./bash-chaser.sh
# 25 sept 2008, orthopteroid@gmail.com

function bail
{
  rm send${PPID}.fifo 2> /dev/null
  rm recv${PPID}.fifo 2> /dev/null
  exit -1;
}

function send_thread
{
  socat -u PIPE:send${PPID}.fifo,ignoreeof UDP4:192.168.0.255:6111,broadcast ; bail
}

function recv_thread
{
  socat -u UDP4-RECV:6111,broadcast PIPE:recv${PPID}.fifo ; bail
}

function display_thread
{
  tic=1
  code=0
  while [ $code -eq 0 ]; do
    read -rs -a DATA < recv${PPID}.fifo > /dev/null 2> /dev/null ; code=${?}
    tput cup ${DATA[1]} ${DATA[2]} ; echo -n ${DATA[0]}
    tput cup 0 15 ; echo -n $code
    tic=$[$tic + 1] ; tput cup 0 $[3 + ($tic % 10)]; echo -n $[$tic % 7]
  done
  bail
}

function control_thread
{
  player="\x$[$RANDOM % 9 + 41]"
  tput cup 0 0 ; echo -ne $player
  row=$[ 1 + $RANDOM % 20 ] ; col=$[ 1 + $RANDOM % 70 ]
  while true; do
    (echo -e "$player $row $col" > send${PPID}.fifo)

    key=' '
    read -rs -t1 -n1 key > /dev/null 2> /dev/null

    rch=0 ; cch=0
    if   [ "$key" = "w" ] ; then rch=-1
    elif [ "$key" = "s" ] ; then rch=+1
    elif [ "$key" = "a" ] ; then cch=-1
    elif [ "$key" = "d" ] ; then cch=+1
    elif [ "$key" = "q" ] ; then return 0;
    fi

    row=$[$row+$rch] ; col=$[$col+$cch]

    if [ $row -eq "24" ]; then row=23; fi
    if [ $col -eq "81" ]; then col=80; fi
    if [ $row -eq "0" ]; then row=1; fi
    if [ $col -eq "0" ]; then col=1; fi
  done
}

clear
mkfifo send${PPID}.fifo # 2> /dev/null
mkfifo recv${PPID}.fifo # 2> /dev/null
(send_thread)&
(recv_thread)&
(display_thread)&
control_thread
bail
