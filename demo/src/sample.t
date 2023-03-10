#charset "us-ascii"
//
// sample.t
// Version 1.0
// Copyright 2022 Diegesis & Mimesis
//
// This is a very simple demonstration "game" for the remoteView library.
//
// It can be compiled via the included makefile with
//
//	# t3make -f makefile.t3m
//
// ...or the equivalent, depending on what TADS development environment
// you're using.
//
// This "game" is distributed under the MIT License, see LICENSE.txt
// for details.
//
#include <adv3.h>
#include <en_us.h>

#include "remoteView.h"

versionInfo:    GameID
        name = 'remoteView Library Demo Game'
        byline = 'Diegesis & Mimesis'
        desc = 'Demo game for the remoteView library. '
        version = '1.0'
        IFID = '12345'
	showAbout() {
		"This is a simple test game that demonstrates the features
		of the remoteView library.
		<.p>
		Test case:
		<.p>
		\t&gt;X PEBBLE
		\n\tYou see no pebble here.
		<.p>
		\n\t&gt;L THROUGH WINDOW
		\n\tIn the other room, you see a pebble.
		<.p>
		\n\t&gt;X PEBBLE
		\n\tIt looks like a pebble seen through a window.
		<.p>
		Consult the README.txt document distributed with the library
		source for a quick summary of how to use the library in your
		own games.
		<.p>
		The library source is also extensively commented in a way
		intended to make it as readable as possible. ";
	}
;

startRoom: Room 'Void'
        "This is a featureless void with a window.  The other room is
		to the north. "
	north = otherRoom
;
+me: Person;
+rock: Thing 'ordinary rock' 'rock' "An ordinary rock. ";

window: RemoteViewConnector 'window' 'window'
	locationList = static [ startRoom, otherRoom ]
	oneWay = true
	oneWayFailure = 'This side of the window is tinted, so you
		can\'t see through it from here. '
;

otherRoom: Room 'Other Room'
	"This is the other room.  The void lies to the south. "
	south = startRoom
;
+pebble: Thing 'small round pebble' 'pebble' "A small, round pebble. ";
++RemoteView ->window 'It looks like a pebble seen through a window. ';

gameMain:       GameMainDef initialPlayerChar = me;
