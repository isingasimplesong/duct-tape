#!/usr/bin/env bash

vancouver=$(TZ='America/Vancouver' date '+%H:%M')
montreal=$(TZ='America/Toronto' date '+%H:%M')
halifax=$(TZ='America/Halifax' date '+%H:%M')
utc=$(TZ='Etc/UTC' date '+%H:%M')
paris=$(TZ='Europe/Paris' date '+%H:%M')
gaza=$(TZ='Asia/Gaza' date '+%H:%M')
moscou=$(TZ='Europe/Moscow' date '+%H:%M')
beijing=$(TZ='Asia/Shanghai' date '+%H:%M')

message="\nVancouver       $vancouver\nMontréal        $montreal\nHalifax         $halifax\nUTC             $utc\nParis           $paris\nGaza            $gaza\nMoscou          $moscou\nPékin           $beijing"

notify-send "Décalage horaire" "$message"
