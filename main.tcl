package require Tk
variable mplayer total_time video_file

proc Read {chan} {
  global total_time

  foreach line [split [read $chan] \n] {
    set line [string trim $line]

    if {[regexp "ANS_LENGTH=(\[0-9\]*)\..*" $line match value]} {
      set total_time $value
      ::.st_scl configure -values [range 0 $value]
      ::.en_scl configure -values [range 0 $value]
    }

    puts $line
  }

  if {[eof $chan]} {
    exit
  }
}

proc PlaySegment {} {
  global mplayer st_second en_second

  puts $mplayer "set_stream_start $st_second"
  puts $mplayer "set_stream_end $en_second"
  puts $mplayer "seek $st_second.0 2"

  after [expr [expr $en_second - $st_second] * 1000] [list puts $mplayer "pause"]
}

proc LoadVideo {id} {
  global mplayer video_file

  set video_file [::tk::dialog::file:: open]
  # set video_file [tk_getOpenFile -title "Choose Video"]

  set cmd { mplayer }
  lappend cmd -quiet -slave -wid $id $video_file
  set pipe [open |$cmd r+]
  fconfigure $pipe -blocking 0 -buffering line
  fileevent $pipe readable [list Read $pipe]
  variable mplayer $pipe
  puts $mplayer "mute 1"
  puts $mplayer "get_time_length"
  puts $mplayer "seek 0.0 2"
  puts $mplayer "pause"
}

proc SetVideo {mode} {
  global mplayer
  global st_second
  global en_second

  if {$mode == "st"} {
    puts $mplayer "seek $st_second.0 2"
    puts $mplayer "pause"
  } else {
    puts $mplayer "seek $en_second.0 2"
    puts $mplayer "pause"
  }
}

proc CutVideo {} {
  global video_file en_second st_second
  puts "ffmpeg -i $video_file -ss $st_second -t [expr $en_second - $st_second] $video_file.cut.mp4"
  exec ffmpeg -i $video_file -ss $st_second -t [expr $en_second - $st_second] $video_file.cut.mp4
  tk_messageBox -message "The video cut was successful." -type ok
}

proc Exit {} {
  global mplayer
  puts $mplayer quit
}

proc Main {} {
  global env

  wm title . "TKVideoCut"
  wm protocol . WM_DELETE_WINDOW [list Exit]
  wm resizable . 0 0
  wm geometry . +800+500
  . configure -padx 4 -pady 4
  wm attributes . -topmost 0

  frame .video -relief groove -borderwidth 2
  grid config .video -column 0 -row 0 -columnspan 3 -sticky "news"
  set id [winfo id .video]

  label .st_label -text "Start Time:"
  grid config .st_label -column 0 -row 1 -sticky "e"

  # scale .st_scl -tickinterval 5 -orient horizontal -from 0 -to 29 -length 150  -variable st_second -showvalue yes
  ttk::combobox .st_scl -textvariable st_second
  .st_scl configure -values [range 0 30]
  bind .st_scl <<ComboboxSelected>> [list SetVideo st]
  grid config .st_scl -column 1 -row 1 -sticky "e"
  set ::st_second 0

  button .st_b -text "Preview" -command [list SetVideo st]
  grid config .st_b -column 2 -row 1 -sticky "e"

  label .en_label -text "End Time:"
  grid config .en_label -column 0 -row 2 -sticky "e"

  # scale .en_scl -tickinterval 5 -orient horizontal -from 0 -to 29 -length 150  -variable en_second -showvalue yes
  ttk::combobox .en_scl -textvariable en_second
  .en_scl configure -values [range 0 30]
  bind .en_scl <<ComboboxSelected>> [list SetVideo en]
  grid config .en_scl -column 1 -row 2 -sticky "e"
  set ::en_second 0

  button .en_b -text "Preview" -command [list SetVideo en]
  grid config .en_b -column 2 -row 2 -sticky "e"

  button .play_b -text "Play" -command [list PlaySegment]
  grid config .play_b -column 0 -row 3 -sticky "news"

  button .cut_b -text "Cut" -command [list CutVideo]
  grid config .cut_b -column 1 -row 3 -columnspan 2 -sticky "news"

  LoadVideo $id
}

proc range {from to} {
  set range {}
  for {set n $from} {$n <= $to} {incr n} {
    lappend range $n
  }
  return $range
}

Main
